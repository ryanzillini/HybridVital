import CoreLocation
import Foundation
import HealthKit

enum WorkoutPhase: Equatable {
    case idle
    case preparing
    case countdown(Int)
    case active
    case paused
    case ending
}

nonisolated struct WorkoutMetricsSnapshot: Sendable {
    var heartRate: Double?
    var activeCalories: Double?
    var distanceMeters: Double?
    var elapsed: TimeInterval?
}

@Observable
@MainActor
final class WorkoutSessionManager: NSObject {
    var phase: WorkoutPhase = .idle
    var currentHeartRate: Double?
    var activeCalories: Double = 0
    var distanceMeters: Double = 0
    var startedAt: Date?
    var elapsed: TimeInterval = 0
    var errorMessage: String?
    var hasReceivedHeartRate = false

    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private let healthStore = HKHealthStore()
    private let locationAuthorizer = LocationAuthorizer()
    private var pauseStartedAt: Date?
    private var pausedAccumulated: TimeInterval = 0

    var isRunning: Bool {
        phase == .active || phase == .paused || isPreparing
    }

    var isPreparing: Bool {
        if case .countdown = phase { return true }
        return phase == .preparing
    }

    func requestLocation() {
        locationAuthorizer.request()
    }

    func recordHeartRate(_ bpm: Double) {
        currentHeartRate = bpm
        hasReceivedHeartRate = true
        guard let builder, phase == .active || phase == .paused else { return }

        let quantity = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: bpm)
        let sample = HKQuantitySample(
            type: HKQuantityType(.heartRate),
            quantity: quantity,
            start: .now,
            end: .now
        )
        builder.add([sample]) { _, error in
            if let error {
                print("[Zone2] Failed to save HR sample: \(error.localizedDescription)")
            }
        }
    }

    func start() async {
        errorMessage = nil
        elapsed = 0
        pausedAccumulated = 0
        pauseStartedAt = nil
        activeCalories = 0
        distanceMeters = 0
        phase = .preparing

        do {
            try await HealthKitService.shared.requestAuthorization()
            locationAuthorizer.request()

            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .running
            configuration.locationType = .outdoor

            let workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let dataBuilder = workoutSession.associatedWorkoutBuilder()
            dataBuilder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            workoutSession.delegate = self
            dataBuilder.delegate = self

            session = workoutSession
            builder = dataBuilder

            workoutSession.prepare()

            for remaining in stride(from: 3, through: 1, by: -1) {
                phase = .countdown(remaining)
                try await Task.sleep(for: .seconds(1))
                if session == nil { return }
            }

            let startDate = Date()
            startedAt = startDate
            workoutSession.startActivity(with: startDate)
            try await dataBuilder.beginCollection(at: startDate)
            phase = .active
        } catch {
            errorMessage = error.localizedDescription
            phase = .idle
            session = nil
            builder = nil
        }
    }

    func pause() {
        session?.pause()
        pauseStartedAt = .now
        phase = .paused
    }

    func resume() {
        session?.resume()
        if let pauseStartedAt {
            pausedAccumulated += Date().timeIntervalSince(pauseStartedAt)
        }
        self.pauseStartedAt = nil
        phase = .active
    }

    func refreshElapsed() {
        guard let startedAt else { return }
        var extra: TimeInterval = pausedAccumulated
        if phase == .paused, let pauseStartedAt {
            extra += Date().timeIntervalSince(pauseStartedAt)
        }
        elapsed = Date().timeIntervalSince(startedAt) - extra
        if let builderElapsed = builder?.elapsedTime {
            elapsed = max(elapsed, builderElapsed)
        }
    }

    @discardableResult
    func end() async -> HKWorkout? {
        phase = .ending
        let endDate = Date()
        session?.end()

        var workout: HKWorkout?
        do {
            try await builder?.endCollection(at: endDate)
            workout = try await builder?.finishWorkout()
        } catch {
            errorMessage = error.localizedDescription
        }

        session = nil
        builder = nil
        pauseStartedAt = nil
        phase = .idle
        return workout
    }

    func cancelPreparing() async {
        session?.end()
        session = nil
        builder = nil
        phase = .idle
    }

    fileprivate func apply(_ snapshot: WorkoutMetricsSnapshot) {
        if let heartRate = snapshot.heartRate {
            currentHeartRate = heartRate
            hasReceivedHeartRate = true
        }
        if let activeCalories = snapshot.activeCalories {
            self.activeCalories = activeCalories
        }
        if let distanceMeters = snapshot.distanceMeters {
            self.distanceMeters = distanceMeters
        }
        if let elapsed = snapshot.elapsed {
            self.elapsed = elapsed
        }
    }
}

extension WorkoutSessionManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor in
            switch toState {
            case .running:
                if phase != .ending {
                    phase = .active
                }
            case .paused:
                phase = .paused
            case .stopped, .ended:
                break
            default:
                break
            }
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
        }
    }
}

extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        let snapshot = WorkoutMetricsSnapshot.extract(from: workoutBuilder, types: collectedTypes)
        Task { @MainActor in
            self.apply(snapshot)
        }
    }
}

extension WorkoutMetricsSnapshot {
    nonisolated static func extract(
        from builder: HKLiveWorkoutBuilder,
        types: Set<HKSampleType>
    ) -> WorkoutMetricsSnapshot {
        var snapshot = WorkoutMetricsSnapshot()
        snapshot.elapsed = builder.elapsedTime

        let bpmUnit = HKUnit.count().unitDivided(by: .minute())
        if let type = HKQuantityType.quantityType(forIdentifier: .heartRate),
           types.contains(type),
           let quantity = builder.statistics(for: type)?.mostRecentQuantity() {
            snapshot.heartRate = quantity.doubleValue(for: bpmUnit)
        }

        if let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
           types.contains(type),
           let quantity = builder.statistics(for: type)?.sumQuantity() {
            snapshot.activeCalories = quantity.doubleValue(for: .kilocalorie())
        }

        if let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
           types.contains(type),
           let quantity = builder.statistics(for: type)?.sumQuantity() {
            snapshot.distanceMeters = quantity.doubleValue(for: .meter())
        }

        return snapshot
    }
}

final class LocationAuthorizer: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func request() {
        manager.requestWhenInUseAuthorization()
    }
}
