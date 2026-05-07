# Data Models — HybridVital

**Last Updated:** May 6, 2026  
**Philosophy**: Local-first, extensible, normalized where it matters, embedded where performance matters. Designed to grow from MVP to millions of users and full medical record support.

## Core Principles

- **HealthKit** = Source of truth for all biometric/workout data Apple can provide.
- **SwiftData** = App’s source of truth for everything else.
- **Easy to Extend** — New features (bloodwork trends, supplement tracking, sleep notes, etc.) should require minimal migration.
- **Performance** — DailyLog acts as the central hub for fast dashboard queries.
- **Privacy** — Sensitive fields clearly marked for future encryption/HIPAA.

---

## 1. UserProfile (Singleton per user)

```swift
@Model
final class UserProfile {
    var id: UUID = UUID()

    // Personal
    var firstName: String?
    var birthDate: Date?
    var heightCm: Double?
    var biologicalSex: BiologicalSex?

    // Core Conditions & Goals
    var hasFamilialHypocholesterolemia: Bool = true
    var primaryGoals: [GoalType] = []          // .cholesterolControl, .hybridAthlete, .longevity, etc.
    var targetMacros: MacroTargets
    var cookingSkillLevel: CookingSkillLevel = .low
    var commonIssues: [HealthIssue] = []       // .constipation, .lowEnergy, .inflammation

    // Preferences
    var foodPreferences: [FoodPreference]
    var allergies: [String]
    var dislikedFoods: [String]

    // Settings
    var weeklyZone2TargetMinutes: Int = 150
    var dailyProteinTargetG: Int = 180
    var notificationPreferences: NotificationSettings

    // Timestamps
    var createdAt: Date = .now
    var updatedAt: Date = .now
}
```
