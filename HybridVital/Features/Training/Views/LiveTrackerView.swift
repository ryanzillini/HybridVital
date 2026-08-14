import SwiftUI

struct LiveTrackerView: View {
    let repository: TrainingRepository
    var onFinished: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: LiveTrackerViewModel
    @State private var showingZones = false
    @State private var confirmEnd = false

    init(repository: TrainingRepository, onFinished: (() -> Void)? = nil) {
        self.repository = repository
        self.onFinished = onFinished
        _viewModel = State(initialValue: LiveTrackerViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background.ignoresSafeArea()

                if let session = viewModel.savedSession {
                    SessionSummaryView(session: session) {
                        onFinished?()
                        dismiss()
                    }
                } else if viewModel.isSessionLive {
                    activeSession
                } else {
                    setup
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.savedSession == nil {
                    ToolbarItem(placement: .cancellationAction) {
                        if viewModel.isSessionLive {
                            Button("End") { confirmEnd = true }
                        } else {
                            Button("Close") { dismiss() }
                        }
                    }
                    if viewModel.phase == .active || viewModel.phase == .paused {
                        ToolbarItem(placement: .primaryAction) {
                            Button(viewModel.phase == .paused ? "Resume" : "Pause") {
                                viewModel.pauseOrResume()
                            }
                        }
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(viewModel.isSessionLive)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .sheet(isPresented: $showingZones, onDismiss: viewModel.reloadZones) {
            ZoneSettingsView(repository: repository)
        }
        .alert("End session?", isPresented: $confirmEnd) {
            Button("End", role: .destructive) {
                Task { await viewModel.endSession() }
            }
            Button("Keep going", role: .cancel) {}
        }
        .alert(
            "Heart rate not found",
            isPresented: $viewModel.showingHelp
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(corosHelpText)
        }
    }

    private var background: Color {
        if viewModel.flashZ3 { return Color.orange.opacity(0.35) }
        if let zone = viewModel.currentZone {
            return ZonePalette.color(zone.number).opacity(0.12)
        }
        return Color.black
    }

    private var setup: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                    .padding(.top, 24)
                Text("Zone 2")
                    .font(.largeTitle.bold())

                connectionCard

                VStack(alignment: .leading, spacing: 8) {
                    Label("Z2 ceiling \(viewModel.zoneSettings.zone3Floor) bpm", systemImage: "chart.bar.fill")
                    Label("Outdoor run · HealthKit workout", systemImage: "figure.run")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    showingZones = true
                } label: {
                    Label("Heart rate zones", systemImage: "slider.horizontal.3")
                }

                Button {
                    Task { await viewModel.start() }
                } label: {
                    Text(startButtonTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(viewModel.hasReceivedHeartRate ? Color.green : Color.green.opacity(0.35))
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .disabled(!canStart)

                if !viewModel.hasReceivedHeartRate, !isCountingDown, viewModel.phase != .preparing {
                    Button("Start without heart rate") {
                        Task { await viewModel.start() }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                Text(corosHelpText)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
            }
        }
    }

    private var connectionCard: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(viewModel.hasReceivedHeartRate ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
                Text(viewModel.sensorStatus.text)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                Spacer()
            }

            if let bpm = viewModel.currentHeartRate {
                Text("\(Int(bpm.rounded()))")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                Text("bpm · band connected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
                    .tint(.white)
            }

            if viewModel.sensorDevices.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Heart rate devices")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    ForEach(viewModel.sensorDevices) { device in
                        Button {
                            viewModel.connectToMonitor(id: device.id)
                        } label: {
                            HStack {
                                Text(device.name)
                                Spacer()
                                Text("\(device.rssi) dBm")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
    }

    private var canStart: Bool {
        viewModel.hasReceivedHeartRate && viewModel.phase != .preparing && !isCountingDown
    }

    private var activeSession: some View {
        VStack(spacing: 16) {
            if isCountingDown, case .countdown(let remaining) = viewModel.phase {
                Spacer()
                Text("Connecting to COROS…")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("\(remaining)")
                    .font(.system(size: 88, weight: .bold, design: .rounded))
                Spacer()
            } else {
                HStack {
                    Text(DurationFormat.clock(viewModel.elapsed))
                        .font(.title2.monospacedDigit())
                    Spacer()
                    Text(viewModel.phase == .paused ? "Paused" : viewModel.currentKind.displayName)
                        .font(.headline)
                        .foregroundStyle(viewModel.currentKind == .jog ? .green : .orange)
                }
                .padding(.horizontal)

                Spacer()

                Text(bpmText)
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundStyle(zoneColor)
                    .contentTransition(.numericText())

                Text(viewModel.currentZone?.name ?? "Waiting for HR")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(zoneColor)

                if let zone = viewModel.currentZone {
                    Text("\(zone.minBPM)–\(zone.maxBPM) bpm")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !viewModel.hasReceivedHeartRate {
                    Text("Waiting for COROS band…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 24) {
                    metric("Z2 time", DurationFormat.clock(viewModel.timeInZone2))
                    metric("Interval", DurationFormat.clock(viewModel.currentIntervalElapsed))
                    metric("kcal", "\(Int(viewModel.activeCalories.rounded()))")
                }
                .padding(.top, 8)

                Spacer()

                if viewModel.canUndo {
                    Button("Undo last lap") {
                        viewModel.undoLastLap()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Button {
                    viewModel.toggleLap()
                } label: {
                    Text(viewModel.lapButtonTitle)
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 88)
                        .background(viewModel.currentKind == .jog ? Color.orange : Color.green)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .disabled(viewModel.phase != .active && viewModel.phase != .paused)
            }
        }
        .padding(.top, 8)
    }

    private var isCountingDown: Bool {
        if case .countdown = viewModel.phase { return true }
        return viewModel.phase == .preparing
    }

    private var startButtonTitle: String {
        if case .countdown(let remaining) = viewModel.phase {
            return "Starting in \(remaining)"
        }
        if viewModel.phase == .preparing {
            return "Preparing…"
        }
        return "Start Zone 2"
    }

    private var bpmText: String {
        guard let bpm = viewModel.currentHeartRate else { return "--" }
        return "\(Int(bpm.rounded()))"
    }

    private var zoneColor: Color {
        guard let zone = viewModel.currentZone else { return .secondary }
        return ZonePalette.color(zone.number)
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity)
    }

    private var corosHelpText: String {
        "Apple Health stores the workout. The COROS band talks over Bluetooth — there is no COROS login in this app. Wear the band so it wakes, allow Bluetooth when asked, and wait until you see a live BPM before starting."
    }
}
