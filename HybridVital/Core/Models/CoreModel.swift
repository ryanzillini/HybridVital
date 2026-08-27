// Core/Models/CoreModels.swift

import SwiftData
import Foundation

// MARK: - Enums & Value Types (define BEFORE any @Model)

enum GoalType: String, Codable, CaseIterable, Identifiable {
    case cholesterolControl, hybridAthlete, longevity, muscleGain, fatLoss
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .cholesterolControl: "Cholesterol control"
        case .hybridAthlete: "Hybrid athlete"
        case .longevity: "Longevity"
        case .muscleGain: "Muscle gain"
        case .fatLoss: "Fat loss"
        }
    }
    var systemImage: String {
        switch self {
        case .cholesterolControl: "drop.fill"
        case .hybridAthlete: "figure.run"
        case .longevity: "leaf.fill"
        case .muscleGain: "dumbbell.fill"
        case .fatLoss: "flame.fill"
        }
    }
}

enum CookingSkillLevel: String, Codable, CaseIterable, Identifiable {
    case low, medium, high
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .low: "Low — keep meals simple"
        case .medium: "Medium"
        case .high: "High"
        }
    }
}

enum HealthIssue: String, Codable, CaseIterable, Identifiable {
    case constipation, lowEnergy, inflammation, highCholesterol
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .constipation: "Constipation"
        case .lowEnergy: "Low energy"
        case .inflammation: "Inflammation"
        case .highCholesterol: "High cholesterol"
        }
    }
}

enum BiologicalSex: String, Codable, CaseIterable, Identifiable {
    case male, female, other
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .other: "Other"
        }
    }
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack, other
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        case .other: return "Other"
        }
    }
}

enum LogSource: String, Codable, CaseIterable, Identifiable {
    case grokVision, manual, usda, openFoodFacts, voice
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .grokVision: "Photo"
        case .manual: "Manual"
        case .usda: "USDA"
        case .openFoodFacts: "Open Food Facts"
        case .voice: "Voice"
        }
    }
}

nonisolated struct MacroTargets: Equatable, Sendable {
    var proteinG: Int
    var carbsG: Int
    var fatG: Int
}

nonisolated struct FoodPreference: Equatable, Sendable {
    var name: String
    var isLiked: Bool
}

nonisolated struct NotificationSettings: Equatable, Sendable {
    var enabled: Bool = true
    static var `default`: NotificationSettings { NotificationSettings() }
}

nonisolated struct NutritionInfo: Equatable, Hashable, Sendable {
    var calories: Double = 0
    var proteinG: Double = 0
    var carbsG: Double = 0
    var fatG: Double = 0
    var fiberG: Double = 0
    var sugarG: Double = 0
    var cholesterolMg: Double = 0
    var sodiumMg: Double = 0
    var customValues: [String: Double] = [:]
}

nonisolated extension MacroTargets: Codable {}

nonisolated extension NotificationSettings: Codable {}

nonisolated extension NutritionInfo: Codable {}

nonisolated extension FoodPreference: Codable {}

nonisolated struct HeartRateZone: Codable, Equatable, Hashable, Identifiable, Sendable {
    var number: Int
    var name: String
    var minBPM: Int
    var maxBPM: Int

    var id: Int { number }
}

nonisolated struct HeartRateZoneSettings: Equatable, Sendable {
    var maxHR: Int
    var restingHR: Int?
    var zones: [HeartRateZone]

    static func defaultSettings(maxHR: Int = 180) -> HeartRateZoneSettings {
        HeartRateZoneSettings(maxHR: maxHR, restingHR: nil, zones: Self.zones(for: maxHR))
    }

    static func zones(for maxHR: Int) -> [HeartRateZone] {
        let clamped = max(120, maxHR)
        // Zone 1 is everything below Zone 2, including warmup / walking HR.
        let percents: [(Int, String, Double, Double)] = [
            (1, "Zone 1", 0.00, 0.60),
            (2, "Zone 2", 0.60, 0.70),
            (3, "Zone 3", 0.70, 0.80),
            (4, "Zone 4", 0.80, 0.90),
            (5, "Zone 5", 0.90, 1.00)
        ]
        return percents.map { number, name, low, high in
            HeartRateZone(
                number: number,
                name: name,
                minBPM: Int((Double(clamped) * low).rounded()),
                maxBPM: Int((Double(clamped) * high).rounded())
            )
        }
    }

    func rebuilt(maxHR: Int) -> HeartRateZoneSettings {
        HeartRateZoneSettings(maxHR: maxHR, restingHR: restingHR, zones: Self.zones(for: maxHR))
    }

    func zone(for bpm: Double) -> HeartRateZone? {
        guard !zones.isEmpty else { return nil }
        let hr = Int(bpm.rounded())
        let sorted = zones.sorted { $0.number < $1.number }

        if let match = sorted.last(where: { hr >= $0.minBPM && hr <= $0.maxBPM }) {
            return match
        }

        if let last = sorted.last, hr > last.maxBPM {
            return last
        }
        if let first = sorted.first, hr < first.minBPM {
            return first
        }

        return sorted.min { a, b in
            distance(hr, to: a) < distance(hr, to: b)
        }
    }

    private func distance(_ hr: Int, to zone: HeartRateZone) -> Int {
        if hr < zone.minBPM { return zone.minBPM - hr }
        if hr > zone.maxBPM { return hr - zone.maxBPM }
        return 0
    }

    var zone3Floor: Int {
        zones.first(where: { $0.number == 3 })?.minBPM ?? Int((Double(maxHR) * 0.70).rounded())
    }

    func isAtOrAboveZone3(bpm: Double) -> Bool {
        Int(bpm.rounded()) >= zone3Floor
    }

    func isInZone2OrBelow(bpm: Double) -> Bool {
        Int(bpm.rounded()) < zone3Floor
    }
}

nonisolated struct ZoneDurations: Equatable, Sendable {
    var zone1Seconds: Double = 0
    var zone2Seconds: Double = 0
    var zone3Seconds: Double = 0
    var zone4Seconds: Double = 0
    var zone5Seconds: Double = 0

    var totalSeconds: Double {
        zone1Seconds + zone2Seconds + zone3Seconds + zone4Seconds + zone5Seconds
    }

    var zone2Percent: Double {
        totalSeconds > 0 ? zone2Seconds / totalSeconds : 0
    }

    var atOrAboveZone3Seconds: Double {
        zone3Seconds + zone4Seconds + zone5Seconds
    }

    mutating func add(seconds: Double, zone: Int) {
        guard seconds > 0 else { return }
        switch zone {
        case 1: zone1Seconds += seconds
        case 2: zone2Seconds += seconds
        case 3: zone3Seconds += seconds
        case 4: zone4Seconds += seconds
        default: zone5Seconds += seconds
        }
    }

    func seconds(for zone: Int) -> Double {
        switch zone {
        case 1: zone1Seconds
        case 2: zone2Seconds
        case 3: zone3Seconds
        case 4: zone4Seconds
        default: zone5Seconds
        }
    }
}

nonisolated struct HRSamplePoint: Codable, Hashable, Sendable {
    var timestamp: Date
    var bpm: Double
}

nonisolated extension HeartRateZoneSettings: Codable {}

nonisolated extension ZoneDurations: Codable {}

// MARK: - Core @Model Classes (no property defaults)

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID = UUID()
    
    var firstName: String?
    var birthDate: Date?
    var heightCm: Double?
    var biologicalSex: BiologicalSex?
    
    var hasFamilialHypocholesterolemia: Bool
    var primaryGoals: [GoalType]
    var cookingSkillLevel: CookingSkillLevel
    var commonIssues: [HealthIssue]
    
    var targetMacros: MacroTargets
    
    var foodPreferences: [FoodPreference]
    var allergies: [String]
    var dislikedFoods: [String]
    
    var weeklyZone2TargetMinutes: Int
    var notificationPreferences: NotificationSettings
    var heartRateZones: HeartRateZoneSettings
    
    var createdAt: Date
    var updatedAt: Date
    
    var estimatedMaxHR: Int {
        if let birthDate,
           let age = Calendar.current.dateComponents([.year], from: birthDate, to: .now).year {
            return max(120, 220 - age)
        }
        return 180
    }
    
    init() {
        self.firstName = "Ryan"
        self.hasFamilialHypocholesterolemia = true
        self.primaryGoals = [.cholesterolControl, .hybridAthlete]
        self.cookingSkillLevel = .low
        self.commonIssues = [.constipation, .lowEnergy]
        self.targetMacros = MacroTargets(proteinG: 180, carbsG: 150, fatG: 80)
        self.foodPreferences = []
        self.allergies = []
        self.dislikedFoods = []
        self.weeklyZone2TargetMinutes = 150
        self.notificationPreferences = .default
        self.heartRateZones = .defaultSettings()
        self.createdAt = .now
        self.updatedAt = .now
    }
}

@Model
final class DailyLog {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date
    
    @Relationship(deleteRule: .cascade)
    var foodEntries: [FoodEntry] = []
    
    var energyLevel: Int?
    var constipationSeverity: Int?
    var notes: String?
    
    var createdAt: Date
    var updatedAt: Date
    
    init(date: Date = Calendar.current.startOfDay(for: .now)) {
        self.date = date
        self.createdAt = .now
        self.updatedAt = .now
    }
}

@Model
final class FoodEntry {
    @Attribute(.unique) var id: UUID = UUID()
    
    var dailyLog: DailyLog?
    
    var timestamp: Date
    var mealType: MealType
    var foodName: String
    var brandName: String?
    var quantity: Double
    var unit: String
    
    var nutrition: NutritionInfo
    var source: LogSource
    var confidenceScore: Double?
    var imageFileName: String?
    var notes: String?
    var createdAt: Date
    
    init(foodName: String, quantity: Double, nutrition: NutritionInfo) {
        self.timestamp = .now
        self.mealType = .other
        self.foodName = foodName
        self.quantity = quantity
        self.unit = "g"
        self.nutrition = nutrition
        self.source = .manual
        self.createdAt = .now
    }
}

@Model
final class TrainingSession {
    @Attribute(.unique) var id: UUID = UUID()
    var startedAt: Date
    var endedAt: Date?
    var healthKitWorkoutUUID: UUID?
    var avgHR: Double?
    var maxHR: Double?
    var minHR: Double?
    var zoneDurations: ZoneDurations
    var intervalCount: Int
    var avgJogSeconds: Double?
    var avgWalkSeconds: Double?
    var longestJogSeconds: Double?
    var fastestRecoverySeconds: Double?
    var fatigueNote: String?
    var notes: String?
    var downsampledHR: [HRSamplePoint]
    var activeCalories: Double?
    var distanceMeters: Double?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \WorkoutInterval.session)
    var intervals: [WorkoutInterval] = []

    var durationSeconds: Double {
        (endedAt ?? .now).timeIntervalSince(startedAt)
    }

    var sortedIntervals: [WorkoutInterval] {
        intervals.sorted { $0.startedAt < $1.startedAt }
    }

    init(startedAt: Date) {
        self.startedAt = startedAt
        self.zoneDurations = ZoneDurations()
        self.intervalCount = 0
        self.downsampledHR = []
        self.createdAt = .now
    }
}

@Model
final class WorkoutInterval {
    @Attribute(.unique) var id: UUID = UUID()
    var kind: IntervalKind
    var startedAt: Date
    var endedAt: Date?
    var startHR: Double?
    var endHR: Double?
    var avgHR: Double?
    var maxHR: Double?
    var minHR: Double?
    var durationSeconds: Double
    var timeToReenterZone2Seconds: Double?
    var session: TrainingSession?

    init(kind: IntervalKind, startedAt: Date, startHR: Double?) {
        self.kind = kind
        self.startedAt = startedAt
        self.startHR = startHR
        self.durationSeconds = 0
    }
}
