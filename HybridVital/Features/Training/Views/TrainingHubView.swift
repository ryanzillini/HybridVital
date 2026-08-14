import SwiftData
import SwiftUI

struct TrainingHubView: View {
    let repository: TrainingRepository

    @State private var showingTracker = false
    @State private var showingZones = false
    @State private var sessions: [TrainingSession] = []
    @State private var selectedSession: TrainingSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
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
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    Button {
                        showingZones = true
                    } label: {
                        Label("Heart rate zones", systemImage: "slider.horizontal.3")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)

                    Text("Wear the COROS armband, start a session, and tap when you cross into Zone 3 or return to jogging.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    if sessions.isEmpty {
                        ContentUnavailableView(
                            "No sessions yet",
                            systemImage: "figure.run",
                            description: Text("Your jog/walk history will show up here.")
                        )
                        .padding(.top, 24)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent sessions")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(sessions, id: \.id) { session in
                                Button {
                                    selectedSession = session
                                } label: {
                                    sessionRow(session)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
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
                    SessionSummaryView(session: selectedSession)
                }
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
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func loadSessions() {
        sessions = repository.recentSessions()
    }
}
