import SwiftUI

struct DailyFoodHistoryView: View {
    let repository: FoodLoggingRepository

    @State private var selectedDay: Date
    @State private var logs: [DailyLog] = []

    init(repository: FoodLoggingRepository) {
        self.repository = repository
        _selectedDay = State(initialValue: Calendar.current.startOfDay(for: .now))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                dayPicker
                summaryCard
                mealsSection
                HVDisclaimer()
            }
            .padding(HVTheme.pagePadding)
        }
        .navigationTitle("Food history")
        .hvInlineNav()
        .hvScreen()
        .task { reload() }
        .onAppear { reload() }
        .refreshable { reload() }
    }

    private var days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<7).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }
    }

    private var logsByDay: [Date: DailyLog] {
        Dictionary(
            logs.map { log in
                (Calendar.current.startOfDay(for: log.date), log)
            },
            uniquingKeysWith: { first, second in
                first.updatedAt > second.updatedAt ? first : second
            }
        )
    }

    private var hasRealMeals: Bool {
        logs.contains { !$0.foodEntries.isEmpty }
    }

    private var selectedEntries: [FoodEntry] {
        let entries = logsByDay[selectedDay]?.foodEntries ?? []
        return entries.sorted { $0.timestamp > $1.timestamp }
    }

    private var usingDemo: Bool {
        !hasRealMeals
    }

    private var selectedMacroDay: DemoCatalog.MacroDay? {
        DemoCatalog.weekMacros.first {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDay)
        }
    }

    private var dayPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(days, id: \.self) { day in
                    Button {
                        selectedDay = day
                    } label: {
                        VStack(spacing: 6) {
                            Text(day, format: .dateTime.weekday(.narrow))
                                .font(.caption2)
                            Text(day, format: .dateTime.day())
                                .font(.headline)
                            Circle()
                                .fill(dotColor(for: day))
                                .frame(width: 6, height: 6)
                        }
                        .foregroundStyle(isSelected(day) ? .black : .primary)
                        .frame(width: 48)
                        .padding(.vertical, 10)
                        .background(isSelected(day) ? HVTheme.accent : HVTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(day.formatted(date: .complete, time: .omitted))
                }
            }
        }
    }

    private var summaryCard: some View {
        let calories = summaryCalories
        let protein = summaryProtein
        let fiber = summaryFiber
        return HVCard {
            VStack(alignment: .leading, spacing: 14) {
                HVSectionHeader(
                    title: selectedDay.formatted(.dateTime.month(.wide).day().weekday(.wide)),
                    accessory: usingDemo ? "Sample day" : nil
                )
                HStack(spacing: 10) {
                    HVMetricTile(
                        label: "Calories",
                        value: hvQuantityLabel(calories),
                        color: HVTheme.calories
                    )
                    HVMetricTile(
                        label: "Protein",
                        value: "\(hvQuantityLabel(protein))g",
                        color: HVTheme.protein,
                        caption: "of 180g"
                    )
                    HVMetricTile(
                        label: "Fiber",
                        value: "\(hvQuantityLabel(fiber))g",
                        color: HVTheme.fiber,
                        caption: "of 35g"
                    )
                }
                HVProgressBar(
                    progress: FoodLoggingTargets.proteinG == 0 ? 0 : protein / FoodLoggingTargets.proteinG,
                    tint: HVTheme.protein
                )
                if let demo = selectedMacroDay, usingDemo {
                    Text("Energy \(demo.energy)/10 · regularity \(demo.constipation)/10 (sample check-in).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HVSectionHeader(
                title: "Meals",
                accessory: usingDemo ? "Sample meals" : (selectedEntries.isEmpty ? nil : "\(selectedEntries.count)")
            )

            if !selectedEntries.isEmpty {
                ForEach(selectedEntries, id: \.id) { entry in
                    NavigationLink {
                        FoodEntryDetailView(repository: repository, entry: entry)
                    } label: {
                        FoodMealRow(
                            name: entry.foodName,
                            subtitle: "\(entry.mealType.displayName) · \(entry.timestamp.formatted(date: .omitted, time: .shortened))",
                            calories: entry.nutrition.calories,
                            proteinG: entry.nutrition.proteinG,
                            sourceName: entry.source.displayName
                        )
                    }
                    .buttonStyle(.plain)
                }
            } else if usingDemo {
                ForEach(DemoCatalog.todayMeals) { food in
                    NavigationLink {
                        DemoFoodDetailView(food: food, repository: repository)
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
                HVEmptyState(
                    title: "Nothing logged",
                    systemImage: "fork.knife",
                    description: "No meals on this day yet."
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var summaryCalories: Double {
        if !selectedEntries.isEmpty {
            return selectedEntries.reduce(0) { $0 + $1.nutrition.calories }
        }
        if usingDemo {
            return selectedMacroDay?.calories ?? 0
        }
        return 0
    }

    private var summaryProtein: Double {
        if !selectedEntries.isEmpty {
            return selectedEntries.reduce(0) { $0 + $1.nutrition.proteinG }
        }
        if usingDemo {
            return selectedMacroDay?.proteinG ?? 0
        }
        return 0
    }

    private var summaryFiber: Double {
        if !selectedEntries.isEmpty {
            return selectedEntries.reduce(0) { $0 + $1.nutrition.fiberG }
        }
        if usingDemo {
            return selectedMacroDay?.fiberG ?? 0
        }
        return 0
    }

    private func isSelected(_ day: Date) -> Bool {
        Calendar.current.isDate(day, inSameDayAs: selectedDay)
    }

    private func dotColor(for day: Date) -> Color {
        if let log = logsByDay[day], !log.foodEntries.isEmpty {
            return isSelected(day) ? .black.opacity(0.55) : HVTheme.accent
        }
        if usingDemo {
            return isSelected(day) ? .black.opacity(0.35) : Color.white.opacity(0.25)
        }
        return .clear
    }

    private func reload() {
        logs = repository.logs(inLastDays: 14)
    }
}
