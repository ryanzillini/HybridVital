import SwiftUI
import SwiftData

@Observable
class QuickFoodLogViewModel {
    var foodName: String = ""
    var quantity: Double = 100
    var mealType: MealType = .lunch
    var proteinG: Double = 0
    var carbsG: Double = 0
    var fatG: Double = 0
    var notes: String = ""
    
    var isLoading = false
    var errorMessage: String?
    
    private let repository: FoodLoggingRepository
    
    init(repository: FoodLoggingRepository) {
        self.repository = repository
    }
    
    var estimatedCalories: Double {
        (proteinG * 4) + (carbsG * 4) + (fatG * 9)
    }
    
    @MainActor
    func save() async {
        guard !foodName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Food name is required"
            return
        }
        
        guard proteinG >= 0, carbsG >= 0, fatG >= 0 else {
            errorMessage = "Nutrition values must be positive"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let nutrition = NutritionInfo(
            calories: estimatedCalories,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            fiberG: 0,
            sugarG: 0,
            cholesterolMg: 0,
            sodiumMg: 0
        )
        
        let entry = FoodEntry(
            foodName: foodName,
            quantity: quantity,
            nutrition: nutrition
        )
        entry.mealType = mealType
        entry.notes = notes.isEmpty ? nil : notes
        
        await repository.save(entry: entry)
        errorMessage = nil
    }
}

struct QuickFoodLogView: View {
    @State private var viewModel: QuickFoodLogViewModel
    @Environment(\.dismiss) var dismiss
    
    init(repository: FoodLoggingRepository) {
        _viewModel = State(initialValue: QuickFoodLogViewModel(repository: repository))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Meal Details") {
                    TextField("Food name", text: $viewModel.foodName)
                        .textContentType(.none)
                    
                    Picker("Meal Type", selection: $viewModel.mealType) {
                        ForEach(MealType.allCases, id: \.self) { meal in
                            Text(meal.displayName).tag(meal)
                        }
                    }
                    
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("g", value: $viewModel.quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                    }
                }
                
                Section("Nutrition (per serving)") {
                    HStack {
                        Text("Protein")
                        Spacer()
                        TextField("g", value: $viewModel.proteinG, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                    }
                    
                    HStack {
                        Text("Carbs")
                        Spacer()
                        TextField("g", value: $viewModel.carbsG, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                    }
                    
                    HStack {
                        Text("Fat")
                        Spacer()
                        TextField("g", value: $viewModel.fatG, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                    }
                    
                    HStack {
                        Text("Estimated Calories")
                        Spacer()
                        Text("\(Int(viewModel.estimatedCalories))")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 60)
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Log Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.save()
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.foodName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    let context = ModelContext(try! ModelContainer(for: FoodEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    let repo = FoodLoggingRepository(context: context)
    
    QuickFoodLogView(repository: repo)
}
