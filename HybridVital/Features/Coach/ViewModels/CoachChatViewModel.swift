import Foundation
import Observation

@MainActor
@Observable
final class CoachChatViewModel {
    var messages: [DemoCatalog.ChatMessage]
    var composerText: String = ""
    var isThinking: Bool = false

    private let services: AppServices
    private let initialPrompt: String?
    private var didConsumeInitialPrompt = false

    init(services: AppServices, initialPrompt: String? = nil) {
        self.services = services
        self.initialPrompt = initialPrompt
        self.messages = DemoCatalog.conversation
    }

    var contextMessage: DemoCatalog.ChatMessage? {
        messages.first(where: { $0.role == .system })
    }

    var transcript: [DemoCatalog.ChatMessage] {
        messages.filter { $0.role != .system }
    }

    var canSend: Bool {
        !isThinking && !composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func seedIfNeeded() async {
        guard !didConsumeInitialPrompt else { return }
        didConsumeInitialPrompt = true
        guard let initialPrompt else { return }
        let text = initialPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        await appendUserAndReply(text)
    }

    func sendComposer() async {
        let text = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }
        composerText = ""
        await appendUserAndReply(text)
    }

    private func appendUserAndReply(_ text: String) async {
        messages.append(
            DemoCatalog.ChatMessage(role: .user, text: text, timestamp: .now)
        )
        isThinking = true
        try? await Task.sleep(for: .milliseconds(1100))
        guard !Task.isCancelled else {
            isThinking = false
            return
        }
        messages.append(cannedReply(to: text))
        isThinking = false
    }

    private var firstName: String {
        let raw = services.training.getOrCreateProfile().firstName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let raw, !raw.isEmpty { return raw }
        return DemoCatalog.greetingName
    }

    private var contextChips: [String] {
        contextMessage?.chips ?? []
    }

    private func chip(containing needle: String) -> String {
        contextChips.first { $0.localizedCaseInsensitiveContains(needle) } ?? needle
    }

    private func cannedReply(to userText: String) -> DemoCatalog.ChatMessage {
        let protein = chip(containing: "Protein")
        let fiber = chip(containing: "Fiber")
        let zone2 = chip(containing: "Z2")
        let text: String
        switch Intent(from: userText) {
        case .protein:
            text = """
            \(firstName), I’m reading \(protein) against your 180g target — that’s a gap in the log, not a diagnosis.

            Low-cook close: canned salmon plus a Core Power shake. That stays more cholesterol-aware than another meat-heavy dinner. \(zone2) already, so you don’t need extra intensity to “earn” food.

            If this is about lipids, medication, or a clinician-set protein number, check with them before you change anything.
            """
        case .zone2:
            text = """
            After Zone 2, keep the plate simple: protein + some carbs, minimal cooking. \(zone2) means volume is already ahead of the 150-minute target — more intensity isn’t the ask.

            \(protein) is still open. A salmon salad with berries covers protein and \(fiber) without a long cook. This is pattern-matching on your logs, not medical clearance for training or recovery.
            """
        case .energy:
            text = """
            Low-energy days in your log have lined up with lighter fiber — a correlation, not a diagnosis. Right now I’m holding \(fiber) and \(protein).

            Frozen berries or kiwi with yogurt is the low-cook move. Skip heroic kitchen work on a flat day.

            Sudden, severe, or medication-linked fatigue is a clinician conversation. I won’t tell you to push Zone 2 through that.
            """
        case .fiber:
            text = """
            Simple high-fiber lunch: canned salmon over greens with olive oil, plus frozen berries. That nudges \(fiber) without a high-cholesterol cook. Oats are the other low-skill option if you want something warm.

            \(protein) still matters — the salmon covers both. I’m not diagnosing constipation or GI issues; if symptoms persist, ask your clinician.
            """
        case .general:
            text = """
            I already have \(protein), \(fiber), and \(zone2) in context — no need to recap.

            Conservative default: low-cook, cholesterol-aware food (salmon, yogurt, berries, or a shake). Close protein first, then fiber. Zone 2 volume is ahead of target, so extra intensity isn’t required today.

            I don’t diagnose. Diet, training, or medication changes belong with your clinician — especially with a cholesterol-aware profile.
            """
        }

        return DemoCatalog.ChatMessage(
            role: .coach,
            text: text,
            timestamp: .now,
            chips: ["Low cook", "Cholesterol-aware", "Not a diagnosis"]
        )
    }

    private enum Intent {
        case protein, zone2, energy, fiber, general

        init(from text: String) {
            let t = text.lowercased()
            if t.contains("protein") || t.contains("180g") || t.contains("180 g") {
                self = .protein
            } else if t.contains("fiber") || t.contains("lunch") {
                self = .fiber
            } else if t.contains("zone") || t.contains("z2") {
                self = .zone2
            } else if t.contains("energy") || t.contains("sluggish") || t.contains("tired") {
                self = .energy
            } else {
                self = .general
            }
        }
    }
}
