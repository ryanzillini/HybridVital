import SwiftData
import SwiftUI

struct TrainingHubView: View {
    let repository: TrainingRepository

    @State private var showingTracker = false
    @State private var showingZones = false
    @State private var sessions: [TrainingSession] = []
    @State private var selectedSession: TrainingSession?
    @State private var sessionPendingDelete: TrainingSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                    startCard
                    weekCard
                    Button {
                        showingZones = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title3)
                                .foregroundStyle(HVTheme.accent)
                            Text("Heart rate zones")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .background(HVTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Heart rate zones")
                    Text("Wear the COROS armband, start a session, and tap when you cross into Zone 3 or return to jogging.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    sessionsSection
                    HVDisclaimer()
                }
                .padding(.horizontal, HVTheme.pagePadding)
                .padding(.bottom, 32)
            }
            .navigationTitle("Training")
            .hvScreen()
            .fullScreenCover(isPresented: $showingTracker, onDismiss: loadSessions) {
                LiveTrackerView(repository: repository) {
                    showingTracker = false
                    loadSessions()
                }
            }
            .sheet(isPresented: $showingZones) {
                ZoneSettingsView(repository: repository)
            }
            .sheet(isPresented: Binding(
                get: { selectedSession != nil },
                set: { if !$0 { selectedSession = nil } }
            )) {
                if let selectedSession {
                    SessionSummaryView(
                        session: selectedSession,
                        onDelete: { delete(selectedSession) }
                    )
                }
            }
            .alert(
                "Delete this session?",
                isPresented: Binding(
                    get: { sessionPendingDelete != nil },
                    set: { if !$0 { sessionPendingDelete = nil } }
                )
            ) {
                Button("Delete", role: .destructive) {
                    if let sessionPendingDelete {
                        delete(sessionPendingDelete)
                    }
                }
                Button("Cancel", role: .cancel) {
                    sessionPendingDelete = nil
                }
            } message: {
                Text(deleteConfirmationMessage(for: sessionPendingDelete))
            }
            .task { loadSessions() }
        }
        .preferredColorScheme(.dark)
    }

    private var startCard: some View {
        Button {
            showingTracker = true
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(HVTheme.accent)
                    .symbolRenderingMode(.hierarchical)
                Text("Start Zone 2")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Text("Live HR · jog / walk laps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 180)
            .background(HVTheme.cardElevated)
            .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusL, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: HVTheme.radiusL, style: .continuous)
                    .stroke(HVTheme.accent.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start Zone 2")
        .accessibilityHint("Opens the live Zone 2 tracker")
    }

    private var weekCard: some View {
        let completed = weekMinutes
        let target = max(repository.getOrCreateProfile().weeklyZone2TargetMinutes, 1)
        let isSample = sessions.isEmpty
        return HVCard {
            VStack(alignment: .leading, spacing: 12) {
                HVSectionHeader(
                    title: "This week",
                    accessory: isSample ? "Sample week" : nil
                )
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text("\(completed)")
                        .font(HVFont.heroMetric(36))
                        .foregroundStyle(HVTheme.accent)
                        .monospacedDigit()
                    Text("of \(target) min")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HVProgressBar(progress: Double(completed) / Double(target), tint: HVTheme.accent)
                Text("Volume toward your personal Zone 2 target — not a prescription to push harder.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var weekMinutes: Int {
        if sessions.isEmpty {
            return DemoCatalog.weeklyZone2CompletedMinutes
        }
        let calendar = Calendar.current
        guard let week = calendar.dateInterval(of: .weekOfYear, for: .now) else { return 0 }
        return sessions.reduce(0) { running, session in
            guard session.startedAt >= week.start, session.startedAt < week.end else { return running }
            return running + Int(session.zoneDurations.zone2Seconds / 60)
        }
    }

    @ViewBuilder
    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HVSectionHeader(
                title: "Recent sessions",
                accessory: sessions.isEmpty ? nil : "\(sessions.count)"
            )

            if sessions.isEmpty {
                HVCard {
                    HVEmptyState(
                        title: "No sessions yet",
                        systemImage: "figure.run",
                        description: "Your jog/walk history will show up here after you finish a Zone 2 run."
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            } else {
                ForEach(sessions, id: \.id) { session in
                    Button {
                        selectedSession = session
                    } label: {
                        sessionRow(session)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(.isButton)
                    .contextMenu {
                        Button("Delete Session", role: .destructive) {
                            sessionPendingDelete = session
                        }
                    }
                }
            }
        }
    }

    private func sessionRow(_ session: TrainingSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.body.bold())
                    .foregroundStyle(.primary)
                Text("\(DurationFormat.clock(session.durationSeconds)) · \(session.intervalCount) laps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if let avg = session.avgHR {
                    Text("\(Int(avg.rounded())) avg")
                        .font(.body.bold())
                        .foregroundStyle(.primary)
                }
                Text("\(Int((session.zoneDurations.zone2Percent * 100).rounded()))% Z2")
                    .font(.caption)
                    .foregroundStyle(HVTheme.accent)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(HVTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
        .accessibilityLabel("Session \(session.startedAt.formatted(date: .abbreviated, time: .shortened))")
    }

    private func delete(_ session: TrainingSession) {
        repository.delete(session: session)
        if selectedSession?.id == session.id {
            selectedSession = nil
        }
        sessionPendingDelete = nil
        loadSessions()
    }

    private func deleteConfirmationMessage(for session: TrainingSession?) -> String {
        let when = session?.startedAt.formatted(date: .abbreviated, time: .shortened) ?? "this session"
        return "This removes \(when) from HybridVital. The workout in Apple Health is left as-is."
    }

    private func loadSessions() {
        sessions = repository.recentSessions()
    }
}
