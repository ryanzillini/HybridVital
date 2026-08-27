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
                cookingSection
                tagEditor(
                    title: "Allergies",
                    subtitle: "Always excluded from suggestions",
                    items: $allergies,
                    draft: $allergyDraft,
                    placeholder: "Add allergy",
                    addLabel: "Add allergy"
                )
                tagEditor(
                    title: "Disliked foods",
                    subtitle: "Skip unless you ask for them",
                    items: $dislikedFoods,
                    draft: $dislikeDraft,
                    placeholder: "Add a dislike",
                    addLabel: "Add disliked food"
                )
                likedFoods
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

    private var cookingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HVSectionHeader(title: "Cooking skill")
            VStack(spacing: 8) {
                ForEach(CookingSkillLevel.allCases) { level in
                    Button {
                        cookingSkill = level
                    } label: {
                        HStack {
                            Text(level.displayName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: cookingSkill == level ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(cookingSkill == level ? HVTheme.accent : .tertiary)
                                .accessibilityHidden(true)
                        }
                        .padding(14)
                        .background(HVTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(level.displayName)
                    .accessibilityValue(cookingSkill == level ? "Selected" : "Not selected")
                }
            }
        }
    }

    private var likedFoods: some View {
        VStack(alignment: .leading, spacing: 10) {
            HVSectionHeader(title: "Liked foods")
            Text("Named foods the coach should lean on.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField("Add a liked food", text: $likeDraft)
                    .textInputAutocapitalization(.words)
                    .onSubmit { addLike() }
                    .padding(12)
                    .background(HVTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous))
                Button {
                    addLike()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(HVTheme.accent)
                }
                .accessibilityLabel("Add liked food")
                .disabled(likeDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if preferences.isEmpty {
                Text("None yet — add yogurt, salmon, or whatever you actually eat.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }

            ForEach(preferences, id: \.name) { item in
                HStack(spacing: 12) {
                    Button {
                        if let index = preferences.firstIndex(where: { $0.name == item.name }) {
                            preferences[index].isLiked.toggle()
                        }
                    } label: {
                        Image(systemName: item.isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(item.isLiked ? HVTheme.protein : .secondary)
                    }
                    .accessibilityLabel(item.isLiked ? "Mark \(item.name) as not liked" : "Mark \(item.name) as liked")

                    Text(item.name)
                        .font(.body.weight(.semibold))
                    Spacer()
                    Button {
                        preferences.removeAll { $0.name == item.name }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .accessibilityLabel("Remove \(item.name)")
                }
                .padding(12)
                .background(HVTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous))
            }
        }
    }

    private func tagEditor(
        title: String,
        subtitle: String,
        items: Binding<[String]>,
        draft: Binding<String>,
        placeholder: String,
        addLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HVSectionHeader(title: title)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                TextField(placeholder, text: draft)
                    .textInputAutocapitalization(.words)
                    .onSubmit {
                        addUnique(draft.wrappedValue, to: items, clearing: draft)
                    }
                    .padding(12)
                    .background(HVTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous))
                Button {
                    addUnique(draft.wrappedValue, to: items, clearing: draft)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(HVTheme.accent)
                }
                .accessibilityLabel(addLabel)
                .disabled(draft.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            ForEach(items.wrappedValue, id: \.self) { name in
                HStack {
                    Text(name)
                        .font(.body.weight(.semibold))
                    Spacer()
                    Button {
                        items.wrappedValue.removeAll { $0 == name }
                    } label: {
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
    }

    private func addUnique(_ raw: String, to items: Binding<[String]>, clearing draft: Binding<String>) {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        guard !items.wrappedValue.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) else {
            draft.wrappedValue = ""
            return
        }
        items.wrappedValue.append(value)
        draft.wrappedValue = ""
    }

    private func addLike() {
        let value = likeDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        guard !preferences.contains(where: { $0.name.caseInsensitiveCompare(value) == .orderedSame }) else {
            likeDraft = ""
            return
        }
        preferences.append(FoodPreference(name: value, isLiked: true))
        likeDraft = ""
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
