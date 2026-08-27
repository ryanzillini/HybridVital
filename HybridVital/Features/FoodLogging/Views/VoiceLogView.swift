import SwiftUI

struct VoiceLogView: View {
    let repository: FoodLoggingRepository

    @Environment(\.dismiss) private var dismiss
    @State private var phase: Phase = .idle
    @State private var transcript = "Greek yogurt with berries, honey, and chia"
    @State private var bars: [CGFloat] = Array(repeating: 10, count: 18)
    @State private var showingReview = false

    init(repository: FoodLoggingRepository) {
        self.repository = repository
    }

    private enum Phase {
        case idle, listening, captured
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer(minLength: 12)
                micButton
                waveform
                statusText
                if phase == .captured {
                    transcriptField
                    HVPrimaryButton(title: "Confirm meal", systemImage: "checkmark") {
                        showingReview = true
                    }
                }
                Spacer(minLength: 12)
                HVDisclaimer(
                    text: "Voice logging is simulated here. Confirm the transcript and macros before they hit your day."
                )
            }
            .padding(HVTheme.pagePadding)
            .navigationTitle("Voice log")
            .hvInlineNav()
            .hvScreen()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingReview) {
                FoodAnalysisReviewSheet(
                    repository: repository,
                    food: reviewedFood,
                    saveSource: .voice,
                    onSaved: {
                        showingReview = false
                        dismiss()
                    }
                )
            }
            .task(id: phase) {
                await runListeningLoop()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var micButton: some View {
        Button {
            switch phase {
            case .idle, .captured:
                phase = .listening
            case .listening:
                phase = .captured
            }
        } label: {
            ZStack {
                Circle()
                    .fill(HVTheme.accent.opacity(phase == .listening ? 0.22 : 0.12))
                    .frame(width: 160, height: 160)
                    .scaleEffect(phase == .listening ? 1.08 : 1)
                    .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: phase == .listening)
                Circle()
                    .fill(phase == .listening ? HVTheme.accent : HVTheme.cardElevated)
                    .frame(width: 112, height: 112)
                Image(systemName: phase == .captured ? "waveform" : "mic.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(phase == .listening ? .black : .white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(phase == .listening ? "Stop listening" : "Start listening")
    }

    private var waveform: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(bars.indices, id: \.self) { index in
                Capsule()
                    .fill(phase == .idle ? Color.white.opacity(0.18) : HVTheme.accent)
                    .frame(width: 6, height: bars[index])
            }
        }
        .frame(height: 56)
        .animation(.easeInOut(duration: 0.12), value: bars)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var statusText: some View {
        switch phase {
        case .idle:
            VStack(spacing: 6) {
                Text("Tap to speak a meal")
                    .font(.title3.weight(.semibold))
                Text("A couple of seconds is enough.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        case .listening:
            Text("Listening…")
                .font(.title3.weight(.semibold))
                .foregroundStyle(HVTheme.accent)
        case .captured:
            Text("Got it — edit if needed")
                .font(.title3.weight(.semibold))
        }
    }

    private var transcriptField: some View {
        TextField("Transcript", text: $transcript, axis: .vertical)
            .lineLimit(3...6)
            .padding(16)
            .background(HVTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
    }

    private var reviewedFood: DemoCatalog.CatalogFood {
        let base = DemoCatalog.visionParse
        return DemoCatalog.CatalogFood(
            name: transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? base.name
                : transcript.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: base.brand,
            mealType: base.mealType,
            source: .voice,
            quantity: base.quantity,
            unit: base.unit,
            nutrition: base.nutrition,
            confidence: base.confidence,
            notes: base.notes
        )
    }

    @MainActor
    private func runListeningLoop() async {
        guard phase == .listening else {
            bars = Array(repeating: 10, count: 18)
            return
        }
        for _ in 0..<16 {
            guard !Task.isCancelled, phase == .listening else { return }
            bars = bars.indices.map { index in
                let wave = abs(sin(Double(index) + Date().timeIntervalSince1970 * 4))
                return CGFloat(10 + wave * 38)
            }
            try? await Task.sleep(for: .milliseconds(110))
        }
        if phase == .listening {
            phase = .captured
            bars = Array(repeating: 16, count: 18)
        }
    }
}
