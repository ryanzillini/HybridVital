import SwiftUI

@Observable
final class QuickFoodLogViewModel {
    var foodName: String = ""
    var brandName: String = ""
    var quantity: Double = 100
    var unit: String = "g"
    var mealType: MealType = .lunch
    var calories: Double = 0
    var proteinG: Double = 0
    var carbsG: Double = 0
    var fatG: Double = 0
    var fiberG: Double = 0
    var sugarG: Double = 0
    var cholesterolMg: Double = 0
    var sodiumMg: Double = 0
    var notes: String = ""
    var isLoading = false
    var errorMessage: String?

    private let repository: FoodLoggingRepository
    private var caloriesManuallyEdited = false

    init(repository: FoodLoggingRepository, food: DemoCatalog.CatalogFood? = nil) {
        self.repository = repository
        if let food {
            apply(food)
        }
    }

    var estimatedCalories: Double {
        (proteinG * 4) + (carbsG * 4) + (fatG * 9)
    }

    var displayedCalories: Double {
        caloriesManuallyEdited ? calories : estimatedCalories
    }

    func apply(_ food: DemoCatalog.CatalogFood) {
        foodName = food.name
        brandName = food.brand ?? ""
        quantity = food.quantity
        unit = food.unit
        mealType = food.mealType
        calories = food.nutrition.calories
        proteinG = food.nutrition.proteinG
        carbsG = food.nutrition.carbsG
        fatG = food.nutrition.fatG
        fiberG = food.nutrition.fiberG
        sugarG = food.nutrition.sugarG
        cholesterolMg = food.nutrition.cholesterolMg
        sodiumMg = food.nutrition.sodiumMg
        notes = food.notes ?? ""
        caloriesManuallyEdited = true
    }

    func setCalories(_ value: Double) {
        calories = value
        caloriesManuallyEdited = true
    }

    @MainActor
    func save() {
        guard !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Food name is required"
            return
        }

        guard proteinG >= 0, carbsG >= 0, fatG >= 0, fiberG >= 0, sugarG >= 0, cholesterolMg >= 0, sodiumMg >= 0 else {
            errorMessage = "Nutrition values must be zero or greater"
            return
        }

        isLoading = true
        defer { isLoading = false }

        let nutrition = NutritionInfo(
            calories: displayedCalories,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            fiberG: fiberG,
            sugarG: sugarG,
            cholesterolMg: cholesterolMg,
            sodiumMg: sodiumMg
        )

        let entry = FoodEntry(
            foodName: foodName.trimmingCharacters(in: .whitespacesAndNewlines),
            quantity: quantity,
            nutrition: nutrition
        )
        entry.mealType = mealType
        entry.unit = unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "g" : unit
        entry.brandName = brandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : brandName
        entry.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        entry.source = .manual

        repository.save(entry: entry)
        errorMessage = nil
    }
}

struct QuickFoodLogView: View {
    @State private var viewModel: QuickFoodLogViewModel
    @Environment(\.dismiss) private var dismiss

    init(repository: FoodLoggingRepository) {
        _viewModel = State(initialValue: QuickFoodLogViewModel(repository: repository))
    }

    init(repository: FoodLoggingRepository, food: DemoCatalog.CatalogFood) {
        _viewModel = State(initialValue: QuickFoodLogViewModel(repository: repository, food: food))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                    identityCard
                    amountCard
                    macrosCard
                    CholesterolAwarenessBanner(milligrams: viewModel.cholesterolMg)
                    notesCard
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(HVTheme.danger)
                    }
                    HVPrimaryButton(title: "Save meal", systemImage: "checkmark") {
                        viewModel.save()
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.foodName.trimmingCharacters(in: .whitespaces).isEmpty)
                    HVDisclaimer(
                        text: "Manual macros are what you typed — HybridVital does not treat them as lab values. Talk with your clinician before changing diet."
                    )
                }
                .padding(HVTheme.pagePadding)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Log Food")
            .hvInlineNav()
            .hvScreen()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.isLoading || viewModel.foodName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var identityCard: some View {
        @Bindable var viewModel = viewModel
        HVCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Meal")
                    .font(.headline)
                TextField("Food name", text: $viewModel.foodName)
                    .textInputAutocapitalization(.sentences)
                TextField("Brand (optional)", text: $viewModel.brandName)
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
    private var amountCard: some View {
        @Bindable var viewModel = viewModel
        HVCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Amount")
                    .font(.headline)
                HStack {
                    Text("Quantity")
                    Spacer()
                    TextField("Qty", value: $viewModel.quantity, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    TextField("Unit", text: $viewModel.unit)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 56)
                }
            }
        }
    }

    @ViewBuilder
    private var macrosCard: some View {
        @Bindable var viewModel = viewModel
        HVCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Nutrition")
                        .font(.headline)
                    Spacer()
                    Text("Est. \(hvQuantityLabel(viewModel.estimatedCalories)) cal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                FoodNutrientField(
                    label: "Calories",
                    unit: "cal",
                    tint: HVTheme.calories,
                    value: Binding(
                        get: { viewModel.displayedCalories },
                        set: { viewModel.setCalories($0) }
                    )
                )
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
}

#Preview {
    QuickFoodLogView(repository: FoodLoggingPreview.repository())
}
