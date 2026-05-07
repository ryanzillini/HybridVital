// Core/Models/CoreModels.swift

import SwiftData
import Foundation

// MARK: - Enums & Value Types (define BEFORE any @Model)

enum GoalType: String, Codable, CaseIterable {
    case cholesterolControl, hybridAthlete, longevity, muscleGain, fatLoss
}

enum CookingSkillLevel: String, Codable {
    case low, medium, high
}

enum HealthIssue: String, Codable {
    case constipation, lowEnergy, inflammation, highCholesterol
}

enum BiologicalSex: String, Codable {
    case male, female, other
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

enum LogSource: String, Codable {
    case grokVision, manual, usda, openFoodFacts, voice
}

struct MacroTargets: Codable, Equatable {
    var proteinG: Int
    var carbsG: Int
    var fatG: Int
}

struct FoodPreference: Codable, Equatable {
    var name: String
    var isLiked: Bool
}

struct NotificationSettings: Codable, Equatable {
    var enabled: Bool = true
    static var `default`: NotificationSettings { NotificationSettings() }
}

struct NutritionInfo: Codable, Equatable, Hashable {
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
    
    var createdAt: Date
    var updatedAt: Date
    
    init() {
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
