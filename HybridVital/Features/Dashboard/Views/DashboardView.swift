import SwiftData
import SwiftUI

@MainActor
@Observable
final class DashboardViewModel {
    let services: AppServices

    var profile: UserProfile?
    var todayEntries: [FoodEntry] = []
    var todayTotals: NutritionInfo = NutritionInfo()
    var todayLog: DailyLog?
    var sessions: [TrainingSession] = []

    /// Personal logging target used for fiber bars. Not a medical recommendation.
    let fiberTargetG: Double = 35

    init(services: AppServices) {
        self.services = services
        refresh()
    }

    var greetingName: String {
        if let name = profile?.firstName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }
        return DemoCatalog.greetingName
    }

    var macros: MacroTargets {
        profile?.targetMacros ?? MacroTargets(proteinG: 180, carbsG: 150, fatG: 80)
    }

    var calorieTarget: Double {
        Double(macros.proteinG * 4 + macros.carbsG * 4 + macros.fatG * 9)
    }

    var isShowingSampleDay: Bool { todayEntries.isEmpty }

    var displayedTotals: NutritionInfo {
        isShowingSampleDay ? sampleDayTotals : todayTotals
    }

    var sampleDayTotals: NutritionInfo {
        DemoCatalog.todayMeals.reduce(into: NutritionInfo()) { totals, meal in
            totals.calories += meal.nutrition.calories
            totals.proteinG += meal.nutrition.proteinG
            totals.carbsG += meal.nutrition.carbsG
            totals.fatG += meal.nutrition.fatG
            totals.fiberG += meal.nutrition.fiberG
            totals.sugarG += meal.nutrition.sugarG
            totals.cholesterolMg += meal.nutrition.cholesterolMg
            totals.sodiumMg += meal.nutrition.sodiumMg
        }
    }

    var sampleWeekProteinAvgG: Double {
        let days = DemoCatalog.weekMacros
        guard !days.isEmpty else { return 0 }
        return days.map(\.proteinG).reduce(0, +) / Double(days.count)
    }

    var weeklyZone2TargetMinutes: Int {
        profile?.weeklyZone2TargetMinutes ?? DemoCatalog.weeklyZone2TargetMinutes
    }

    var isShowingSampleZone2: Bool { sessions.isEmpty }

    var zone2MinutesThisWeek: Int {
        if isShowingSampleZone2 {
            return DemoCatalog.weeklyZone2CompletedMinutes
        }
        let calendar = Calendar.current
        guard let week = calendar.dateInterval(of: .weekOfYear, for: .now) else { return 0 }
        return sessions.reduce(0) { running, session in
            guard session.startedAt >= week.start, session.startedAt < week.end else { return running }
            return running + Int(session.zoneDurations.zone2Seconds / 60)
        }
    }

    var hasCheckIn: Bool {
        todayLog?.energyLevel != nil || todayLog?.constipationSeverity != nil
    }

    func refresh() {
        profile = services.training.getOrCreateProfile()
        todayEntries = services.food.getTodayEntries()
        todayTotals = services.food.getTodayNutritionTotals()
        todayLog = services.food.fetchTodayLog()
        sessions = services.training.recentSessions()
    }
}

struct DashboardView: View {
    let services: AppServices

    @State private var viewModel: DashboardViewModel
    @State private var showingTracker = false
    @State private var showingMealLog = false
    @State private var selectedLogMethod: FoodLogMethod?
    @State private var showingCheckIn = false
    @State private var selectedInsight: DemoCatalog.Insight?
    @State private var selectedEntry: FoodEntry?
    @State private var selectedDemoMeal: DemoCatalog.CatalogFood?

    init(services: AppServices) {
        self.services = services
        _viewModel = State(initialValue: DashboardViewModel(services: services))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                    header
                    quickActions
                    todaySummary
                    loggedMeals
                    zone2Card
                    coachInsight
                    checkInCard
                    HVDisclaimer()
                        .padding(.top, 8)
                }
                .padding(.horizontal, HVTheme.pagePadding)
                .padding(.bottom, 32)
            }
            .refreshable { viewModel.refresh() }
            .navigationTitle("")
            .hvInlineNav()
            .hvScreen()
            .toolbar { toolbarContent }
            .task { viewModel.refresh() }
            .fullScreenCover(isPresented: $showingTracker, onDismiss: viewModel.refresh) {
                LiveTrackerView(repository: services.training) {
                    showingTracker = false
                    viewModel.refresh()
                }
            }
            .sheet(isPresented: $showingMealLog, onDismiss: {
                selectedLogMethod = nil
                viewModel.refresh()
            }) {
                mealLogSheet
            }
            .sheet(isPresented: $showingCheckIn, onDismiss: viewModel.refresh) {
                DailyCheckInView(repository: services.food)
            }
            .sheet(item: $selectedInsight) { insight in
                DashboardInsightSheet(insight: insight)
            }
            .sheet(isPresented: Binding(
                get: { selectedEntry != nil },
                set: { if !$0 { selectedEntry = nil } }
            ), onDismiss: viewModel.refresh) {
                if let selectedEntry {
                    NavigationStack {
                        FoodEntryDetailView(repository: services.food, entry: selectedEntry)
                    }
                    .preferredColorScheme(.dark)
                }
            }
            .sheet(item: $selectedDemoMeal) { meal in
                DashboardDemoMealSheet(meal: meal)
            }
        }
        .preferredColorScheme(.dark)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                selectedInsight = DemoCatalog.insights.first
            } label: {
                Image(systemName: "sparkles")
            }
            .accessibilityLabel("Coach insight")
        }
        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink {
                ProfileHomeView(services: services)
            } label: {
                Image(systemName: "person.crop.circle")
            }
            .accessibilityLabel("Profile")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("HybridVital")
                .font(.title.bold())
                .foregroundStyle(.primary)
            Text("Welcome back, \(viewModel.greetingName)")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            Button {
                showingTracker = true
            } label: {
                HVQuickActionTile(
                    title: "Zone 2",
                    subtitle: "Live HR · jog / walk",
                    systemImage: "heart.fill",
                    tint: HVTheme.accent
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Start Zone 2")
            .accessibilityHint("Opens the live Zone 2 tracker")

            Button {
                selectedLogMethod = nil
                showingMealLog = true
            } label: {
                HVQuickActionTile(
                    title: "Log Meal",
                    subtitle: "Photo, search, or manual",
                    systemImage: "plus.circle.fill",
                    tint: HVTheme.calories
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Log meal")
            .accessibilityHint("Choose how to log food")
        }
    }

    private var todaySummary: some View {
        let totals = viewModel.displayedTotals
        return HVCard {
            VStack(alignment: .leading, spacing: 16) {
                HVSectionHeader(
                    title: "Today's Summary",
                    accessory: viewModel.isShowingSampleDay ? "Sample day" : nil
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(Int(totals.calories.rounded()))")
                        .font(HVFont.heroMetric())
                        .foregroundStyle(HVTheme.calories)
                        .monospacedDigit()
                    Text("kcal · \(Int(viewModel.calorieTarget.rounded())) target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HVProgressBar(
                        progress: progress(totals.calories, of: viewModel.calorieTarget),
                        tint: HVTheme.calories
                    )
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Calories \(Int(totals.calories.rounded())) of \(Int(viewModel.calorieTarget.rounded()))")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    HVMetricTile(
                        label: "Protein",
                        value: "\(Int(totals.proteinG.rounded()))g",
                        color: HVTheme.protein,
                        caption: "of \(viewModel.macros.proteinG)g"
                    )
                    HVMetricTile(
                        label: "Carbs",
                        value: "\(Int(totals.carbsG.rounded()))g",
                        color: HVTheme.carbs,
                        caption: "of \(viewModel.macros.carbsG)g"
                    )
                    HVMetricTile(
                        label: "Fat",
                        value: "\(Int(totals.fatG.rounded()))g",
                        color: HVTheme.fat,
                        caption: "of \(viewModel.macros.fatG)g"
                    )
                    HVMetricTile(
                        label: "Fiber",
                        value: "\(Int(totals.fiberG.rounded()))g",
                        color: HVTheme.fiber,
                        caption: "of \(Int(viewModel.fiberTargetG))g log target"
                    )
                }

                VStack(spacing: 10) {
                    MacroProgressRow(
                        label: "Protein",
                        value: totals.proteinG,
                        target: Double(viewModel.macros.proteinG),
                        tint: HVTheme.protein
                    )
                    MacroProgressRow(
                        label: "Carbs",
                        value: totals.carbsG,
                        target: Double(viewModel.macros.carbsG),
                        tint: HVTheme.carbs
                    )
                    MacroProgressRow(
                        label: "Fat",
                        value: totals.fatG,
                        target: Double(viewModel.macros.fatG),
                        tint: HVTheme.fat
                    )
                    MacroProgressRow(
                        label: "Fiber",
                        value: totals.fiberG,
                        target: viewModel.fiberTargetG,
                        tint: HVTheme.fiber
                    )
                }

                if viewModel.isShowingSampleDay {
                    Text("Week protein · sample \(Int(viewModel.sampleWeekProteinAvgG.rounded()))g/day avg")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    @ViewBuilder
    private var loggedMeals: some View {
        HVCard {
            VStack(alignment: .leading, spacing: 12) {
                HVSectionHeader(
                    title: "Logged meals",
                    accessory: viewModel.isShowingSampleDay ? "Sample day" : "\(viewModel.todayEntries.count)"
                )

                if viewModel.isShowingSampleDay {
                    ForEach(DemoCatalog.todayMeals) { meal in
                        Button {
                            selectedDemoMeal = meal
                        } label: {
                            MealRow(
                                name: meal.name,
                                mealType: meal.mealType.displayName,
                                calories: meal.nutrition.calories,
                                proteinG: meal.nutrition.proteinG
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(meal.mealType.displayName), \(meal.name)")
                    }
                    Text("Sample meals so the dashboard never looks empty. Log a real plate anytime.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(viewModel.todayEntries, id: \.id) { entry in
                        Button {
                            selectedEntry = entry
                        } label: {
                            MealRow(
                                name: entry.foodName,
                                mealType: entry.mealType.displayName,
                                calories: entry.nutrition.calories,
                                proteinG: entry.nutrition.proteinG
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(entry.mealType.displayName), \(entry.foodName)")
                    }
                }
            }
        }
    }

    private var zone2Card: some View {
        let completed = viewModel.zone2MinutesThisWeek
        let target = max(viewModel.weeklyZone2TargetMinutes, 1)
        return HVCard {
            VStack(alignment: .leading, spacing: 12) {
                HVSectionHeader(
                    title: "Zone 2 this week",
                    accessory: viewModel.isShowingSampleZone2 ? "Sample week" : nil
                )

                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text("\(completed)")
                        .font(HVFont.heroMetric(36))
                        .foregroundStyle(HVTheme.accent)
                        .monospacedDigit()
                    Text("of \(viewModel.weeklyZone2TargetMinutes) min")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Zone 2 \(completed) of \(viewModel.weeklyZone2TargetMinutes) minutes this week")

                HVProgressBar(
                    progress: Double(completed) / Double(target),
                    tint: HVTheme.accent
                )

                if completed >= viewModel.weeklyZone2TargetMinutes {
                    Text("Above your weekly minutes target — recover as you need. This is training volume, not a diagnosis.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(max(viewModel.weeklyZone2TargetMinutes - completed, 0)) min left toward this week’s personal target.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var coachInsight: some View {
        if let insight = DemoCatalog.insights.first {
            Button {
                selectedInsight = insight
            } label: {
                HVInsightBanner(
                    title: insight.title,
                    bodyText: insight.body,
                    systemImage: insight.systemImage,
                    tint: HVTheme.coach
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Coach insight, \(insight.title)")
            .accessibilityHint("Shows the full note")
        }
    }

    private var checkInCard: some View {
        HVCard {
            VStack(alignment: .leading, spacing: 14) {
                HVSectionHeader(title: "Daily check-in")

                if viewModel.hasCheckIn {
                    HStack(spacing: 10) {
                        HVMetricTile(
                            label: "Energy",
                            value: scoreText(viewModel.todayLog?.energyLevel),
                            color: HVTheme.accent,
                            caption: "1–10"
                        )
                        HVMetricTile(
                            label: "Constipation",
                            value: scoreText(viewModel.todayLog?.constipationSeverity),
                            color: HVTheme.warning,
                            caption: "severity 1–10"
                        )
                    }
                } else {
                    Text("A 20-second energy and digestion log helps Coach notice patterns. It is not a diagnosis.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HVPrimaryButton(
                    title: viewModel.hasCheckIn ? "Update check-in" : "Log check-in",
                    systemImage: "sun.max.fill"
                ) {
                    showingCheckIn = true
                }
            }
        }
    }

    @ViewBuilder
    private var mealLogSheet: some View {
        Group {
            if let selectedLogMethod {
                foodLogScreen(for: selectedLogMethod)
            } else {
                FoodLogMethodSheet { method in
                    selectedLogMethod = method
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents(selectedLogMethod == nil ? [.medium, .large] : [.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(HVTheme.background)
    }

    @ViewBuilder
    private func foodLogScreen(for method: FoodLogMethod) -> some View {
        switch method {
        case .camera, .library:
            PhotoCaptureStubView(repository: services.food, source: method)
        case .search:
            FoodSearchView(repository: services.food)
        case .voice:
            VoiceLogView(repository: services.food)
        case .manual:
            QuickFoodLogView(repository: services.food)
        }
    }

    private func progress(_ value: Double, of target: Double) -> Double {
        guard target > 0 else { return 0 }
        return value / target
    }

    private func scoreText(_ value: Int?) -> String {
        guard let value else { return "—" }
        return "\(value)/10"
    }
}

struct DashboardInsightSheet: View {
    let insight: DemoCatalog.Insight

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                    HVInsightBanner(
                        title: insight.title,
                        bodyText: insight.body,
                        systemImage: insight.systemImage,
                        tint: HVTheme.coach
                    )

                    Text(insight.kind)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(HVTheme.coach)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(HVTheme.coach.opacity(0.14))
                        .clipShape(Capsule())

                    Text(insight.body)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Patterns are observations from your logs, not medical conclusions.")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)

                    HVDisclaimer()
                }
                .padding(HVTheme.pagePadding)
            }
            .navigationTitle("Coach note")
            .hvInlineNav()
            .hvScreen()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct DashboardDemoMealSheet: View {
    let meal: DemoCatalog.CatalogFood

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(meal.mealType.displayName.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(meal.name)
                            .font(.title2.bold())
                        if let brand = meal.brand {
                            Text(brand)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Text("Sample meal · \(meal.source.displayName)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Text("\(Int(meal.nutrition.calories.rounded()))")
                        .font(HVFont.heroMetric())
                        .foregroundStyle(HVTheme.calories)
                    Text("kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        HVMetricTile(label: "Protein", value: "\(Int(meal.nutrition.proteinG.rounded()))g", color: HVTheme.protein)
                        HVMetricTile(label: "Carbs", value: "\(Int(meal.nutrition.carbsG.rounded()))g", color: HVTheme.carbs)
                        HVMetricTile(label: "Fat", value: "\(Int(meal.nutrition.fatG.rounded()))g", color: HVTheme.fat)
                        HVMetricTile(label: "Fiber", value: "\(Int(meal.nutrition.fiberG.rounded()))g", color: HVTheme.fiber)
                    }

                    if let notes = meal.notes {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HVDisclaimer()
                }
                .padding(HVTheme.pagePadding)
            }
            .navigationTitle("Meal")
            .hvInlineNav()
            .hvScreen()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct MealRow: View {
    let name: String
    let mealType: String
    let calories: Double
    let proteinG: Double

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Text(mealType)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(calories.rounded())) cal")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("\(Int(proteinG.rounded()))g protein")
                    .font(.caption)
                    .foregroundStyle(HVTheme.protein)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(HVTheme.tertiaryFill)
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous))
        .contentShape(Rectangle())
    }
}

private struct MacroProgressRow: View {
    let label: String
    let value: Double
    let target: Double
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value.rounded())) / \(Int(target.rounded()))g")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                    .monospacedDigit()
            }
            HVProgressBar(progress: target > 0 ? value / target : 0, tint: tint)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(Int(value.rounded())) of \(Int(target.rounded())) grams")
    }
}

#Preview {
    let container: ModelContainer
    do {
        container = try ModelContainer(
            for: UserProfile.self,
            DailyLog.self,
            FoodEntry.self,
            TrainingSession.self,
            WorkoutInterval.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    } catch {
        fatalError("Preview ModelContainer failed: \(error)")
    }
    let context = ModelContext(container)
    let services = AppServices(
        food: FoodLoggingRepository(context: context),
        training: TrainingRepository(context: context)
    )
    return DashboardView(services: services)
        .modelContainer(container)
}
