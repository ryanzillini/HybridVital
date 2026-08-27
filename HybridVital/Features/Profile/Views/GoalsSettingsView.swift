import SwiftUI

struct GoalsSettingsView: View {
    let services: AppServices
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<GoalType>
    @State private var didSave = false

    init(services: AppServices) {
        self.services = services
        let profile = services.training.getOrCreateProfile()
        _selected = State(initialValue: Set(profile.primaryGoals))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                Text("Choose every aim that should shape food and training context. HybridVital stays conservative when cholesterol control is on.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                VStack(spacing: 10) {
                    ForEach(GoalType.allCases) { goal in
                        Button {
                            toggle(goal)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: goal.systemImage)
                                    .foregroundStyle(selected.contains(goal) ? HVTheme.accent : .secondary)
                                    .frame(width: 28)
                                Text(goal.displayName)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: selected.contains(goal) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selected.contains(goal) ? HVTheme.accent : .tertiary)
                                    .accessibilityHidden(true)
                            }
                            .padding(14)
                            .background(HVTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(goal.displayName)
                        .accessibilityValue(selected.contains(goal) ? "Selected" : "Not selected")
                        .accessibilityAddTraits(.isButton)
                    }
                }

                HVPrimaryButton(title: "Save goals", systemImage: "checkmark") {
                    save()
                    dismiss()
                }

                HVDisclaimer()
            }
            .padding(HVTheme.pagePadding)
        }
        .navigationTitle("Goals")
        .hvInlineNav()
        .hvScreen()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .onDisappear {
            if !didSave {
                save()
            }
        }
    }

    private func toggle(_ goal: GoalType) {
        if selected.contains(goal) {
            selected.remove(goal)
        } else {
            selected.insert(goal)
        }
    }

    private func save() {
        services.training.saveProfile { profile in
            profile.primaryGoals = GoalType.allCases.filter { selected.contains($0) }
        }
        didSave = true
    }
}
