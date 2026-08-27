import SwiftUI

enum HVTheme {
    static let accent = Color.green
    static let warning = Color.orange
    static let danger = Color.red
    static let background = Color.black
    static let card = Color.white.opacity(0.06)
    static let cardElevated = Color.white.opacity(0.08)
    static let cardStroke = Color.white.opacity(0.10)
    static let tertiaryFill = Color.white.opacity(0.04)

    static let calories = Color.blue
    static let protein = Color.red
    static let carbs = Color.orange
    static let fat = Color.yellow
    static let fiber = Color.green
    static let coach = Color.mint

    static let radiusS: CGFloat = 12
    static let radiusM: CGFloat = 16
    static let radiusL: CGFloat = 24

    static let pagePadding: CGFloat = 16
    static let stackSpacing: CGFloat = 20
}

enum HVFont {
    static func heroMetric(_ size: CGFloat = 44) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}

struct HVScreenBackground: View {
    var body: some View {
        HVTheme.background.ignoresSafeArea()
    }
}

struct HVCard<Content: View>: View {
    var padding: CGFloat = 16
    var radius: CGFloat = HVTheme.radiusM
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HVTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

struct HVSectionHeader: View {
    let title: String
    var accessory: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
            Spacer()
            if let accessory {
                Text(accessory)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct HVMetricTile: View {
    let label: String
    let value: String
    var color: Color = .primary
    var caption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(HVTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous))
    }
}

struct HVPrimaryButton: View {
    let title: String
    var systemImage: String?
    var fill: Color = HVTheme.accent
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(fill)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct HVQuickActionTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var tint: Color = HVTheme.accent

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 36))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 140)
        .padding(.vertical, 8)
        .background(HVTheme.cardElevated)
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
    }
}

struct HVProgressBar: View {
    let progress: Double
    var tint: Color = HVTheme.accent

    var body: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(tint.opacity(0.22))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(tint)
                        .frame(width: proxy.size.width * min(max(progress, 0), 1))
                }
        }
        .frame(height: 8)
    }
}

struct HVInsightBanner: View {
    let title: String
    let bodyText: String
    var systemImage: String = "sparkles"
    var tint: Color = HVTheme.coach

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(bodyText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
    }
}

struct HVDisclaimer: View {
    var text: String = "HybridVital is not medical advice. Talk with your clinician before changing diet, training, or medication."

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HVEmptyState: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(description)
        )
        .foregroundStyle(.secondary)
    }
}

extension View {
    func hvScreen() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(HVTheme.background)
            .preferredColorScheme(.dark)
            .tint(HVTheme.accent)
    }

    func hvInlineNav() -> some View {
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(HVTheme.background, for: .navigationBar)
    }
}
