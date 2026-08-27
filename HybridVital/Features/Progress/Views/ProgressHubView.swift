import SwiftData
import SwiftUI

@Observable
@MainActor
final class ProgressHubViewModel {
    var range: ProgressTimeRange = .week
    var snapshot: ProgressSnapshot

    private let services: AppServices

    init(services: AppServices) {
        self.services = services
        self.snapshot = ProgressSnapshot.load(services: services, range: .week)
    }

    func refresh() {
        snapshot = ProgressSnapshot.load(services: services, range: range)
    }
}

struct ProgressHubView: View {
    let services: AppServices
    @State private var model: ProgressHubViewModel

    init(services: AppServices) {
        self.services = services
        _model = State(initialValue: ProgressHubViewModel(services: services))
    }

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                    rangePicker(selection: $model.range)
                    zone2Hero
                    macroAdherence
                    energyDigestion
                    insight
                    destinations
                    recentSessions
                    HVDisclaimer()
                }
                .padding(HVTheme.pagePadding)
            }
            .navigationTitle("Progress")
            .hvScreen()
            .onAppear { model.refresh() }
            .onChange(of: model.range) { _, _ in
                model.refresh()
            }
        }
        .preferredColorScheme(.dark)
    }

    private func rangePicker(selection: Binding<ProgressTimeRange>) -> some View {
        Picker("Range", selection: selection) {
            ForEach(ProgressTimeRange.allCases) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Progress range")
    }

    private var zone2Hero: some View {
        let snapshot = model.snapshot
        return HVCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Zone 2")
                        .font(.headline)
                    Spacer()
                    if snapshot.trainingIsSample {
                        HVSampleCaption()
                    }
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(snapshot.zone2CompletedMinutes)")
                        .font(HVFont.heroMetric(44))
                        .foregroundStyle(ZonePalette.color(2))
                    Text("/ \(snapshot.zone2TargetMinutes) min")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                HVProgressBar(
                    progress: snapshot.zone2Progress,
                    tint: ZonePalette.color(2)
                )
                Text(zone2Caption(snapshot))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var macroAdherence: some View {
        let snapshot = model.snapshot
        return VStack(alignment: .leading, spacing: 10) {
            HVSectionHeader(
                title: "Macro adherence",
                accessory: model.range.title
            )
            if snapshot.macrosAreSample {
                HVSampleCaption()
            }
            HStack(spacing: 10) {
                adherenceTile(
                    label: "Protein",
                    value: "\(Int(snapshot.averageProtein.rounded()))g",
                    caption: "of \(snapshot.proteinTarget)g",
                    progress: snapshot.proteinAdherence,
                    color: HVTheme.protein
                )
                adherenceTile(
                    label: "Fiber",
                    value: "\(Int(snapshot.averageFiber.rounded()))g",
                    caption: "of \(snapshot.fiberTarget)g",
                    progress: snapshot.fiberAdherence,
                    color: HVTheme.fiber
                )
                adherenceTile(
                    label: "Calories",
                    value: "\(Int(snapshot.averageCalories.rounded()))",
                    caption: "of \(snapshot.calorieTarget)",
                    progress: snapshot.calorieAdherence,
                    color: HVTheme.calories
                )
            }
            Text(todayCaption(snapshot))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var energyDigestion: some View {
        let snapshot = model.snapshot
        return VStack(alignment: .leading, spacing: 10) {
            HVSectionHeader(title: "Energy & digestion")
            if snapshot.macrosAreSample {
                HVSampleCaption()
            }
            HStack(spacing: 10) {
                HVMetricTile(
                    label: "Energy",
                    value: String(format: "%.1f", snapshot.averageEnergy),
                    color: HVTheme.accent,
                    caption: "avg / 10"
                )
                HVMetricTile(
                    label: "Constipation",
                    value: String(format: "%.1f", snapshot.averageConstipation),
                    color: snapshot.averageConstipation > 2 ? HVTheme.warning : .primary,
                    caption: snapshot.averageConstipation > 2 ? "Watch fiber" : "Mostly low"
                )
            }
        }
    }

    private var insight: some View {
        let item = DemoCatalog.insights.first
        return Group {
            if let item {
                HVInsightBanner(
                    title: item.title,
                    bodyText: item.body,
                    systemImage: item.systemImage,
                    tint: HVTheme.coach
                )
            }
        }
    }

    private var destinations: some View {
        VStack(spacing: 10) {
            HVSectionHeader(title: "Trends")
            NavigationLink {
                MacroTrendsView(services: services, range: model.range)
            } label: {
                progressRow(
                    title: "Macro trends",
                    subtitle: "Protein, fiber, calories",
                    systemImage: "chart.xyaxis.line",
                    tint: HVTheme.protein
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                TrainingTrendsView(services: services, range: model.range)
            } label: {
                progressRow(
                    title: "Training trends",
                    subtitle: "Zone 2 minutes by day",
                    systemImage: "heart.fill",
                    tint: ZonePalette.color(2)
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                EnergyTrendsView(services: services, range: model.range)
            } label: {
                progressRow(
                    title: "Energy & recovery",
                    subtitle: "Energy and digestion together",
                    systemImage: "bolt.heart.fill",
                    tint: HVTheme.warning
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                WeeklyReportView(services: services)
            } label: {
                progressRow(
                    title: "Weekly report",
                    subtitle: "Narrative + share",
                    systemImage: "doc.text.fill",
                    tint: HVTheme.coach
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var recentSessions: some View {
        let sessions = model.snapshot.sessions
        if !sessions.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HVSectionHeader(title: "Recent sessions")
                ForEach(sessions.prefix(5), id: \.id) { session in
                    sessionRow(session)
                }
            }
        }
    }

    private func sessionRow(_ session: TrainingSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.body.weight(.semibold))
                Text("\(DurationFormat.clock(session.durationSeconds)) · \(session.intervalCount) laps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if let avg = session.avgHR {
                    Text("\(Int(avg.rounded())) avg")
                        .font(.body.weight(.semibold))
                }
                Text("\(Int((session.zoneDurations.zone2Percent * 100).rounded()))% Z2")
                    .font(.caption)
                    .foregroundStyle(ZonePalette.color(2))
            }
        }
        .padding(12)
        .background(HVTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
    }

    private func adherenceTile(
        label: String,
        value: String,
        caption: String,
        progress: Double,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            HVProgressBar(progress: progress, tint: color)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(HVTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous))
    }

    private func progressRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color
    ) -> some View {
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

    private func zone2Caption(_ snapshot: ProgressSnapshot) -> String {
        let delta = snapshot.zone2CompletedMinutes - snapshot.zone2TargetMinutes
        if delta >= 0 {
            return "\(delta) min over the weekly target. Consistency over intensity."
        }
        return "\(abs(delta)) min under the weekly target. Easy volume still counts."
    }

    private func todayCaption(_ snapshot: ProgressSnapshot) -> String {
        let totals = snapshot.todayTotals
        let sample = snapshot.todayIsSample ? " · Sample data" : ""
        return "Today \(Int(totals.proteinG.rounded()))g protein · \(Int(totals.fiberG.rounded()))g fiber · \(Int(totals.calories.rounded())) kcal\(sample)"
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
    ProgressHubView(
        services: AppServices(
            food: FoodLoggingRepository(context: context),
            training: TrainingRepository(context: context)
        )
    )
}
