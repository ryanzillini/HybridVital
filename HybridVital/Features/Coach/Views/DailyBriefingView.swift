import SwiftUI

struct DailyBriefingView: View {
    @State private var trainingDays = DemoCatalog.weekTraining
    @State private var macroDays = DemoCatalog.weekMacros

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                intro
                trainingRecap
                nutritionRecap
                todayFocus
                suggestedMeals
                HVDisclaimer()
            }
            .padding(.horizontal, HVTheme.pagePadding)
            .padding(.vertical, 16)
        }
        .navigationTitle("Daily briefing")
        .hvInlineNav()
        .hvScreen()
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Morning briefing", systemImage: "sun.horizon.fill")
                .font(.headline)
                .foregroundStyle(HVTheme.coach)
            Text(Date.now, format: .dateTime.weekday(.wide).month().day())
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(DemoCatalog.weeklyReportSummary)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var trainingRecap: some View {
        VStack(alignment: .leading, spacing: 12) {
            HVSectionHeader(title: "Training recap", accessory: "Zone 2")
            HVCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(DemoCatalog.weeklyZone2CompletedMinutes)")
                            .font(HVFont.heroMetric(36))
                            .foregroundStyle(HVTheme.accent)
                        Text("/ \(DemoCatalog.weeklyZone2TargetMinutes) min")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    HVProgressBar(
                        progress: trainingProgress,
                        tint: HVTheme.accent
                    )
                    Text("Ahead of the weekly target — extra volume, not a cue to add intensity. Last sessions stayed mostly in Zone 2 with a few Z3 spikes.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(trainingDays, id: \.date) { day in
                            VStack(spacing: 6) {
                                Capsule()
                                    .fill(day.zone2Minutes > 0 ? HVTheme.accent : HVTheme.tertiaryFill)
                                    .frame(height: barHeight(for: day.zone2Minutes))
                                Text(day.date, format: .dateTime.weekday(.narrow))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Text(day.zone2Minutes > 0 ? "\(day.zone2Minutes)" : "—")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(trainingAccessibility(day))
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private var nutritionRecap: some View {
        VStack(alignment: .leading, spacing: 12) {
            HVSectionHeader(title: "Nutrition recap", accessory: "7 days")
            HStack(spacing: 10) {
                HVMetricTile(
                    label: "Protein avg",
                    value: "\(avgProtein)g",
                    color: HVTheme.protein,
                    caption: "Target 180g"
                )
                HVMetricTile(
                    label: "Fiber avg",
                    value: "\(avgFiber)g",
                    color: HVTheme.fiber,
                    caption: "Target 35g"
                )
                HVMetricTile(
                    label: "Calories avg",
                    value: "\(avgCalories)",
                    color: HVTheme.calories,
                    caption: "Logged week"
                )
            }

            if let dip = lowestFiberDay {
                HVInsightBanner(
                    title: "Fiber dipped midweek",
                    bodyText: "\(dip.date.formatted(.dateTime.weekday(.wide))) landed at \(Int(dip.fiberG))g fiber with energy \(dip.energy)/10. That’s a log pattern — not a GI diagnosis. Frozen berries or kiwi are the low-cook bump.",
                    systemImage: "leaf.fill",
                    tint: HVTheme.fiber
                )
            }
        }
    }

    private var todayFocus: some View {
        VStack(alignment: .leading, spacing: 12) {
            HVSectionHeader(title: "Focus for today")
            HVCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Close the protein gap, then fiber", systemImage: "target")
                        .font(.headline)
                        .foregroundStyle(HVTheme.coach)
                    CoachChipStrip(
                        chips: DemoCatalog.conversation.first(where: { $0.role == .system })?.chips ?? [],
                        accessibilityLabelText: "Today’s open loops"
                    )
                    Text("Protein is the open loop — well below 180g so far. Fiber is also short of 35g. A salmon plate plus berries (or a Core Power) is the low-cook, cholesterol-aware path. This is a logging target, not a medical plan.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous)
                    .stroke(HVTheme.coach.opacity(0.28), lineWidth: 1)
            }
        }
    }

    private var suggestedMeals: some View {
        VStack(alignment: .leading, spacing: 12) {
            HVSectionHeader(title: "Suggested meals", accessory: "Low cook")
            ForEach(suggestedFoods) { food in
                HVCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(food.name)
                                .font(.headline)
                            Spacer()
                            Text("\(Int(food.nutrition.proteinG))g P")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(HVTheme.protein)
                        }
                        Text(reason(for: food))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 12) {
                            labeledValue("Fiber", "\(Int(food.nutrition.fiberG))g", HVTheme.fiber)
                            labeledValue(
                                "Chol.",
                                "\(Int(food.nutrition.cholesterolMg))mg",
                                food.nutrition.cholesterolMg >= 100 ? HVTheme.warning : HVTheme.coach
                            )
                            labeledValue("Cal", "\(Int(food.nutrition.calories))", HVTheme.calories)
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var suggestedFoods: [DemoCatalog.CatalogFood] {
        let allowed = ["yogurt", "salmon", "berries", "core power", "oats"]
        return DemoCatalog.searchResults.filter { food in
            let name = food.name.lowercased()
            return allowed.contains { name.contains($0) }
        }
    }

    private func reason(for food: DemoCatalog.CatalogFood) -> String {
        let name = food.name.lowercased()
        if name.contains("salmon") {
            return "High protein, pantry-level cook. More cholesterol-aware than a heavy meat plate."
        }
        if name.contains("yogurt") {
            return "Fast protein. Pair with berries if fiber is the other gap."
        }
        if name.contains("berries") {
            return "Fiber bump for constipation-aware days. No cooking."
        }
        if name.contains("core power") || name.contains("fairlife") {
            return "Closes a protein gap when you don’t want to cook."
        }
        if name.contains("oats") {
            return "Warm, low-skill fiber. Keep toppings simple and cholesterol-aware."
        }
        return food.notes ?? "Low-cook staple from your catalog."
    }

    private var trainingProgress: Double {
        let target = Double(max(DemoCatalog.weeklyZone2TargetMinutes, 1))
        return Double(DemoCatalog.weeklyZone2CompletedMinutes) / target
    }

    private var avgProtein: Int {
        average(\.proteinG)
    }

    private var avgFiber: Int {
        average(\.fiberG)
    }

    private var avgCalories: Int {
        average(\.calories)
    }

    private func average(_ key: KeyPath<DemoCatalog.MacroDay, Double>) -> Int {
        guard !macroDays.isEmpty else { return 0 }
        let total = macroDays.reduce(0.0) { $0 + $1[keyPath: key] }
        return Int((total / Double(macroDays.count)).rounded())
    }

    private var lowestFiberDay: DemoCatalog.MacroDay? {
        macroDays.min(by: { $0.fiberG < $1.fiberG })
    }

    private func barHeight(for minutes: Int) -> CGFloat {
        let maxMinutes = max(trainingDays.map(\.zone2Minutes).max() ?? 1, 1)
        let ratio = CGFloat(minutes) / CGFloat(maxMinutes)
        return max(6, ratio * 56)
    }

    private func trainingAccessibility(_ day: DemoCatalog.TrainingDay) -> String {
        let weekday = day.date.formatted(.dateTime.weekday(.wide))
        if day.zone2Minutes == 0 {
            return "\(weekday), rest"
        }
        return "\(weekday), \(day.zone2Minutes) minutes Zone 2"
    }

    private func labeledValue(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
        }
    }
}
