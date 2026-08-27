import SwiftData
import SwiftUI

@MainActor
@Observable
final class OnboardingFlowViewModel {
    let services: AppServices

    var page = 0
    var selectedGoals: Set<GoalType>
    var hasFamilialHypocholesterolemia: Bool
    var cookingSkill: CookingSkillLevel
    var commonIssues: Set<HealthIssue>
    var proteinG: Int
    var carbsG: Int
    var fatG: Int
    var weeklyZone2Minutes: Int

    let pageCount = 5

    init(services: AppServices) {
        self.services = services
        let profile = services.training.getOrCreateProfile()
        selectedGoals = Set(profile.primaryGoals)
        hasFamilialHypocholesterolemia = profile.hasFamilialHypocholesterolemia
        cookingSkill = profile.cookingSkillLevel
        commonIssues = Set(profile.commonIssues)
        proteinG = profile.targetMacros.proteinG
        carbsG = profile.targetMacros.carbsG
        fatG = profile.targetMacros.fatG
        weeklyZone2Minutes = profile.weeklyZone2TargetMinutes
    }

    var progress: Double {
        Double(page + 1) / Double(pageCount)
    }

    var isLastPage: Bool { page >= pageCount - 1 }

    var orderedGoals: [GoalType] {
        GoalType.allCases.filter { selectedGoals.contains($0) }
    }

    var orderedIssues: [HealthIssue] {
        HealthIssue.allCases.filter { commonIssues.contains($0) }
    }

    var calorieEstimate: Int {
        proteinG * 4 + carbsG * 4 + fatG * 9
    }

    func advance() {
        page = min(page + 1, pageCount - 1)
        persist()
    }

    func persist() {
        services.training.saveProfile { profile in
            profile.primaryGoals = GoalType.allCases.filter { selectedGoals.contains($0) }
            profile.hasFamilialHypocholesterolemia = hasFamilialHypocholesterolemia
            profile.cookingSkillLevel = cookingSkill
            profile.commonIssues = HealthIssue.allCases.filter { commonIssues.contains($0) }
            profile.targetMacros = MacroTargets(proteinG: proteinG, carbsG: carbsG, fatG: fatG)
            profile.weeklyZone2TargetMinutes = weeklyZone2Minutes
        }
    }

    func toggleGoal(_ goal: GoalType) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }

    func toggleIssue(_ issue: HealthIssue) {
        if commonIssues.contains(issue) {
            commonIssues.remove(issue)
        } else {
            commonIssues.insert(issue)
        }
    }
}

struct OnboardingFlowView: View {
    let services: AppServices
    var onFinished: () -> Void

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var viewModel: OnboardingFlowViewModel

    init(services: AppServices, onFinished: @escaping () -> Void) {
        self.services = services
        self.onFinished = onFinished
        _viewModel = State(initialValue: OnboardingFlowViewModel(services: services))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            VStack(spacing: 0) {
                HVProgressBar(progress: viewModel.progress, tint: HVTheme.accent)
                    .padding(.horizontal, HVTheme.pagePadding)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .accessibilityLabel("Onboarding step \(viewModel.page + 1) of \(viewModel.pageCount)")

                TabView(selection: $viewModel.page) {
                    welcomePage.tag(0)
                    goalsPage.tag(1)
                    healthPage.tag(2)
                    targetsPage.tag(3)
                    readyPage.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: viewModel.page)

                pageDots
                    .padding(.bottom, 12)

                HVPrimaryButton(
                    title: viewModel.isLastPage ? "Enter HybridVital" : "Continue",
                    systemImage: viewModel.isLastPage ? "arrow.right" : nil
                ) {
                    if viewModel.isLastPage {
                        finish()
                    } else {
                        withAnimation { viewModel.advance() }
                    }
                }
                .padding(.horizontal, HVTheme.pagePadding)
                .padding(.bottom, 20)
            }
            .background(HVTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .hvInlineNav()
            .hvScreen()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { finish() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(HVTheme.accent)
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == viewModel.page ? HVTheme.accent : Color.white.opacity(0.18))
                    .frame(width: index == viewModel.page ? 22 : 8, height: 8)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityHidden(true)
    }

    private var welcomePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(HVTheme.accent)
                    .symbolRenderingMode(.hierarchical)
                    .padding(.top, 12)

                VStack(alignment: .leading, spacing: 8) {
                    Text("HybridVital")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    Text("Train in Zone 2. Eat with context. A coach that already knows your day.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 14) {
                    OnboardingFeatureRow(
                        systemImage: "lock.fill",
                        title: "Local-first",
                        subtitle: "Logs live on this iPhone. You choose if anything leaves the device."
                    )
                    OnboardingFeatureRow(
                        systemImage: "heart.fill",
                        title: "Zone 2",
                        subtitle: "Live heart rate, jog/walk laps, and a weekly minutes target you set."
                    )
                    OnboardingFeatureRow(
                        systemImage: "sparkles",
                        title: "AI Coach",
                        subtitle: "Automatic context from meals, sessions, and the notes you choose to keep."
                    )
                    OnboardingFeatureRow(
                        systemImage: "fork.knife",
                        title: "Food logging",
                        subtitle: "Photo, search, voice, or a 15-second manual entry — always editable."
                    )
                }

                Text("HybridVital is a personal training and logging companion. It does not diagnose, treat, or replace your clinician.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, HVTheme.pagePadding)
            .padding(.bottom, 24)
        }
    }

    private var goalsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                pageTitle(
                    "What are you training toward?",
                    subtitle: "Select every goal that matters. These shape Coach context — they are not a diagnosis or a prescription."
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(GoalType.allCases) { goal in
                        OnboardingChip(
                            title: goal.displayName,
                            systemImage: goal.systemImage,
                            isSelected: viewModel.selectedGoals.contains(goal)
                        ) {
                            viewModel.toggleGoal(goal)
                        }
                    }
                }
            }
            .padding(.horizontal, HVTheme.pagePadding)
            .padding(.bottom, 24)
        }
    }

    private var healthPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                pageTitle(
                    "Health context",
                    subtitle: "Only log what a clinician has already told you. HybridVital will stay conservative and will not diagnose."
                )

                HVCard {
                    Toggle(isOn: Bindable(viewModel).hasFamilialHypocholesterolemia) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Familial hypocholesterolemia")
                                .font(.headline)
                            Text("On, only if your clinician has noted this. Used to keep cholesterol advice cautious.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(HVTheme.accent)
                }

                Text("Cooking skill")
                    .font(.headline)

                VStack(spacing: 10) {
                    ForEach(CookingSkillLevel.allCases) { level in
                        Button {
                            viewModel.cookingSkill = level
                        } label: {
                            HStack {
                                Text(level.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                if viewModel.cookingSkill == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(HVTheme.accent)
                                }
                            }
                            .padding(14)
                            .background(viewModel.cookingSkill == level ? HVTheme.accent.opacity(0.14) : HVTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous)
                                    .stroke(viewModel.cookingSkill == level ? HVTheme.accent : HVTheme.cardStroke, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(viewModel.cookingSkill == level ? .isSelected : [])
                    }
                }

                Text("Common issues to keep in mind")
                    .font(.headline)

                Text("These are reminders for Coach, not a symptom checker.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(HealthIssue.allCases) { issue in
                        OnboardingChip(
                            title: issue.displayName,
                            systemImage: issue.chipImage,
                            isSelected: viewModel.commonIssues.contains(issue)
                        ) {
                            viewModel.toggleIssue(issue)
                        }
                    }
                }
            }
            .padding(.horizontal, HVTheme.pagePadding)
            .padding(.bottom, 24)
        }
    }

    private var targetsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                pageTitle(
                    "Personal targets",
                    subtitle: "Numbers you want HybridVital to track. They are not medical prescriptions — change them anytime in Profile."
                )

                targetStepper(
                    title: "Protein",
                    value: Bindable(viewModel).proteinG,
                    range: 80...280,
                    step: 5,
                    unit: "g",
                    tint: HVTheme.protein
                )
                targetStepper(
                    title: "Carbs",
                    value: Bindable(viewModel).carbsG,
                    range: 60...320,
                    step: 5,
                    unit: "g",
                    tint: HVTheme.carbs
                )
                targetStepper(
                    title: "Fat",
                    value: Bindable(viewModel).fatG,
                    range: 30...150,
                    step: 5,
                    unit: "g",
                    tint: HVTheme.fat
                )

                Text("About \(viewModel.calorieEstimate) kcal from these macros")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                targetStepper(
                    title: "Weekly Zone 2",
                    value: Bindable(viewModel).weeklyZone2Minutes,
                    range: 30...360,
                    step: 15,
                    unit: "min",
                    tint: HVTheme.accent
                )
            }
            .padding(.horizontal, HVTheme.pagePadding)
            .padding(.bottom, 24)
        }
    }

    private var readyPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                pageTitle(
                    "You’re ready",
                    subtitle: "A quiet recap of what we’ll keep on this device. Edit anything later in Profile."
                )

                HVCard {
                    recapRow(title: "Goals", value: recapGoals)
                    Divider().overlay(HVTheme.cardStroke)
                    recapRow(title: "Cooking", value: viewModel.cookingSkill.displayName)
                    Divider().overlay(HVTheme.cardStroke)
                    recapRow(
                        title: "Macros",
                        value: "\(viewModel.proteinG)p / \(viewModel.carbsG)c / \(viewModel.fatG)f g"
                    )
                    Divider().overlay(HVTheme.cardStroke)
                    recapRow(title: "Zone 2", value: "\(viewModel.weeklyZone2Minutes) min / week")
                    if viewModel.hasFamilialHypocholesterolemia {
                        Divider().overlay(HVTheme.cardStroke)
                        recapRow(title: "Clinician note", value: "Familial hypocholesterolemia on file")
                    }
                }

                HVDisclaimer()
            }
            .padding(.horizontal, HVTheme.pagePadding)
            .padding(.bottom, 24)
        }
    }

    private var recapGoals: String {
        let names = viewModel.orderedGoals.map(\.displayName)
        return names.isEmpty ? "None selected" : names.joined(separator: ", ")
    }

    private func pageTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.largeTitle.bold())
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    private func recapRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }

    private func targetStepper(
        title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int,
        unit: String,
        tint: Color
    ) -> some View {
        HVCard {
            Stepper(value: value, in: range, step: step) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Text("\(value.wrappedValue) \(unit)")
                        .font(HVFont.heroMetric(28))
                        .foregroundStyle(tint)
                        .monospacedDigit()
                }
            }
            .tint(HVTheme.accent)
        }
    }

    private func finish() {
        viewModel.persist()
        hasCompletedOnboarding = true
        onFinished()
    }
}

private extension HealthIssue {
    var chipImage: String {
        switch self {
        case .constipation: "leaf.fill"
        case .lowEnergy: "battery.50percent"
        case .inflammation: "flame.fill"
        case .highCholesterol: "drop.fill"
        }
    }
}

private struct OnboardingFeatureRow: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(HVTheme.accent)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct OnboardingChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(isSelected ? HVTheme.accent : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(isSelected ? HVTheme.accent.opacity(0.16) : HVTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous)
                    .stroke(isSelected ? HVTheme.accent : HVTheme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
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
    let services = AppServices(
        food: FoodLoggingRepository(context: context),
        training: TrainingRepository(context: context)
    )
    return OnboardingFlowView(services: services, onFinished: {})
        .modelContainer(container)
}
