import Foundation
import HealthKit
import Observation
import SwiftData
import UIKit

struct InMemoryInterval: Identifiable, Sendable {
    var id = UUID()
    var kind: IntervalKind
    var startedAt: Date
    var endedAt: Date?
    var startHR: Double?
    var endHR: Double?
    var samples: [Double] = []
    var timeToReenterZone2Seconds: Double?

    var durationSeconds: Double {
        (endedAt ?? .now).timeIntervalSince(startedAt)
    }

    var avgHR: Double? {
        guard !samples.isEmpty else { return startHR }
        return samples.reduce(0, +) / Double(samples.count)
    }

    var maxHR: Double? {
        samples.max() ?? startHR
    }

    var minHR: Double? {
        samples.min() ?? startHR
    }
}

@MainActor
enum LiveTrackerBridge {
    static weak var viewModel: LiveTrackerViewModel?
}

@Observable
@MainActor
final class LiveTrackerViewModel {
    let sessionManager = WorkoutSessionManager()
    let heartRateMonitor = HeartRateBLEService()
    let haptic = HapticCoach()

    var zoneSettings: HeartRateZoneSettings
    var currentKind: IntervalKind = .jog
    var intervals: [InMemoryInterval] = []
    var flashZ3 = false
    var showingHelp = false
    var savedSession: TrainingSession?
    var isSaving = false

    private var calculator: ZoneCalculator
    private var liveActivity = Zone2LiveActivityController()
    private var loopTask: Task<Void, Never>?
    private var lastDownsample: Date?
    private var hrSeries: [HRSamplePoint] = []
    private let repository: TrainingRepository

    init(repository: TrainingRepository) {
        self.repository = repository
        let settings = repository.getOrCreateProfile().heartRateZones
        self.zoneSettings = settings
        self.calculator = ZoneCalculator(settings: settings)
    }

    var phase: WorkoutPhase { sessionManager.phase }
    var currentHeartRate: Double? { heartRateMonitor.currentBPM ?? sessionManager.currentHeartRate }
    var elapsed: TimeInterval { sessionManager.elapsed }
    var hasReceivedHeartRate: Bool { heartRateMonitor.currentBPM != nil || sessionManager.hasReceivedHeartRate }
    var errorMessage: String? { sessionManager.errorMessage ?? heartRateMonitor.lastError }
    var activeCalories: Double { sessionManager.activeCalories }
    var distanceMeters: Double { sessionManager.distanceMeters }

    var currentZone: HeartRateZone? {
        calculator.currentZone
    }

    var timeInZone2: TimeInterval {
        calculator.durations.zone2Seconds
    }

    var currentIntervalElapsed: TimeInterval {
        intervals.last?.durationSeconds ?? 0
    }

    var canUndo: Bool {
        intervals.count > 1
    }

    var isSessionLive: Bool {
        switch phase {
        case .active, .paused, .preparing, .countdown: true
        default: false
        }
    }

    var lapButtonTitle: String {
        currentKind == .jog ? "Entered Z3 — Walk" : "Back to Jog"
    }

    func onAppear() {
        LiveTrackerBridge.viewModel = self
        LapToggleChannel.startListening {
            Task { @MainActor in
                LiveTrackerBridge.viewModel?.drainExternalLaps()
            }
        }
        reloadZones()
        Task {
            try? await HealthKitService.shared.requestAuthorization()
            sessionManager.requestLocation()
            heartRateMonitor.startScanning()
        }
    }

    func onDisappear() {
        if !isSessionLive {
            heartRateMonitor.stop()
            LiveTrackerBridge.viewModel = nil
        }
    }

    func reloadZones() {
        zoneSettings = repository.getOrCreateProfile().heartRateZones
        calculator.settings = zoneSettings
    }

    func start() async {
        UIApplication.shared.isIdleTimerDisabled = true
        currentKind = .jog
        intervals = []
        hrSeries = []
        lastDownsample = nil
        savedSession = nil
        calculator = ZoneCalculator(settings: zoneSettings)

        await sessionManager.start()
        guard phase == .active else {
            UIApplication.shared.isIdleTimerDisabled = false
            return
        }

        let startDate = sessionManager.startedAt ?? .now
        intervals = [
            InMemoryInterval(kind: .jog, startedAt: startDate, startHR: sessionManager.currentHeartRate)
        ]
        startLiveActivity(at: startDate)
        startLoop()
    }

    func pauseOrResume() {
        if phase == .paused {
            sessionManager.resume()
        } else if phase == .active {
            sessionManager.pause()
        }
        pushLiveActivity()
    }

    func toggleLap(at date: Date = .now) {
        guard phase == .active || phase == .paused else { return }
        closeOpenInterval(at: date)
        currentKind = currentKind.toggled
        let bpm = sessionManager.currentHeartRate
        intervals.append(InMemoryInterval(kind: currentKind, startedAt: date, startHR: bpm))
        haptic.lapConfirmed()
        pushLiveActivity()
    }

    func undoLastLap() {
        guard canUndo else { return }
        let removed = intervals.removeLast()
        if var previous = intervals.popLast() {
            previous.endedAt = nil
            previous.timeToReenterZone2Seconds = nil
            intervals.append(previous)
            currentKind = previous.kind
        }
        _ = removed
        haptic.lapConfirmed()
        pushLiveActivity()
    }

    func drainExternalLaps() {
        let dates = LapToggleStore.drain()
        for date in dates {
            toggleLap(at: date)
        }
    }

    func endSession() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        loopTask?.cancel()
        loopTask = nil
        closeOpenInterval(at: .now)
        UIApplication.shared.isIdleTimerDisabled = false
        await liveActivity.end()

        let startDate = sessionManager.startedAt ?? intervals.first?.startedAt ?? .now
        let hkWorkout = await sessionManager.end()
        let endDate = Date()
        let hkSamples = (try? await HealthKitService.shared.fetchHeartRateSamples(from: startDate, to: endDate)) ?? []
        let session = persistSession(
            healthKitWorkout: hkWorkout,
            startedAt: startDate,
            endedAt: endDate,
            hkSamples: hkSamples
        )
        savedSession = session
        heartRateMonitor.stop()
        LiveTrackerBridge.viewModel = nil
    }

    func cancelSetup() async {
        loopTask?.cancel()
        loopTask = nil
        UIApplication.shared.isIdleTimerDisabled = false
        await sessionManager.cancelPreparing()
        await liveActivity.end()
        heartRateMonitor.stop()
        LiveTrackerBridge.viewModel = nil
    }

    private func startLoop() {
        loopTask?.cancel()
        loopTask = Task { @MainActor [weak self] in
            while let self, !Task.isCancelled {
                self.tick()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func tick() {
        sessionManager.refreshElapsed()
        drainExternalLaps()

        if let bpm = currentHeartRate {
            sessionManager.recordHeartRate(bpm)
            let event = calculator.ingest(bpm: bpm)
            handle(event)
            recordSample(bpm: bpm)
        }

        if phase == .active, !hasReceivedHeartRate, elapsed > 15 {
            showingHelp = true
        }

        pushLiveActivity()
    }

    private func handle(_ event: ZoneCalculator.CrossEvent) {
        switch event {
        case .enteredZone3:
            haptic.enteredZone3()
            flashZ3 = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(900))
                flashZ3 = false
            }
        case .returnedToZone2:
            haptic.returnedToZone2()
            if var current = intervals.last, current.kind == .walk, current.timeToReenterZone2Seconds == nil {
                current.timeToReenterZone2Seconds = current.durationSeconds
                intervals[intervals.count - 1] = current
            }
        case .none:
            break
        }
    }

    private func recordSample(bpm: Double) {
        let now = Date()
        if var current = intervals.last {
            current.samples.append(bpm)
            intervals[intervals.count - 1] = current
        }

        if lastDownsample == nil || now.timeIntervalSince(lastDownsample ?? .distantPast) >= 5 {
            hrSeries.append(HRSamplePoint(timestamp: now, bpm: bpm))
            lastDownsample = now
        }
    }

    private func closeOpenInterval(at date: Date) {
        guard var current = intervals.last, current.endedAt == nil else { return }
        current.endedAt = date
        current.endHR = sessionManager.currentHeartRate
        intervals[intervals.count - 1] = current
    }

    private func startLiveActivity(at date: Date) {
        liveActivity.start(startedAt: date, state: contentState())
    }

    private func pushLiveActivity() {
        liveActivity.update(contentState())
    }

    private func contentState() -> Zone2ActivityAttributes.ContentState {
        let bpm = Int((sessionManager.currentHeartRate ?? 0).rounded())
        let zone = calculator.currentZone
        return Zone2ActivityAttributes.ContentState(
            heartRate: bpm,
            zoneNumber: zone?.number ?? 0,
            zoneName: zone?.name ?? "Waiting",
            intervalKind: currentKind,
            elapsedSeconds: Int(sessionManager.elapsed),
            timeInZone2Seconds: Int(calculator.durations.zone2Seconds),
            isPaused: phase == .paused,
            isAboveZone3: zone.map { $0.number >= 3 } ?? false
        )
    }

    private func persistSession(
        healthKitWorkout: HKWorkout?,
        startedAt: Date,
        endedAt: Date,
        hkSamples: [HKQuantitySample]
    ) -> TrainingSession {
        let session = TrainingSession(startedAt: startedAt)
        session.endedAt = endedAt
        session.healthKitWorkoutUUID = healthKitWorkout?.uuid
        session.activeCalories = workoutEnergy(healthKitWorkout) ?? activeCalories
        session.distanceMeters = workoutDistance(healthKitWorkout) ?? distanceMeters

        let bpmUnit = HKUnit.count().unitDivided(by: .minute())
        let points: [HRSamplePoint]
        if hkSamples.count > 1 {
            points = downsample(hkSamples, unit: bpmUnit)
            var hkCalculator = ZoneCalculator(settings: zoneSettings)
            for sample in hkSamples {
                _ = hkCalculator.ingest(bpm: sample.quantity.doubleValue(for: bpmUnit), at: sample.startDate)
            }
            session.zoneDurations = hkCalculator.durations
        } else {
            points = hrSeries
            session.zoneDurations = calculator.durations
        }
        session.downsampledHR = points

        let bpmValues = points.map(\.bpm)
        if !bpmValues.isEmpty {
            session.avgHR = bpmValues.reduce(0, +) / Double(bpmValues.count)
            session.maxHR = bpmValues.max()
            session.minHR = bpmValues.min()
        }

        let closed = intervals.map { memory -> WorkoutInterval in
            let model = WorkoutInterval(kind: memory.kind, startedAt: memory.startedAt, startHR: memory.startHR)
            model.endedAt = memory.endedAt
            model.endHR = memory.endHR
            model.avgHR = memory.avgHR
            model.maxHR = memory.maxHR
            model.minHR = memory.minHR
            model.durationSeconds = memory.durationSeconds
            model.timeToReenterZone2Seconds = memory.timeToReenterZone2Seconds
                ?? recoverySeconds(for: memory, samples: hkSamples, unit: bpmUnit)
            return model
        }

        session.intervals = closed
        session.intervalCount = closed.count

        let jogs = closed.filter { $0.kind == .jog }
        let walks = closed.filter { $0.kind == .walk }
        if !jogs.isEmpty {
            session.avgJogSeconds = jogs.map(\.durationSeconds).reduce(0, +) / Double(jogs.count)
            session.longestJogSeconds = jogs.map(\.durationSeconds).max()
        }
        if !walks.isEmpty {
            session.avgWalkSeconds = walks.map(\.durationSeconds).reduce(0, +) / Double(walks.count)
            let recoveries = walks.compactMap(\.timeToReenterZone2Seconds)
            session.fastestRecoverySeconds = recoveries.min() ?? walks.map(\.durationSeconds).min()
        }
        session.fatigueNote = Self.fatigueNote(jogs: jogs)

        repository.save(session: session)
        return session
    }

    private func workoutEnergy(_ workout: HKWorkout?) -> Double? {
        workout?.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie())
    }

    private func workoutDistance(_ workout: HKWorkout?) -> Double? {
        workout?.statistics(for: HKQuantityType(.distanceWalkingRunning))?.sumQuantity()?.doubleValue(for: .meter())
    }

    private func downsample(_ samples: [HKQuantitySample], unit: HKUnit) -> [HRSamplePoint] {
        var last: Date?
        var points: [HRSamplePoint] = []
        for sample in samples {
            if let last, sample.startDate.timeIntervalSince(last) < 5 { continue }
            points.append(HRSamplePoint(timestamp: sample.startDate, bpm: sample.quantity.doubleValue(for: unit)))
            last = sample.startDate
        }
        return points
    }

    private func recoverySeconds(for interval: InMemoryInterval, samples: [HKQuantitySample], unit: HKUnit) -> Double? {
        guard interval.kind == .walk else { return nil }
        let end = interval.endedAt ?? .now
        let floor = Double(zoneSettings.zone3Floor)
        if let sample = samples.first(where: { sample in
            sample.startDate >= interval.startedAt
                && sample.startDate <= end
                && sample.quantity.doubleValue(for: unit) < floor
        }) {
            return sample.startDate.timeIntervalSince(interval.startedAt)
        }
        return nil
    }

    private static func fatigueNote(jogs: [WorkoutInterval]) -> String? {
        guard jogs.count >= 4 else { return nil }
        let midpoint = jogs.count / 2
        let first = jogs.prefix(midpoint).map(\.durationSeconds)
        let second = jogs.suffix(from: midpoint).map(\.durationSeconds)
        let firstAvg = first.reduce(0, +) / Double(first.count)
        let secondAvg = second.reduce(0, +) / Double(second.count)
        guard firstAvg > 0, secondAvg < firstAvg * 0.85 else { return nil }
        return "Later jogs were shorter — fatigue showing."
    }
}
