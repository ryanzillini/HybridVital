import SwiftUI

struct CoachChatView: View {
    let services: AppServices
    var initialPrompt: String? = nil

    @State private var viewModel: CoachChatViewModel
    @FocusState private var composerFocused: Bool

    init(services: AppServices, initialPrompt: String? = nil) {
        self.services = services
        self.initialPrompt = initialPrompt
        _viewModel = State(
            initialValue: CoachChatViewModel(services: services, initialPrompt: initialPrompt)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if let system = viewModel.contextMessage {
                contextCard(system)
                    .padding(.horizontal, HVTheme.pagePadding)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
            }
            transcript
            composerBar
            HVDisclaimer(
                text: "Coach reads your logs. It does not diagnose or replace your clinician — especially for cholesterol, medication, or GI symptoms."
            )
            .padding(.horizontal, HVTheme.pagePadding)
            .padding(.bottom, 10)
        }
        .navigationTitle("Chat")
        .hvInlineNav()
        .hvScreen()
        .scrollDismissesKeyboard(.interactively)
        .task {
            await viewModel.seedIfNeeded()
        }
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(viewModel.transcript) { message in
                        CoachMessageBubble(message: message)
                            .id(message.id)
                    }

                    if viewModel.isThinking {
                        CoachThinkingRow()
                            .id("thinking")
                    }
                }
                .padding(.horizontal, HVTheme.pagePadding)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .defaultScrollAnchor(.bottom)
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToLatest(proxy)
            }
            .onChange(of: viewModel.isThinking) { _, _ in
                scrollToLatest(proxy)
            }
        }
    }

    private func contextCard(_ system: DemoCatalog.ChatMessage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Automatic context", systemImage: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(HVTheme.coach)
            Text(system.text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if !system.chips.isEmpty {
                CoachChipStrip(chips: system.chips)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HVTheme.coach.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous)
                .stroke(HVTheme.coach.opacity(0.22), lineWidth: 1)
        }
    }

    private var composerBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(
                "Ask about protein, Zone 2, or meals…",
                text: $viewModel.composerText,
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .lineLimit(1...5)
            .focused($composerFocused)
            .submitLabel(.send)
            .onSubmit {
                Task { await viewModel.sendComposer() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(HVTheme.cardElevated)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            Button {
                composerFocused = false
                Task { await viewModel.sendComposer() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(viewModel.canSend ? HVTheme.coach : Color.white.opacity(0.22))
                    .symbolRenderingMode(.hierarchical)
            }
            .disabled(!viewModel.canSend)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, HVTheme.pagePadding)
        .padding(.vertical, 10)
        .background(HVTheme.background)
    }

    private func scrollToLatest(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            if viewModel.isThinking {
                proxy.scrollTo("thinking", anchor: .bottom)
            } else if let last = viewModel.transcript.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}
