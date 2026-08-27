import SwiftData
import SwiftUI

enum FoodLoggingTargets {
    static let calories: Double = 2_200
    static let proteinG: Double = 180
    static let carbsG: Double = 150
    static let fatG: Double = 80
    static let fiberG: Double = 35
    static let cholesterolFlagMg: Double = 100
}

enum FoodLoggingPreview {
    @MainActor
    static func repository() -> FoodLoggingRepository {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: DailyLog.self,
            FoodEntry.self,
            configurations: configuration
        )
        return FoodLoggingRepository(context: ModelContext(container))
    }
}

extension NutritionInfo {
    mutating func add(_ other: NutritionInfo) {
        calories += other.calories
        proteinG += other.proteinG
        carbsG += other.carbsG
        fatG += other.fatG
        fiberG += other.fiberG
        sugarG += other.sugarG
        cholesterolMg += other.cholesterolMg
        sodiumMg += other.sodiumMg
    }

    static func sum(_ items: [NutritionInfo]) -> NutritionInfo {
        items.reduce(into: NutritionInfo()) { $0.add($1) }
    }
}

extension DemoCatalog.CatalogFood {
    func makeFoodEntry(source: LogSource? = nil, confidence: Double? = nil) -> FoodEntry {
        let entry = FoodEntry(foodName: name, quantity: quantity, nutrition: nutrition)
        entry.brandName = brand
        entry.mealType = mealType
        entry.unit = unit
        entry.notes = notes
        entry.source = source ?? self.source
        entry.confidenceScore = confidence ?? self.confidence
        return entry
    }
}

func hvQuantityLabel(_ value: Double) -> String {
    if abs(value - value.rounded()) < 0.05 {
        return "\(Int(value.rounded()))"
    }
    return String(format: "%.1f", value)
}

struct FoodMacroRing: View {
    let progress: Double
    let tint: Color
    var size: CGFloat = 72
    var lineWidth: CGFloat = 7

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.22), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct FoodMealRow: View {
    let name: String
    let subtitle: String
    let calories: Double
    let proteinG: Double
    var sourceName: String?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let sourceName {
                    Text(sourceName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(hvQuantityLabel(calories)) cal")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(HVTheme.calories)
                Text("\(hvQuantityLabel(proteinG))g protein")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HVTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
    }
}

struct CholesterolAwarenessBanner: View {
    let milligrams: Double

    var body: some View {
        if milligrams >= FoodLoggingTargets.cholesterolFlagMg {
            HVInsightBanner(
                title: "Cholesterol awareness",
                bodyText: "This item is relatively high in dietary cholesterol (\(hvQuantityLabel(milligrams)) mg). HybridVital flags it for awareness because cholesterol is a tracked concern — this is not medical advice.",
                systemImage: "drop.fill",
                tint: HVTheme.warning
            )
        }
    }
}

struct FoodNutrientField: View {
    let label: String
    let unit: String
    var tint: Color = .primary
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(tint)
            Spacer()
            TextField(unit, value: $value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 84)
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)
        }
    }
}

struct FoodNutritionTiles: View {
    let nutrition: NutritionInfo

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                HVMetricTile(
                    label: "Calories",
                    value: hvQuantityLabel(nutrition.calories),
                    color: HVTheme.calories
                )
                HVMetricTile(
                    label: "Protein",
                    value: "\(hvQuantityLabel(nutrition.proteinG))g",
                    color: HVTheme.protein
                )
            }
            HStack(spacing: 10) {
                HVMetricTile(
                    label: "Carbs",
                    value: "\(hvQuantityLabel(nutrition.carbsG))g",
                    color: HVTheme.carbs
                )
                HVMetricTile(
                    label: "Fat",
                    value: "\(hvQuantityLabel(nutrition.fatG))g",
                    color: HVTheme.fat
                )
            }
            HStack(spacing: 10) {
                HVMetricTile(
                    label: "Fiber",
                    value: "\(hvQuantityLabel(nutrition.fiberG))g",
                    color: HVTheme.fiber
                )
                HVMetricTile(
                    label: "Sugar",
                    value: "\(hvQuantityLabel(nutrition.sugarG))g"
                )
            }
            HStack(spacing: 10) {
                HVMetricTile(
                    label: "Cholesterol",
                    value: "\(hvQuantityLabel(nutrition.cholesterolMg)) mg",
                    color: nutrition.cholesterolMg >= FoodLoggingTargets.cholesterolFlagMg ? HVTheme.warning : .primary
                )
                HVMetricTile(
                    label: "Sodium",
                    value: "\(hvQuantityLabel(nutrition.sodiumMg)) mg"
                )
            }
        }
    }
}
