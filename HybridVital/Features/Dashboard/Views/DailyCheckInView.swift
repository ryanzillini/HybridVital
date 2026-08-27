import SwiftData
import SwiftUI

struct DailyCheckInView: View {
    let repository: FoodLoggingRepository

    @Environment(\.dismiss) private var dismiss
    @State private var energy: Int
    @State private var constipationSeverity: Int
    @State private var notes: String

    init(repository: FoodLoggingRepository) {
        self.repository = repository
        let log = repository.fetchTodayLog()
        _energy = State(initialValue: Self.clamped(log?.energyLevel, fallback: 6))
        _constipationSeverity = State(initialValue: Self.clamped(log?.constipationSeverity, fallback: 2))
        _notes = State(initialValue: log?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    CheckInScaleRow(
                        title: "Energy",
                        value: $energy,
                        tint: HVTheme.accent,
                        lowCaption: "Drained",
                        highCaption: "Strong"
                    )
                } footer: {
                    Text("How you feel today, 1–10. This is a personal log, not a medical score.")
                }

                Section {
                    CheckInScaleRow(
                        title: "Constipation severity",
                        value: $constipationSeverity,
                        tint: HVTheme.warning,
                        lowCaption: "None",
                        highCaption: "More severe"
                    )
                } footer: {
                    Text("1 is none, 10 is more severe. HybridVital does not diagnose digestive conditions.")
                }

                Section("Notes") {
                    TextField("Optional — meals, sleep, training, or how you felt", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("Daily check-in")
            .hvInlineNav()
            .hvScreen()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(HVTheme.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(HVTheme.accent)
    }

    private func save() {
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        repository.saveDailyCheckIn(
            energy: Self.clamped(energy, fallback: 6),
            constipation: Self.clamped(constipationSeverity, fallback: 2),
            notes: trimmed.isEmpty ? nil : trimmed
        )
        dismiss()
    }

    private static func clamped(_ value: Int?, fallback: Int) -> Int {
        guard let value else { return fallback }
        return min(10, max(1, value))
    }
}

private struct CheckInScaleRow: View {
    let title: String
    @Binding var value: Int
    var tint: Color
    var lowCaption: String
    var highCaption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(value)")
                    .font(HVFont.heroMetric(34))
                    .foregroundStyle(tint)
                    .monospacedDigit()
                    .accessibilityHidden(true)
            }

            HStack(spacing: 5) {
                ForEach(1...10, id: \.self) { step in
                    Button {
                        value = step
                    } label: {
                        Capsule()
                            .fill(step <= value ? tint : HVTheme.tertiaryFill)
                            .frame(height: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(title) \(step) of 10")
                    .accessibilityAddTraits(step == value ? .isSelected : [])
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue("\(value) out of 10")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    value = min(10, value + 1)
                case .decrement:
                    value = max(1, value - 1)
                default:
                    break
                }
            }

            HStack {
                Text("1 · \(lowCaption)")
                Spacer()
                Text("10 · \(highCaption)")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .listRowBackground(HVTheme.card)
        .padding(.vertical, 6)
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
    return DailyCheckInView(repository: FoodLoggingRepository(context: context))
        .modelContainer(container)
}
