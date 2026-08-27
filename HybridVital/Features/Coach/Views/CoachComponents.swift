import SwiftUI

struct CoachChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(HVTheme.coach.opacity(0.16))
            .foregroundStyle(HVTheme.coach)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(HVTheme.coach.opacity(0.28), lineWidth: 1)
            }
    }
}

struct CoachChipStrip: View {
    let chips: [String]
    var accessibilityLabelText: String = "Today’s context"

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chips, id: \.self) { chip in
                    CoachChip(text: chip)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabelText)
    }
}

struct CoachMessageBubble: View {
    let message: DemoCatalog.ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser {
                Spacer(minLength: 44)
            } else {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HVTheme.coach)
                    .frame(width: 28, height: 28)
                    .background(HVTheme.coach.opacity(0.16))
                    .clipShape(Circle())
                    .accessibilityHidden(true)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(isUser ? Color.black : Color.primary)
                    .textSelection(.enabled)
                    .padding(12)
                    .background(isUser ? HVTheme.accent : HVTheme.cardElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                if !message.chips.isEmpty {
                    CoachChipStrip(chips: message.chips, accessibilityLabelText: "Reply tags")
                }

                Text(message.timestamp, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if !isUser {
                Spacer(minLength: 36)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isUser ? "You: \(message.text)" : "Coach: \(message.text)")
    }
}

struct CoachThinkingRow: View {
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(HVTheme.coach)
            ProgressView()
                .tint(HVTheme.coach)
            Text("Coach is thinking…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(HVTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
        .accessibilityLabel("Coach is thinking")
    }
}

struct CoachPrimaryLinkLabel: View {
    let title: String
    var systemImage: String = "sparkles"
    var fill: Color = HVTheme.coach

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(fill)
        .foregroundStyle(.black)
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
    }
}

struct CoachRowCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            content()
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HVTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous)
                .stroke(HVTheme.cardStroke, lineWidth: 1)
        }
    }
}
