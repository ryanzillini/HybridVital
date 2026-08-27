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
        PreferencesSettingsScreen(
            cookingSkill: $cookingSkill,
            allergies: $allergies,
            allergyDraft: $allergyDraft,
            dislikedFoods: $dislikedFoods,
            dislikeDraft: $dislikeDraft,
            preferences: $preferences,
            likeDraft: $likeDraft,
            onSave: saveAndDismiss,
            onAutoSave: saveIfNeeded
        )
    }

    private func saveAndDismiss() {
        save()
        dismiss()
    }

    private func saveIfNeeded() {
        if !didSave {
            save()
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

private struct PreferencesSettingsScreen: View {
    @Binding var cookingSkill: CookingSkillLevel
    @Binding var allergies: [String]
    @Binding var allergyDraft: String
    @Binding var dislikedFoods: [String]
    @Binding var dislikeDraft: String
    @Binding var preferences: [FoodPreference]
    @Binding var likeDraft: String
    let onSave: () -> Void
    let onAutoSave: () -> Void

    var body: some View {
        scroll
            .navigationTitle("Food preferences")
            .modifier(PreferencesChrome(onSave: onSave, onAutoSave: onAutoSave))
    }

    private var scroll: some View {
        ScrollView {
            form
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
            cookingAndTags
            likedAndSave
        }
        .padding(HVTheme.pagePadding)
    }

    private var cookingAndTags: some View {
        VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
            CookingSkillSection(cookingSkill: $cookingSkill)
            allergiesEditor
            dislikesEditor
        }
    }

    private var likedAndSave: some View {
        VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
            LikedFoodsEditor(preferences: $preferences, draft: $likeDraft)
            HVPrimaryButton(
                title: "Save preferences",
                systemImage: "checkmark",
                action: onSave
            )
            HVDisclaimer()
        }
    }

    private var allergiesEditor: TagListEditor {
        TagListEditor(
            title: "Allergies",
            subtitle: "Always excluded from suggestions",
            items: $allergies,
            draft: $allergyDraft,
            placeholder: "Add allergy",
            addLabel: "Add allergy"
        )
    }

    private var dislikesEditor: TagListEditor {
        TagListEditor(
            title: "Disliked foods",
            subtitle: "Skip unless you ask for them",
            items: $dislikedFoods,
            draft: $dislikeDraft,
            placeholder: "Add a dislike",
            addLabel: "Add disliked food"
        )
    }
}

private struct PreferencesChrome: ViewModifier {
    let onSave: () -> Void
    let onAutoSave: () -> Void

    func body(content: Content) -> some View {
        content
            .hvInlineNav()
            .hvScreen()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .fontWeight(.semibold)
                }
            }
            .onDisappear(perform: onAutoSave)
    }
}

private struct CookingSkillSection: View {
    @Binding var cookingSkill: CookingSkillLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HVSectionHeader(title: "Cooking skill")
            skillList
        }
    }

    private var skillList: some View {
        VStack(spacing: 8) {
            ForEach(CookingSkillLevel.allCases) { level in
                CookingSkillRow(
                    level: level,
                    isSelected: cookingSkill == level,
                    action: { cookingSkill = level }
                )
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
            rowLabel
        }
        .buttonStyle(.plain)
        .accessibilityLabel(level.displayName)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private var rowLabel: some View {
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
            tagList
        }
    }

    private var editorRow: some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: $draft)
                .textInputAutocapitalization(.words)
                .onSubmit(addItem)
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

    private var tagList: some View {
        ForEach(items, id: \.self) { name in
            TagRow(name: name, onRemove: { remove(name) })
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

    private func remove(_ name: String) {
        items.removeAll { $0 == name }
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
            emptyCaption
            likedList
        }
    }

    @ViewBuilder
    private var emptyCaption: some View {
        if preferences.isEmpty {
            Text("None yet — add yogurt, salmon, or whatever you actually eat.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
    }

    private var editorRow: some View {
        HStack(spacing: 8) {
            TextField("Add a liked food", text: $draft)
                .textInputAutocapitalization(.words)
                .onSubmit(addLike)
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

    private var likedList: some View {
        ForEach(preferences, id: \.name) { item in
            LikedFoodRow(
                item: item,
                onToggleLike: { toggleLike(item.name) },
                onRemove: { remove(item.name) }
            )
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

    private func remove(_ name: String) {
        preferences.removeAll { $0.name == name }
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
