import Foundation
import SwiftUI

enum DemoCatalog {
    static let firstName = "Ryan"

    static var greetingName: String { firstName }

    // MARK: - Nutrition week

    struct MacroDay: Identifiable {
        let id = UUID()
        let date: Date
        let calories: Double
        let proteinG: Double
        let carbsG: Double
        let fatG: Double
        let fiberG: Double
        let energy: Int
        let constipation: Int
    }

    static var weekMacros: [MacroDay] {
        let cal = Calendar.current
        return (0..<7).reversed().compactMap { offset -> MacroDay? in
            guard let date = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: .now)) else {
                return nil
            }
            let wave = Double(offset)
            return MacroDay(
                date: date,
                calories: 2100 + (wave * 40) - 80,
                proteinG: 150 + (offset == 2 ? -35 : 18),
                carbsG: 140 + wave * 6,
                fatG: 70 + wave,
                fiberG: offset == 2 ? 12 : 28 + wave,
                energy: offset == 2 ? 3 : 7,
                constipation: offset == 2 ? 4 : 1
            )
        }
    }

    static var monthMacros: [MacroDay] {
        let cal = Calendar.current
        return (0..<28).reversed().compactMap { offset -> MacroDay? in
            guard let date = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: .now)) else {
                return nil
            }
            let cycle = Double(offset % 7)
            return MacroDay(
                date: date,
                calories: 2000 + cycle * 55,
                proteinG: 155 + cycle * 4,
                carbsG: 130 + cycle * 8,
                fatG: 68 + cycle,
                fiberG: 22 + cycle,
                energy: 5 + Int(cycle) % 4,
                constipation: offset % 9 == 2 ? 3 : 1
            )
        }
    }

    // MARK: - Training week

    struct TrainingDay: Identifiable {
        let id = UUID()
        let date: Date
        let zone2Minutes: Int
        let avgHR: Int
        let z2Percent: Int
    }

    static var weekTraining: [TrainingDay] {
        let cal = Calendar.current
        let minutes = [0, 42, 0, 55, 0, 38, 48]
        return minutes.enumerated().compactMap { index, value -> TrainingDay? in
            guard let date = cal.date(byAdding: .day, value: index - 6, to: cal.startOfDay(for: .now)) else {
                return nil
            }
            return TrainingDay(
                date: date,
                zone2Minutes: value,
                avgHR: value == 0 ? 0 : 138 + index,
                z2Percent: value == 0 ? 0 : 72 + index
            )
        }
    }

    static let weeklyZone2TargetMinutes = 150
    static let weeklyZone2CompletedMinutes = 183

    // MARK: - Food search / vision

    struct CatalogFood: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let brand: String?
        let mealType: MealType
        let source: LogSource
        let quantity: Double
        let unit: String
        let nutrition: NutritionInfo
        let confidence: Double?
        let notes: String?
    }

    static let searchResults: [CatalogFood] = [
        CatalogFood(
            name: "Nonfat Greek yogurt",
            brand: "Fage",
            mealType: .breakfast,
            source: .openFoodFacts,
            quantity: 170,
            unit: "g",
            nutrition: NutritionInfo(calories: 100, proteinG: 18, carbsG: 7, fatG: 0, fiberG: 0, sugarG: 7, cholesterolMg: 10, sodiumMg: 65),
            confidence: 0.94,
            notes: nil
        ),
        CatalogFood(
            name: "Canned salmon",
            brand: "Safe Catch",
            mealType: .lunch,
            source: .usda,
            quantity: 85,
            unit: "g",
            nutrition: NutritionInfo(calories: 140, proteinG: 21, carbsG: 0, fatG: 6, fiberG: 0, sugarG: 0, cholesterolMg: 55, sodiumMg: 240),
            confidence: 0.91,
            notes: nil
        ),
        CatalogFood(
            name: "Frozen mixed berries",
            brand: nil,
            mealType: .snack,
            source: .usda,
            quantity: 140,
            unit: "g",
            nutrition: NutritionInfo(calories: 70, proteinG: 1, carbsG: 17, fatG: 0.5, fiberG: 6, sugarG: 11, cholesterolMg: 0, sodiumMg: 2),
            confidence: 0.88,
            notes: nil
        ),
        CatalogFood(
            name: "Chicken thigh, roasted",
            brand: nil,
            mealType: .dinner,
            source: .usda,
            quantity: 180,
            unit: "g",
            nutrition: NutritionInfo(calories: 320, proteinG: 38, carbsG: 0, fatG: 18, fiberG: 0, sugarG: 0, cholesterolMg: 145, sodiumMg: 160),
            confidence: 0.86,
            notes: nil
        ),
        CatalogFood(
            name: "Oats, dry",
            brand: "Quaker",
            mealType: .breakfast,
            source: .openFoodFacts,
            quantity: 40,
            unit: "g",
            nutrition: NutritionInfo(calories: 150, proteinG: 5, carbsG: 27, fatG: 3, fiberG: 4, sugarG: 1, cholesterolMg: 0, sodiumMg: 0),
            confidence: 0.9,
            notes: nil
        ),
        CatalogFood(
            name: "Fairlife Core Power",
            brand: "Fairlife",
            mealType: .snack,
            source: .openFoodFacts,
            quantity: 414,
            unit: "ml",
            nutrition: NutritionInfo(calories: 170, proteinG: 26, carbsG: 8, fatG: 4.5, fiberG: 0, sugarG: 6, cholesterolMg: 20, sodiumMg: 260),
            confidence: 0.97,
            notes: nil
        )
    ]

    static let visionParse = CatalogFood(
        name: "Greek yogurt bowl with berries and honey",
        brand: nil,
        mealType: .breakfast,
        source: .grokVision,
        quantity: 1,
        unit: "bowl",
        nutrition: NutritionInfo(
            calories: 420,
            proteinG: 32,
            carbsG: 48,
            fatG: 10,
            fiberG: 8,
            sugarG: 28,
            cholesterolMg: 15,
            sodiumMg: 90
        ),
        confidence: 0.81,
        notes: "Low-cook. Watch added honey if cholesterol-focused."
    )

    static let todayMeals: [CatalogFood] = [
        CatalogFood(
            name: "Greek yogurt + berries",
            brand: nil,
            mealType: .breakfast,
            source: .grokVision,
            quantity: 1,
            unit: "bowl",
            nutrition: NutritionInfo(calories: 380, proteinG: 32, carbsG: 42, fatG: 8, fiberG: 7, sugarG: 24, cholesterolMg: 12, sodiumMg: 80),
            confidence: 0.84,
            notes: nil
        ),
        CatalogFood(
            name: "Canned salmon salad",
            brand: nil,
            mealType: .lunch,
            source: .manual,
            quantity: 1,
            unit: "plate",
            nutrition: NutritionInfo(calories: 520, proteinG: 44, carbsG: 18, fatG: 28, fiberG: 8, sugarG: 4, cholesterolMg: 70, sodiumMg: 480),
            confidence: nil,
            notes: "Olive oil + mixed greens"
        )
    ]

    // MARK: - Coach

    struct ChatMessage: Identifiable, Hashable {
        enum Role: String {
            case user, coach, system
        }
        let id = UUID()
        let role: Role
        let text: String
        let timestamp: Date
        var chips: [String] = []
    }

    static var conversation: [ChatMessage] {
        let now = Date()
        return [
            ChatMessage(
                role: .system,
                text: "Coach loaded today’s macros, last Zone 2 session, and your cholesterol + fiber goals.",
                timestamp: now.addingTimeInterval(-3600),
                chips: ["Protein 76g / 180g", "Fiber 15g / 35g", "Z2 183 min this week"]
            ),
            ChatMessage(
                role: .user,
                text: "I felt sluggish after yesterday’s run. Dinner ideas that are high protein and easy?",
                timestamp: now.addingTimeInterval(-3500)
            ),
            ChatMessage(
                role: .coach,
                text: "Yesterday’s Zone 2 was 48 minutes with a few Z3 spikes — that can leave you a bit flat if dinner was light on carbs and fiber.\n\nKeep it low-cook: canned salmon over mixed greens with olive oil, plus a Fairlife shake if you still need ~40g protein. If constipation has been an issue, add frozen berries or a kiwi rather than a heavy grain bowl.",
                timestamp: now.addingTimeInterval(-3440),
                chips: ["Low cook", "Cholesterol-aware", "Fiber bump"]
            )
        ]
    }

    static let suggestedPrompts: [String] = [
        "What should I eat after Zone 2?",
        "Am I on pace for 180g protein?",
        "Low-energy day plan",
        "Simple high-fiber lunch"
    ]

    struct Insight: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let body: String
        let systemImage: String
        let kind: String
    }

    static let insights: [Insight] = [
        Insight(
            title: "Fiber dip, energy dip",
            body: "Energy dropped on the day fiber landed at 12g. A 25g+ day has usually tracked with steadier afternoon energy.",
            systemImage: "leaf.fill",
            kind: "Learned pattern"
        ),
        Insight(
            title: "Zone 2 week is ahead",
            body: "183 of 150 target minutes. Recovery walks after Z3 spikes have been getting faster this month.",
            systemImage: "heart.fill",
            kind: "Rolling metric"
        ),
        Insight(
            title: "Protein still open",
            body: "76g of 180g so far today. A salmon plate plus a Core Power gets you close without cooking.",
            systemImage: "fork.knife",
            kind: "Live context"
        )
    ]

    struct MemoryItem: Identifiable {
        let id = UUID()
        var title: String
        var detail: String
        var layer: String
        var isEnabled: Bool
    }

    static let memories: [MemoryItem] = [
        MemoryItem(title: "Familial hypocholesterolemia", detail: "Stay conservative on dietary cholesterol advice. Flag high-cholesterol meals.", layer: "Permanent profile", isEnabled: true),
        MemoryItem(title: "Protein target 180g", detail: "Primary daily macro. Prefer dairy + fish when cooking energy is low.", layer: "Permanent profile", isEnabled: true),
        MemoryItem(title: "Cooking skill: low", detail: "Default to canned, frozen, and shake-based meals.", layer: "Permanent profile", isEnabled: true),
        MemoryItem(title: "Constipation + low energy", detail: "Watch fiber streaks and afternoon energy ratings.", layer: "Permanent profile", isEnabled: true),
        MemoryItem(title: "7-day fiber average 24g", detail: "Rolling window from daily logs.", layer: "Rolling metrics", isEnabled: true),
        MemoryItem(title: "Energy falls after low-fiber days", detail: "Suggested by Coach from the last 30 days. You can forget this.", layer: "Learned patterns", isEnabled: true)
    ]

    static let weeklyReportSummary = """
    Strong Zone 2 week — volume is above the 150 minute target. Protein averaged ~168g, a little under 180g on two weeknights. Fiber dipped midweek and energy followed. Keep the low-cook salmon / yogurt / berry pattern and add one high-fiber snack on training days.
    """
}
