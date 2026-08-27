import SwiftUI

struct FoodSearchView: View {
    let repository: FoodLoggingRepository
    var onSaved: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var selectedFood: DemoCatalog.CatalogFood?
    @State private var addedNotice: String?

    init(repository: FoodLoggingRepository, onSaved: (() -> Void)? = nil) {
        self.repository = repository
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                    searchField
                    if let addedNotice {
                        Text(addedNotice)
                            .font(.footnote)
                            .foregroundStyle(HVTheme.accent)
                    }
                    if filtered.isEmpty {
                        HVEmptyState(
                            title: "No matches",
                            systemImage: "magnifyingglass",
                            description: "Try a shorter name, a brand, or log it manually."
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                    } else {
                        if !recents.isEmpty {
                            section(title: "Recents", foods: recents)
                        }
                        if !usda.isEmpty {
                            section(title: "USDA", foods: usda)
                        }
                        if !openFoodFacts.isEmpty {
                            section(title: "Open Food Facts", foods: openFoodFacts)
                        }
                    }
                    HVDisclaimer(
                        text: "USDA and Open Food Facts listings here are a local demo catalog. Confirm labels when you care about cholesterol, sodium, or fiber."
                    )
                }
                .padding(HVTheme.pagePadding)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Search foods")
            .hvInlineNav()
            .hvScreen()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(item: $selectedFood) { food in
                FoodAnalysisReviewSheet(
                    repository: repository,
                    food: food,
                    saveSource: food.source,
                    onSaved: {
                        selectedFood = nil
                        onSaved?()
                        dismiss()
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search USDA and Open Food Facts", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(14)
        .background(HVTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
    }

    private var filtered: [DemoCatalog.CatalogFood] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return DemoCatalog.searchResults }
        return DemoCatalog.searchResults.filter { food in
            food.name.localizedCaseInsensitiveContains(trimmed)
                || (food.brand?.localizedCaseInsensitiveContains(trimmed) ?? false)
        }
    }

    private var recents: [DemoCatalog.CatalogFood] {
        let staticRecents = Array(DemoCatalog.searchResults.prefix(3))
        let allowed = Set(filtered.map(\.id))
        return staticRecents.filter { allowed.contains($0.id) }
    }

    private var recentIDs: Set<UUID> {
        Set(recents.map(\.id))
    }

    private var usda: [DemoCatalog.CatalogFood] {
        filtered.filter { $0.source == .usda && !recentIDs.contains($0.id) }
    }

    private var openFoodFacts: [DemoCatalog.CatalogFood] {
        filtered.filter { $0.source == .openFoodFacts && !recentIDs.contains($0.id) }
    }

    private func section(title: String, foods: [DemoCatalog.CatalogFood]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HVSectionHeader(title: title, accessory: "\(foods.count)")
            ForEach(foods) { food in
                Button {
                    selectedFood = food
                } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        FoodMealRow(
                            name: food.name,
                            subtitle: brandLine(food),
                            calories: food.nutrition.calories,
                            proteinG: food.nutrition.proteinG,
                            sourceName: food.source.displayName
                        )
                    }
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Review & add") { selectedFood = food }
                    Button("Add now") { addDirectly(food) }
                }
            }
        }
    }

    private func brandLine(_ food: DemoCatalog.CatalogFood) -> String {
        var parts: [String] = [food.mealType.displayName]
        if let brand = food.brand, !brand.isEmpty {
            parts.append(brand)
        }
        parts.append("\(hvQuantityLabel(food.quantity)) \(food.unit)")
        return parts.joined(separator: " · ")
    }

    private func addDirectly(_ food: DemoCatalog.CatalogFood) {
        repository.save(entry: food.makeFoodEntry(source: food.source))
        addedNotice = "Added \(food.name)"
        onSaved?()
    }
}

#Preview("Search") {
    FoodSearchView(repository: FoodLoggingPreview.repository())
}
