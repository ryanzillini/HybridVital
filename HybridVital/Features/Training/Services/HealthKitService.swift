import Foundation
import HealthKit

final class HealthKitService {
    static let shared = HealthKitService()

    let store = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private var shareTypes: Set<HKSampleType> {
        [
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKObjectType.workoutType()
        ]
    }

    private var readTypes: Set<HKObjectType> {
        [
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKObjectType.workoutType()
        ]
    }

    func requestAuthorization() async throws {
        guard isAvailable else {
            throw HealthKitServiceError.unavailable
        }
        try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
    }

    func fetchHeartRateSamples(from start: Date, to end: Date) async throws -> [HKQuantitySample] {
        let type = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
        return try await descriptor.result(for: store)
    }
}

enum HealthKitServiceError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "HealthKit is not available on this device. Zone 2 tracking needs a physical iPhone."
        }
    }
}
