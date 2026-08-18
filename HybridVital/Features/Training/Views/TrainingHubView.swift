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
            List {
                Section {
                    Button {
                        showingTracker = true
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.green)
                            Text("Start Zone 2")
                                .font(.title2.bold())
                            Text("Live HR · jog / walk laps")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    )
                    .listRowSeparator(.hidden)

                    Button {
                        showingZones = true
                    } label: {
                        Label("Heart rate zones", systemImage: "slider.horizontal.3")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    Text("Wear the COROS armband, start a session, and tap when you cross into Zone 3 or return to jogging.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section {
                    if sessions.isEmpty {
                        ContentUnavailableView(
                            "No sessions yet",
                            systemImage: "figure.run",
                            description: Text("Your jog/walk history will show up here.")
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(sessions, id: \.id) { session in
                            sessionRow(session)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedSession = session }
                                .accessibilityAddTraits(.isButton)
                                .listRowBackground(Color(.secondarySystemBackground))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete", role: .destructive) {
                                        sessionPendingDelete = session
                                    }
                                }
                                .contextMenu {
                                    Button("Delete Session", role: .destructive) {
                                        sessionPendingDelete = session
                                    }
                                }
                        }
                    }
                } header: {
                    if !sessions.isEmpty {
                        Text("Recent sessions")
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Training")
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
    }

    private func sessionRow(_ session: TrainingSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.body.bold())
                Text("\(DurationFormat.clock(session.durationSeconds)) · \(session.intervalCount) laps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if let avg = session.avgHR {
                    Text("\(Int(avg.rounded())) avg")
                        .font(.body.bold())
                }
                Text("\(Int((session.zoneDurations.zone2Percent * 100).rounded()))% Z2")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 6)
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
