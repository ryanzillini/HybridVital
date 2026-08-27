import SwiftData
import SwiftUI

struct CoachHomeView: View {
    let services: AppServices

    @State private var firstName = DemoCatalog.greetingName

    init(services: AppServices) {
        self.services = services
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                    header
                    contextStrip
                    briefingCard
                    insightsSection
                    askCoachLink
                    suggestedPrompts
                    memoryRow
                    HVDisclaimer()
                }
                .padding(.horizontal, HVTheme.pagePadding)
                .padding(.bottom, 28)
            }
            .navigationTitle("Coach")
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(HVTheme.background, for: .navigationBar)
            .hvScreen()
            .task {
                let profile = services.training.getOrCreateProfile()
                if let name = profile.firstName?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !name.isEmpty {
                    firstName = name
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(HVTheme.accent)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning, \(firstName)"
        case 12..<17: return "Good afternoon, \(firstName)"
        default: return "Good evening, \(firstName)"
        }
    }

    private var todayChips: [String] {
        DemoCatalog.conversation.first(where: { $0.role == .system })?.chips ?? []
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(.title2.bold())
                Text("Context is already loaded — protein, fiber, and Zone 2. No recap needed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundStyle(HVTheme.coach)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)
        }
        .padding(.top, 8)
    }

    private var contextStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HVSectionHeader(title: "Today", accessory: "Live context")
            CoachChipStrip(chips: todayChips)
        }
    }

    private var briefingCard: some View {
        NavigationLink {
            DailyBriefingView()
        } label: {
            HVCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Daily briefing", systemImage: "sun.horizon.fill")
                            .font(.headline)
                            .foregroundStyle(HVTheme.coach)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    Text(DemoCatalog.weeklyReportSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous)
                    .stroke(HVTheme.coach.opacity(0.22), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens this morning’s briefing")
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HVSectionHeader(title: "Insights", accessory: "From your logs")
            ForEach(DemoCatalog.insights) { insight in
                NavigationLink {
                    InsightDetailView(insight: insight, services: services)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(insight.kind.uppercased())
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(HVTheme.coach)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        HVInsightBanner(
                            title: insight.title,
                            bodyText: insight.body,
                            systemImage: insight.systemImage,
                            tint: HVTheme.coach
                        )
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var askCoachLink: some View {
        NavigationLink {
            CoachChatView(services: services)
        } label: {
            CoachPrimaryLinkLabel(title: "Ask Coach")
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens a chat with today’s context already loaded")
    }

    private var suggestedPrompts: some View {
        VStack(alignment: .leading, spacing: 12) {
            HVSectionHeader(title: "Suggested", accessory: "Pre-seeded")
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(DemoCatalog.suggestedPrompts, id: \.self) { prompt in
                    NavigationLink {
                        CoachChatView(services: services, initialPrompt: prompt)
                    } label: {
                        Text(prompt)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .padding(12)
                            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                            .background(HVTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous)
                                    .stroke(HVTheme.coach.opacity(0.32), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var memoryRow: some View {
        NavigationLink {
            CoachMemorySettingsView()
        } label: {
            CoachRowCard {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundStyle(HVTheme.coach)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Memory")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Automatic context · you can mute or forget")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserProfile.self,
        DailyLog.self,
        FoodEntry.self,
        TrainingSession.self,
        WorkoutInterval.self,
        configurations: configuration
    )
    let context = container.mainContext
    let profile = UserProfile()
    profile.firstName = DemoCatalog.firstName
    context.insert(profile)
    let services = AppServices(
        food: FoodLoggingRepository(context: context),
        training: TrainingRepository(context: context)
    )
    return CoachHomeView(services: services)
        .modelContainer(container)
}
