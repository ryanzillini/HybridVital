import SwiftData
import SwiftUI

struct ZoneSettingsView: View {
    let repository: TrainingRepository
    @Environment(\.dismiss) private var dismiss
    @State private var settings: HeartRateZoneSettings

    init(repository: TrainingRepository) {
        self.repository = repository
        _settings = State(initialValue: repository.getOrCreateProfile().heartRateZones)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: maxHRBinding, in: 120...220, step: 1) {
                        HStack {
                            Text("Max heart rate")
                            Spacer()
                            Text("\(settings.maxHR) bpm")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button("Recalculate zones from max HR") {
                        settings = settings.rebuilt(maxHR: settings.maxHR)
                    }
                } footer: {
                    Text("The min/max you save are what the run uses. Recalculate replaces those with % of max HR. Zone 3 min (\(settings.zone3Floor) bpm) is the walk cue.")
                }

                Section("Zones") {
                    ForEach($settings.zones) { $zone in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(zone.name)
                                .font(.headline)
                            HStack {
                                Text("Min")
                                TextField("bpm", value: $zone.minBPM, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                Text("Max")
                                TextField("bpm", value: $zone.maxBPM, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                            }
                            .font(.body)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Heart Rate Zones")
            .hvInlineNav()
            .hvScreen()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        repository.saveZoneSettings(settings)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(HVTheme.accent)
    }

    private var maxHRBinding: Binding<Int> {
        Binding(
            get: { settings.maxHR },
            set: { newValue in
                settings.maxHR = newValue
            }
        )
    }
}

#Preview {
    let container = try! ModelContainer(
        for: UserProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    ZoneSettingsView(repository: TrainingRepository(context: ModelContext(container)))
}
