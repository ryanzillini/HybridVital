import Charts
import SwiftData
import SwiftUI

struct SessionSummaryView: View {
    let session: TrainingSession
    var onDone: (() -> Void)?
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false
    @State private var showingExportFormats = false
    @State private var shareItems: [URL] = []
    @State private var showingShare = false
    @State private var exportError: String?

    init(session: TrainingSession, onDelete: (() -> Void)? = nil, onDone: (() -> Void)? = nil) {
        self.session = session
        self.onDelete = onDelete
        self.onDone = onDone
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    headlineStats
                    zoneBreakdown
                    if let fatigueNote = session.fatigueNote {
                        Text(fatigueNote)
                            .font(.callout)
                            .foregroundStyle(.orange)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    rollups
                    hrChart
                    intervalList
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Zone 2 Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: close) {
                        Image(systemName: "chevron.down")
                    }
                    .accessibilityLabel("Close")
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Export", systemImage: "square.and.arrow.up") {
                            showingExportFormats = true
                        }
                        if onDelete != nil {
                            Divider()
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                confirmDelete = true
                            }
                        }
                    } label: {
                        Label("Session actions", systemImage: "ellipsis.circle")
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .confirmationDialog(
                "Export this session",
                isPresented: $showingExportFormats,
                titleVisibility: .visible
            ) {
                Button("JSON") { export(.json) }
                Button("CSV") { export(.csv) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("JSON is the full session. CSV is heart rate and laps for a spreadsheet.")
            }
            .sheet(isPresented: $showingShare) {
                ShareSheet(items: shareItems) {
                    showingShare = false
                }
            }
            .alert("Delete this session?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) {
                    onDelete?()
                    close()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes \(session.startedAt.formatted(date: .abbreviated, time: .shortened)) from HybridVital. The workout in Apple Health is left as-is.")
            }
            .alert(
                "Couldn’t export",
                isPresented: Binding(
                    get: { exportError != nil },
                    set: { if !$0 { exportError = nil } }
                )
            ) {
                Button("OK", role: .cancel) { exportError = nil }
            } message: {
                Text(exportError ?? "")
            }
        }
        .preferredColorScheme(.dark)
    }

    private func close() {
        if let onDone {
            onDone()
        } else {
            dismiss()
        }
    }

    private func export(_ format: SessionExportFormat) {
        do {
            shareItems = try SessionExport.shareItems(for: session, format: format)
            showingShare = true
        } catch {
            exportError = error.localizedDescription
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(DurationFormat.clock(session.durationSeconds))
                .font(.system(size: 44, weight: .bold, design: .rounded))
        }
    }

    private var headlineStats: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            stat("Avg HR", value: bpm(session.avgHR))
            stat("Max HR", value: bpm(session.maxHR))
            stat("Min HR", value: bpm(session.minHR))
            stat("In Z2", value: percent(session.zoneDurations.zone2Percent))
            stat("At/above Z3", value: DurationFormat.minutesSeconds(session.zoneDurations.atOrAboveZone3Seconds))
            stat("Intervals", value: "\(session.intervalCount)")
        }
    }

    private var zoneBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Time in zone")
                .font(.headline)
            ForEach(1...5, id: \.self) { zone in
                let seconds = session.zoneDurations.seconds(for: zone)
                let total = max(session.zoneDurations.totalSeconds, 1)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Z\(zone)")
                            .font(.caption.bold())
                            .foregroundStyle(ZonePalette.color(zone))
                        Spacer()
                        Text(DurationFormat.minutesSeconds(seconds))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    GeometryReader { proxy in
                        Capsule()
                            .fill(ZonePalette.color(zone).opacity(0.25))
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(ZonePalette.color(zone))
                                    .frame(width: proxy.size.width * seconds / total)
                            }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var rollups: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Jog / walk")
                .font(.headline)
            HStack {
                stat("Avg jog", value: optionalDuration(session.avgJogSeconds))
                stat("Longest jog", value: optionalDuration(session.longestJogSeconds))
            }
            HStack {
                stat("Avg walk", value: optionalDuration(session.avgWalkSeconds))
                stat("Fastest recovery", value: optionalDuration(session.fastestRecoverySeconds))
            }
        }
    }

    @ViewBuilder
    private var hrChart: some View {
        if session.downsampledHR.count > 1 {
            VStack(alignment: .leading, spacing: 8) {
                Text("Heart rate")
                    .font(.headline)
                Chart(session.downsampledHR, id: \.timestamp) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("BPM", point.bpm)
                    )
                    .foregroundStyle(ZonePalette.color(2))
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 180)
            }
            .padding()
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var intervalList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Laps")
                .font(.headline)
            ForEach(session.sortedIntervals, id: \.id) { interval in
                HStack {
                    Image(systemName: interval.kind.systemImage)
                        .foregroundStyle(interval.kind == .jog ? Color.green : Color.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(interval.kind.displayName)
                            .font(.body.bold())
                        Text(DurationFormat.clock(interval.durationSeconds))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        if let maxHR = interval.maxHR {
                            Text("max \(Int(maxHR.rounded()))")
                                .font(.caption.bold())
                        }
                        if interval.kind == .walk, let recovery = interval.timeToReenterZone2Seconds {
                            Text("Z2 in \(DurationFormat.minutesSeconds(recovery))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func stat(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func bpm(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int(value.rounded()))"
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func optionalDuration(_ value: Double?) -> String {
        guard let value else { return "—" }
        return DurationFormat.minutesSeconds(value)
    }
}
