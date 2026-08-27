import SwiftUI

struct FoodLogHubView: View {
    let repository: FoodLoggingRepository

    @State private var entries: [FoodEntry] = []
    @State private var totals = NutritionInfo()
    @State private var photoMethod: FoodLogMethod?
    @State private var sheetMethod: FoodLogMethod?
    @State private var reviewFood: DemoCatalog.CatalogFood?
    @State private var selectedEntry: FoodEntry?

    init(repository: FoodLoggingRepository) {
        self.repository = repository
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                    hero
                    methodGrid
                    todayTotalsCard
                    todayMealsCard
                    historyLink
                    HVDisclaimer()
                }
                .padding(.horizontal, HVTheme.pagePadding)
                .padding(.vertical, 12)
            }
            .navigationTitle("Food")
            .hvInlineNav()
            .hvScreen()
            .fullScreenCover(item: $photoMethod, onDismiss: refresh) { method in
                PhotoCaptureStubView(repository: repository, source: method)
            }
            .sheet(item: $sheetMethod, onDismiss: refresh) { method in
                switch method {
                case .search:
                    FoodSearchView(repository: repository)
                case .voice:
                    VoiceLogView(repository: repository)
                case .manual:
                    QuickFoodLogView(repository: repository)
                case .camera, .library:
                    PhotoCaptureStubView(repository: repository, source: method)
                }
            }
            .sheet(item: $reviewFood, onDismiss: refresh) { food in
                FoodAnalysisReviewSheet(repository: repository, food: food, saveSource: food.source)
            }
            .sheet(isPresented: Binding(
                get: { selectedEntry != nil },
                set: { if !$0 { selectedEntry = nil } }
            ), onDismiss: refresh) {
                if let selectedEntry {
                    NavigationStack {
                        FoodEntryDetailView(repository: repository, entry: selectedEntry)
                    }
                }
            }
            .task { refresh() }
            .refreshable { refresh() }
        }
        .preferredColorScheme(.dark)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Log in under 15 seconds")
                .font(HVFont.heroMetric(32))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text("Photo-first, always editable. High protein, fiber-aware, conservative on cholesterol.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private var methodGrid: some View {
        VStack(spacing: 12) {
            Button {
                open(.camera)
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: FoodLogMethod.camera.systemImage)
                        .font(.system(size: 40))
                        .foregroundStyle(HVTheme.accent)
                        .symbolRenderingMode(.hierarchical)
                    Text(FoodLogMethod.camera.title)
                        .font(.title3.weight(.semibold))
                    Text(FoodLogMethod.camera.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 160)
                .padding(.vertical, 8)
                .background(HVTheme.cardElevated)
                .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusL, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Take photo")

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(FoodLogMethod.allCases.filter { $0 != .camera }) { method in
                    Button {
                        open(method)
                    } label: {
                        HVQuickActionTile(
                            title: method.title,
                            subtitle: method.subtitle,
                            systemImage: method.systemImage,
                            tint: tint(for: method)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(method.title)
                }
            }
        }
    }

    private var todayTotalsCard: some View {
        let shown = displayTotals
        let sample = entries.isEmpty
        return HVCard {
            VStack(alignment: .leading, spacing: 16) {
                HVSectionHeader(
                    title: "Today",
                    accessory: sample ? "Sample day" : "Live"
                )
                HStack(spacing: 16) {
                    ring(
                        label: "Cal",
                        value: shown.calories,
                        goal: FoodLoggingTargets.calories,
                        unit: "",
                        tint: HVTheme.calories
                    )
                    ring(
                        label: "Protein",
                        value: shown.proteinG,
                        goal: FoodLoggingTargets.proteinG,
                        unit: "g",
                        tint: HVTheme.protein
                    )
                    ring(
                        label: "Fiber",
                        value: shown.fiberG,
                        goal: FoodLoggingTargets.fiberG,
                        unit: "g",
                        tint: HVTheme.fiber
                    )
                }
                .frame(maxWidth: .infinity)

                macroBar(label: "Carbs", value: shown.carbsG, goal: FoodLoggingTargets.carbsG, tint: HVTheme.carbs)
                macroBar(label: "Fat", value: shown.fatG, goal: FoodLoggingTargets.fatG, tint: HVTheme.fat)

                Text("Targets are 180g protein and 35g fiber. Rings are a daily pace check, not a prescription.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var todayMealsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HVSectionHeader(
                title: "Today’s meals",
                accessory: entries.isEmpty ? "Sample meals" : "\(entries.count)"
            )

            if entries.isEmpty {
                ForEach(DemoCatalog.todayMeals) { food in
                    Button {
                        reviewFood = food
                    } label: {
                        FoodMealRow(
                            name: food.name,
                            subtitle: "\(food.mealType.displayName) · \(hvQuantityLabel(food.quantity)) \(food.unit)",
                            calories: food.nutrition.calories,
                            proteinG: food.nutrition.proteinG,
                            sourceName: food.source.displayName
                        )
                    }
                    .buttonStyle(.plain)
                }
            } else {
                ForEach(entries, id: \.id) { entry in
                    Button {
                        selectedEntry = entry
                    } label: {
                        FoodMealRow(
                            name: entry.foodName,
                            subtitle: "\(entry.mealType.displayName) · \(hvQuantityLabel(entry.quantity)) \(entry.unit)",
                            calories: entry.nutrition.calories,
                            proteinG: entry.nutrition.proteinG,
                            sourceName: entry.source.displayName
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var historyLink: some View {
        NavigationLink {
            DailyFoodHistoryView(repository: repository)
        } label: {
            HStack {
                Label("Food history", systemImage: "calendar")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(HVTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var displayTotals: NutritionInfo {
        if !entries.isEmpty {
            return totals
        }
        return NutritionInfo.sum(DemoCatalog.todayMeals.map(\.nutrition))
    }

    private func ring(label: String, value: Double, goal: Double, unit: String, tint: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                FoodMacroRing(progress: goal == 0 ? 0 : value / goal, tint: tint)
                VStack(spacing: 0) {
                    Text(hvQuantityLabel(value))
                        .font(.headline)
                    Text(unit.isEmpty ? "cal" : unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func macroBar(label: String, value: Double, goal: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(hvQuantityLabel(value)) / \(hvQuantityLabel(goal))g")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(tint)
            }
            HVProgressBar(progress: goal == 0 ? 0 : value / goal, tint: tint)
        }
    }

    private func tint(for method: FoodLogMethod) -> Color {
        switch method {
        case .camera: HVTheme.accent
        case .library: HVTheme.coach
        case .search: HVTheme.calories
        case .voice: HVTheme.carbs
        case .manual: .white
        }
    }

    private func open(_ method: FoodLogMethod) {
        switch method {
        case .camera, .library:
            photoMethod = method
        case .search, .voice, .manual:
            sheetMethod = method
        }
    }

    private func refresh() {
        entries = repository.getTodayEntries()
        totals = repository.getTodayNutritionTotals()
    }
}

#Preview("Hub") {
    FoodLogHubView(repository: FoodLoggingPreview.repository())
}
