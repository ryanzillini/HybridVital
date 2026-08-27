import SwiftUI

struct PreferencesSettingsView: View {
    let services: AppServices
    @Environment(\.dismiss) private var dismiss
    @State private var allergies: [String]
    @State private var dislikedFoods: [String]
    @State private var preferences: [FoodPreference]
    @State private var cookingSkill: CookingSkillLevel
    @State private var allergyDraft = ""
    @State private var dislikeDraft = ""
    @State private var likeDraft = ""
    @State private var didSave = false

    init(services: AppServices) {
        self.services = services
        let profile = services.training.getOrCreateProfile()
        _allergies = State(initialValue: profile.allergies)
        _dislikedFoods = State(initialValue: profile.dislikedFoods)
        _preferences = State(initialValue: profile.foodPreferences)
        _cookingSkill = State(initialValue: profile.cookingSkillLevel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                CookingSkillSection(cookingSkill: $cookingSkill)
                TagListEditor(
                    title: "Allergies",
                    subtitle: "Always excluded from suggestions",
                    items: $allergies,
                    draft: $allergyDraft,
                    placeholder: "Add allergy",
                    addLabel: "Add allergy"
                )
                TagListEditor(
                    title: "Disliked foods",
                    subtitle: "Skip unless you ask for them",
                    items: $dislikedFoods,
                    draft: $dislikeDraft,
                    placeholder: "Add a dislike",
                    addLabel: "Add disliked food"
                )
                LikedFoodsEditor(preferences: $preferences, draft: $likeDraft)
                HVPrimaryButton(title: "Save preferences", systemImage: "checkmark") {
                    save()
                    dismiss()
                }
                HVDisclaimer()
            }
            .padding(HVTheme.pagePadding)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Food preferences")
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

    private func save() {
        services.training.saveProfile { profile in
            profile.allergies = allergies
            profile.dislikedFoods = dislikedFoods
            profile.foodPreferences = preferences
            profile.cookingSkillLevel = cookingSkill
        }
        didSave = true
    }
}

private struct CookingSkillSection: View {
    @Binding var cookingSkill: CookingSkillLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HVSectionHeader(title: "Cooking skill")
            VStack(spacing: 8) {
                ForEach(CookingSkillLevel.allCases) { level in
                    CookingSkillRow(
                        level: level,
                        isSelected: cookingSkill == level
                    ) {
                        cookingSkill = level
                    }
                }
            }
        }
    }
}

private struct CookingSkillRow: View {
    let level: CookingSkillLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(level.displayName)
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
        .accessibilityLabel(level.displayName)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private var checkColor: Color {
        isSelected ? HVTheme.accent : Color.secondary
    }
}

private struct TagListEditor: View {
    let title: String
    let subtitle: String
    @Binding var items: [String]
    @Binding var draft: String
    let placeholder: String
    let addLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HVSectionHeader(title: title)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
            editorRow
            ForEach(items, id: \.self) { name in
                TagRow(name: name) {
                    items.removeAll { $0 == name }
                }
            }
        }
    }

    private var editorRow: some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: $draft)
                .textInputAutocapitalization(.words)
                .onSubmit { addItem() }
                .padding(12)
                .background(HVTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous))
            Button(action: addItem) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(HVTheme.accent)
            }
            .accessibilityLabel(addLabel)
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func addItem() {
        let value = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        guard !items.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) else {
            draft = ""
            return
        }
        items.append(value)
        draft = ""
    }
}

private struct TagRow: View {
    let name: String
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Text(name)
                .font(.body.weight(.semibold))
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.tertiary)
            }
            .accessibilityLabel("Remove \(name)")
        }
        .padding(12)
        .background(HVTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous))
    }
}

private struct LikedFoodsEditor: View {
    @Binding var preferences: [FoodPreference]
    @Binding var draft: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HVSectionHeader(title: "Liked foods")
            Text("Named foods the coach should lean on.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            editorRow
            if preferences.isEmpty {
                Text("None yet — add yogurt, salmon, or whatever you actually eat.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            ForEach(preferences, id: \.name) { item in
                LikedFoodRow(
                    item: item,
                    onToggleLike: { toggleLike(item.name) },
                    onRemove: { preferences.removeAll { $0.name == item.name } }
                )
            }
        }
    }

    private var editorRow: some View {
        HStack(spacing: 8) {
            TextField("Add a liked food", text: $draft)
                .textInputAutocapitalization(.words)
                .onSubmit { addLike() }
                .padding(12)
                .background(HVTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous))
            Button(action: addLike) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(HVTheme.accent)
            }
            .accessibilityLabel("Add liked food")
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func addLike() {
        let value = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        guard !preferences.contains(where: { $0.name.caseInsensitiveCompare(value) == .orderedSame }) else {
            draft = ""
            return
        }
        preferences.append(FoodPreference(name: value, isLiked: true))
        draft = ""
    }

    private func toggleLike(_ name: String) {
        guard let index = preferences.firstIndex(where: { $0.name == name }) else { return }
        preferences[index].isLiked.toggle()
    }
}

private struct LikedFoodRow: View {
    let item: FoodPreference
    let onToggleLike: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggleLike) {
                Image(systemName: item.isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(heartColor)
            }
            .accessibilityLabel(item.isLiked ? "Mark \(item.name) as not liked" : "Mark \(item.name) as liked")

            Text(item.name)
                .font(.body.weight(.semibold))
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.tertiary)
            }
            .accessibilityLabel("Remove \(item.name)")
        }
        .padding(12)
        .background(HVTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous))
    }

    private var heartColor: Color {
        item.isLiked ? HVTheme.protein : Color.secondary
    }
}
