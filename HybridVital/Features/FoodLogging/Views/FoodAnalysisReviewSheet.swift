import SwiftUI

@Observable
final class FoodAnalysisReviewViewModel {
    var foodName: String
    var brandName: String
    var mealType: MealType
    var quantity: Double
    var unit: String
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var fiberG: Double
    var sugarG: Double
    var cholesterolMg: Double
    var sodiumMg: Double
    var notes: String
    var errorMessage: String?
    var isSaving = false

    let confidence: Double?
    let catalogSource: LogSource

    init(food: DemoCatalog.CatalogFood) {
        foodName = food.name
        brandName = food.brand ?? ""
        mealType = food.mealType
        quantity = food.quantity
        unit = food.unit
        calories = food.nutrition.calories
        proteinG = food.nutrition.proteinG
        carbsG = food.nutrition.carbsG
        fatG = food.nutrition.fatG
        fiberG = food.nutrition.fiberG
        sugarG = food.nutrition.sugarG
        cholesterolMg = food.nutrition.cholesterolMg
        sodiumMg = food.nutrition.sodiumMg
        notes = food.notes ?? ""
        confidence = food.confidence
        catalogSource = food.source
    }

    var confidencePercent: Int? {
        guard let confidence else { return nil }
        return Int((confidence * 100).rounded())
    }

    var nutrition: NutritionInfo {
        NutritionInfo(
            calories: calories,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            fiberG: fiberG,
            sugarG: sugarG,
            cholesterolMg: cholesterolMg,
            sodiumMg: sodiumMg
        )
    }

    func makeEntry(source: LogSource) -> FoodEntry? {
        let name = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            errorMessage = "Give this item a name before saving."
            return nil
        }
        let entry = FoodEntry(foodName: name, quantity: quantity, nutrition: nutrition)
        entry.brandName = brandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : brandName
        entry.mealType = mealType
        entry.unit = unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "g" : unit
        entry.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        entry.source = source
        entry.confidenceScore = confidence
        errorMessage = nil
        return entry
    }
}

struct FoodAnalysisReviewSheet: View {
    let repository: FoodLoggingRepository
    var saveSource: LogSource
    var onSaved: (() -> Void)?

    @State private var viewModel: FoodAnalysisReviewViewModel
    @State private var showingSearch = false
    @Environment(\.dismiss) private var dismiss

    init(
        repository: FoodLoggingRepository,
        food: DemoCatalog.CatalogFood,
        saveSource: LogSource = .grokVision,
        onSaved: (() -> Void)? = nil
    ) {
        self.repository = repository
        self.saveSource = saveSource
        self.onSaved = onSaved
        _viewModel = State(initialValue: FoodAnalysisReviewViewModel(food: food))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                    confidenceHeader
                    identityCard
                    quantityCard
                    macrosCard
                    CholesterolAwarenessBanner(milligrams: viewModel.cholesterolMg)
                    notesCard
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(HVTheme.danger)
                    }
                    HVPrimaryButton(title: "Save meal", systemImage: "checkmark") {
                        save()
                    }
                    Button("Looks off — search instead") {
                        showingSearch = true
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    HVDisclaimer(
                        text: "Vision parses are a starting point. Confirm amounts before you treat them as logged. HybridVital is not medical advice."
                    )
                }
                .padding(HVTheme.pagePadding)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Review")
            .hvInlineNav()
            .hvScreen()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingSearch) {
                FoodSearchView(repository: repository, onSaved: {
                    showingSearch = false
                    onSaved?()
                    dismiss()
                })
            }
        }
        .preferredColorScheme(.dark)
    }

    private var confidenceHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(HVTheme.coach)
            VStack(alignment: .leading, spacing: 4) {
                Text("Check this parse")
                    .font(.headline)
                Text("Confidence is a hint, not a guarantee. Edit anything that looks wrong.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(viewModel.catalogSource.displayName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 8)
            if let percent = viewModel.confidencePercent {
                Text("\(percent)%")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(confidenceFill(percent))
                    .clipShape(Capsule())
                    .accessibilityLabel("Confidence \(percent) percent")
            }
        }
        .padding(16)
        .background(HVTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
    }

    @ViewBuilder
    private var identityCard: some View {
        @Bindable var viewModel = viewModel
        HVCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Item")
                    .font(.headline)
                TextField("Food name", text: $viewModel.foodName)
                    .textInputAutocapitalization(.sentences)
                TextField("Brand (optional)", text: $viewModel.brandName)
                    .textInputAutocapitalization(.words)
                Picker("Meal type", selection: $viewModel.mealType) {
                    ForEach(MealType.allCases) { meal in
                        Text(meal.displayName).tag(meal)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    @ViewBuilder
    private var quantityCard: some View {
        @Bindable var viewModel = viewModel
        HVCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Amount")
                    .font(.headline)
                HStack {
                    TextField("Quantity", value: $viewModel.quantity, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Unit", text: $viewModel.unit)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
        }
    }

    @ViewBuilder
    private var macrosCard: some View {
        @Bindable var viewModel = viewModel
        HVCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Nutrition")
                    .font(.headline)
                FoodNutrientField(label: "Calories", unit: "cal", tint: HVTheme.calories, value: $viewModel.calories)
                FoodNutrientField(label: "Protein", unit: "g", tint: HVTheme.protein, value: $viewModel.proteinG)
                FoodNutrientField(label: "Carbs", unit: "g", tint: HVTheme.carbs, value: $viewModel.carbsG)
                FoodNutrientField(label: "Fat", unit: "g", tint: HVTheme.fat, value: $viewModel.fatG)
                FoodNutrientField(label: "Fiber", unit: "g", tint: HVTheme.fiber, value: $viewModel.fiberG)
                FoodNutrientField(label: "Sugar", unit: "g", value: $viewModel.sugarG)
                FoodNutrientField(label: "Cholesterol", unit: "mg", tint: HVTheme.warning, value: $viewModel.cholesterolMg)
                FoodNutrientField(label: "Sodium", unit: "mg", value: $viewModel.sodiumMg)
            }
        }
    }

    @ViewBuilder
    private var notesCard: some View {
        @Bindable var viewModel = viewModel
        HVCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.headline)
                TextField("Optional notes", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
    }

    private func confidenceFill(_ percent: Int) -> Color {
        if percent >= 85 { return HVTheme.accent }
        if percent >= 70 { return HVTheme.warning }
        return HVTheme.danger
    }

    private func save() {
        guard !viewModel.isSaving else { return }
        viewModel.isSaving = true
        defer { viewModel.isSaving = false }
        guard let entry = viewModel.makeEntry(source: saveSource) else { return }
        repository.save(entry: entry)
        onSaved?()
        dismiss()
    }
}
