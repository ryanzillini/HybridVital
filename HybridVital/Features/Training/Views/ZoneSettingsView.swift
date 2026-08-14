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
                    Text("Zone 3 starts at \(settings.zone3Floor) bpm. Crossing that ceiling is your walk cue.")
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
            .navigationBarTitleDisplayMode(.inline)
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
