import SwiftUI

struct GoalsSettingsView: View {
    let services: AppServices
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<GoalType>
    @State private var didSave = false

    init(services: AppServices) {
        self.services = services
        let profile = services.training.getOrCreateProfile()
        _selected = State(initialValue: Set(profile.primaryGoals.filter(\.isSelectable)))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                intro
                goalList
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

    private var intro: some View {
        Text("Choose every aim that should shape food and training context. HybridVital stays conservative when cholesterol control is on.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    private var goalList: some View {
        VStack(spacing: 10) {
            ForEach(GoalType.selectableCases) { goal in
                GoalPickerRow(
                    goal: goal,
                    isSelected: selected.contains(goal)
                ) {
                    toggle(goal)
                }
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
            profile.primaryGoals = GoalType.selectableCases.filter { selected.contains($0) }
        }
        didSave = true
    }
}

private struct GoalPickerRow: View {
    let goal: GoalType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: goal.systemImage)
                    .foregroundStyle(iconColor)
                    .frame(width: 28)
                Text(goal.displayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(checkColor)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .background(HVTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(goal.displayName)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(.isButton)
    }

    private var iconColor: Color {
        isSelected ? HVTheme.accent : Color.secondary
    }

    private var checkColor: Color {
        isSelected ? HVTheme.accent : Color.secondary
    }
}
