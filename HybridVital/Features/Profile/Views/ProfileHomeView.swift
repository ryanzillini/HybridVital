import SwiftData
import SwiftUI

struct ProfileHomeView: View {
    let services: AppServices
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingZones = false
    @State private var profile: UserProfile

    init(services: AppServices) {
        self.services = services
        _profile = State(initialValue: services.training.getOrCreateProfile())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                header
                profileFacts
                settingsSection
                onboardingSection
                HVDisclaimer()
            }
            .padding(HVTheme.pagePadding)
        }
        .navigationTitle("Profile")
        .hvScreen()
        .onAppear { reloadProfile() }
        .sheet(isPresented: $showingZones, onDismiss: reloadProfile) {
            ZoneSettingsView(repository: services.training)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HVCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(profile.firstName ?? DemoCatalog.firstName)
                    .font(HVFont.heroMetric(36))
                Text("Goals")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(profile.primaryGoals) { goal in
                            Label(goal.displayName, systemImage: goal.systemImage)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(HVTheme.accent.opacity(0.16))
                                .foregroundStyle(HVTheme.accent)
                                .clipShape(Capsule())
                        }
                    }
                }
                .accessibilityLabel("Goals")
            }
        }
    }

    private var profileFacts: some View {
        VStack(alignment: .leading, spacing: 10) {
            HVSectionHeader(title: "At a glance")
            if profile.hasFamilialHypocholesterolemia {
                factRow(
                    title: "Familial hypocholesterolemia",
                    subtitle: "Cholesterol advice stays conservative",
                    systemImage: "drop.fill",
                    tint: HVTheme.warning
                )
            }
            ForEach(profile.commonIssues) { issue in
                factRow(
                    title: issue.displayName,
                    subtitle: "Tracked as a standing context",
                    systemImage: "cross.case.fill",
                    tint: HVTheme.coach
                )
            }
            factRow(
                title: profile.cookingSkillLevel.displayName,
                subtitle: "Cooking skill",
                systemImage: "frying.pan",
                tint: HVTheme.carbs
            )
            factRow(
                title: "\(profile.weeklyZone2TargetMinutes) min / week",
                subtitle: "Zone 2 target",
                systemImage: "heart.fill",
                tint: ZonePalette.color(2)
            )
        }
    }

    private var settingsSection: some View {
        VStack(spacing: 10) {
            HVSectionHeader(title: "Settings")
            NavigationLink {
                GoalsSettingsView(services: services)
                    .onDisappear(perform: reloadProfile)
            } label: {
                settingsRow("Goals", subtitle: "Primary training and nutrition aims", systemImage: "target", tint: HVTheme.accent)
            }
            .buttonStyle(.plain)

            NavigationLink {
                PreferencesSettingsView(services: services)
                    .onDisappear(perform: reloadProfile)
            } label: {
                settingsRow("Food preferences & allergies", subtitle: "Likes, dislikes, cooking skill", systemImage: "fork.knife", tint: HVTheme.protein)
            }
            .buttonStyle(.plain)

            NavigationLink {
                NotificationsSettingsView(services: services)
                    .onDisappear(perform: reloadProfile)
            } label: {
                settingsRow("Notifications", subtitle: "Reminders and nudges", systemImage: "bell.fill", tint: HVTheme.warning)
            }
            .buttonStyle(.plain)

            Button {
                showingZones = true
            } label: {
                settingsRow("Heart rate zones", subtitle: "Max HR and Zone 2 / Zone 3 bands", systemImage: "heart.fill", tint: ZonePalette.color(2))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Heart rate zones")

            NavigationLink {
                PrivacySettingsView()
            } label: {
                settingsRow("Privacy & data", subtitle: "Local-first, HealthKit, export", systemImage: "lock.fill", tint: .secondary)
            }
            .buttonStyle(.plain)

            NavigationLink {
                AboutView()
            } label: {
                settingsRow("About", subtitle: "HybridVital 0.2.0", systemImage: "info.circle.fill", tint: HVTheme.coach)
            }
            .buttonStyle(.plain)
        }
    }

    private func reloadProfile() {
        profile = services.training.getOrCreateProfile()
    }

    private var onboardingSection: some View {
        HVCard {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Onboarding completed", isOn: $hasCompletedOnboarding)
                    .tint(HVTheme.accent)
                Text("Turn this off to return to onboarding immediately.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func factRow(title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(HVTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous))
    }

    private func settingsRow(_ title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(12)
        .background(HVTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: UserProfile.self,
        DailyLog.self,
        FoodEntry.self,
        TrainingSession.self,
        WorkoutInterval.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    NavigationStack {
        ProfileHomeView(
            services: AppServices(
                food: FoodLoggingRepository(context: context),
                training: TrainingRepository(context: context)
            )
        )
    }
    .preferredColorScheme(.dark)
}
