import SwiftUI

struct CoachMemorySettingsView: View {
    @State private var memories: [DemoCatalog.MemoryItem] = DemoCatalog.memories

    private let layerOrder = ["Permanent profile", "Rolling metrics", "Learned patterns"]

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Automatic memory", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundStyle(HVTheme.coach)
                    Text("Coach loads your profile, rolling metrics, and learned patterns so you don’t recap. Mute a layer if you don’t want it used. Forget removes a learned pattern from this device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
                .listRowBackground(HVTheme.card)
            }

            ForEach(visibleLayers, id: \.self) { layer in
                Section {
                    ForEach(memories.filter { $0.layer == layer }) { item in
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: enabledBinding(item.id)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text(item.detail)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tint(HVTheme.coach)
                            .opacity(item.isEnabled ? 1 : 0.55)

                            if item.layer == "Learned patterns" {
                                Button("Forget this pattern", role: .destructive) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        memories.removeAll { $0.id == item.id }
                                    }
                                }
                                .font(.footnote.weight(.semibold))
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(HVTheme.card)
                    }
                } header: {
                    Text(layer)
                } footer: {
                    Text(footerCopy(for: layer))
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Privacy")
                        .font(.subheadline.weight(.semibold))
                    Text("Memory is local-first on this device. A future cloud mirror would copy the same profile, metrics, and your overrides — nothing is uploaded today.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
                .listRowBackground(HVTheme.card)
            }

            Section {
                HVDisclaimer()
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Memory")
        .hvInlineNav()
        .hvScreen()
    }

    private var visibleLayers: [String] {
        layerOrder.filter { layer in
            memories.contains { $0.layer == layer }
        }
    }

    private func enabledBinding(_ id: UUID) -> Binding<Bool> {
        Binding(
            get: { memories.first(where: { $0.id == id })?.isEnabled ?? false },
            set: { newValue in
                guard let index = memories.firstIndex(where: { $0.id == id }) else { return }
                memories[index].isEnabled = newValue
            }
        )
    }

    private func footerCopy(for layer: String) -> String {
        switch layer {
        case "Permanent profile":
            return "Conditions, goals, and cooking skill. Muting stops Coach from using them; it does not delete your profile."
        case "Rolling metrics":
            return "Recomputed from the last 7–30 days of food, training, and check-ins."
        case "Learned patterns":
            return "Hypotheses from your logs. Forget removes them here. This is not a diagnosis."
        default:
            return ""
        }
    }
}
