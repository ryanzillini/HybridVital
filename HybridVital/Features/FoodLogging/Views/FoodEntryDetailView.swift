import SwiftUI

struct FoodEntryDetailView: View {
    let repository: FoodLoggingRepository
    let entry: FoodEntry

    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false
    @State private var showingQuickLog = false

    init(repository: FoodLoggingRepository, entry: FoodEntry) {
        self.repository = repository
        self.entry = entry
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                header
                FoodNutritionTiles(nutrition: entry.nutrition)
                CholesterolAwarenessBanner(milligrams: entry.nutrition.cholesterolMg)
                metaCard
                if let notes = entry.notes, !notes.isEmpty {
                    HVCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes")
                                .font(.headline)
                            Text(notes)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                HVPrimaryButton(title: "Log a correction", systemImage: "square.and.pencil") {
                    showingQuickLog = true
                }
                Button("Delete meal", role: .destructive) {
                    confirmDelete = true
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(HVTheme.danger.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
                HVDisclaimer()
            }
            .padding(HVTheme.pagePadding)
        }
        .navigationTitle(entry.foodName)
        .hvInlineNav()
        .hvScreen()
        .alert("Delete this meal?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                repository.delete(entry: entry)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes \(entry.foodName) from HybridVital. It does not change anything in Apple Health.")
        }
        .sheet(isPresented: $showingQuickLog) {
            QuickFoodLogView(repository: repository, food: catalogDraft)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.mealType.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(HVTheme.accent)
            Text(entry.foodName)
                .font(.title2.weight(.bold))
            Text(amountLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metaCard: some View {
        HVCard {
            VStack(alignment: .leading, spacing: 12) {
                metaRow("Source", entry.source.displayName)
                if let score = entry.confidenceScore {
                    metaRow("Confidence", "\(Int((score * 100).rounded()))%")
                }
                if let brand = entry.brandName, !brand.isEmpty {
                    metaRow("Brand", brand)
                }
                metaRow("Logged", entry.timestamp.formatted(date: .abbreviated, time: .shortened))
            }
        }
    }

    private var amountLine: String {
        "\(hvQuantityLabel(entry.quantity)) \(entry.unit)"
    }

    private var catalogDraft: DemoCatalog.CatalogFood {
        DemoCatalog.CatalogFood(
            name: entry.foodName,
            brand: entry.brandName,
            mealType: entry.mealType,
            source: entry.source,
            quantity: entry.quantity,
            unit: entry.unit,
            nutrition: entry.nutrition,
            confidence: entry.confidenceScore,
            notes: entry.notes
        )
    }

    private func metaRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

struct DemoFoodDetailView: View {
    let food: DemoCatalog.CatalogFood
    var repository: FoodLoggingRepository?

    @State private var didSave = false

    init(food: DemoCatalog.CatalogFood, repository: FoodLoggingRepository? = nil) {
        self.food = food
        self.repository = repository
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(food.mealType.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(HVTheme.accent)
                    Text(food.name)
                        .font(.title2.weight(.bold))
                    Text("\(hvQuantityLabel(food.quantity)) \(food.unit) · \(food.source.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Sample meal")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                FoodNutritionTiles(nutrition: food.nutrition)
                CholesterolAwarenessBanner(milligrams: food.nutrition.cholesterolMg)
                if let notes = food.notes, !notes.isEmpty {
                    HVCard {
                        Text(notes)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                if let repository {
                    if didSave {
                        Text("Saved to today")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(HVTheme.accent)
                    }
                    HVPrimaryButton(title: "Add to today", systemImage: "plus") {
                        repository.save(entry: food.makeFoodEntry())
                        didSave = true
                    }
                }
                HVDisclaimer()
            }
            .padding(HVTheme.pagePadding)
        }
        .navigationTitle("Meal")
        .hvInlineNav()
        .hvScreen()
    }
}
