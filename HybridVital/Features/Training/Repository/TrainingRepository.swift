import Foundation
import Observation
import SwiftData

@Observable
final class TrainingRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getOrCreateProfile() -> UserProfile {
        var descriptor = FetchDescriptor<UserProfile>(sortBy: [SortDescriptor(\.createdAt)])
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let profile = UserProfile()
        profile.heartRateZones = .defaultSettings(maxHR: profile.estimatedMaxHR)
        context.insert(profile)
        saveContext()
        return profile
    }

    func saveZoneSettings(_ settings: HeartRateZoneSettings) {
        let profile = getOrCreateProfile()
        profile.heartRateZones = settings
        profile.updatedAt = .now
        saveContext()
    }

    func saveProfile(_ mutate: (UserProfile) -> Void) {
        let profile = getOrCreateProfile()
        mutate(profile)
        profile.updatedAt = .now
        saveContext()
    }

    func save(session: TrainingSession) {
        context.insert(session)
        for interval in session.intervals where interval.modelContext == nil {
            context.insert(interval)
        }
        saveContext()
    }

    func recentSessions(limit: Int = 20) -> [TrainingSession] {
        var descriptor = FetchDescriptor<TrainingSession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    func delete(session: TrainingSession) {
        context.delete(session)
        saveContext()
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("[Training] Save failed: \(error)")
        }
    }
}
