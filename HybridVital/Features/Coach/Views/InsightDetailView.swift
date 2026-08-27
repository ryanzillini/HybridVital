import SwiftData
import SwiftUI

struct InsightDetailView: View {
    let insight: DemoCatalog.Insight
    var services: AppServices?

    @Environment(\.modelContext) private var modelContext

    init(insight: DemoCatalog.Insight, services: AppServices? = nil) {
        self.insight = insight
        self.services = services
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                HVInsightBanner(
                    title: insight.title,
                    bodyText: insight.body,
                    systemImage: insight.systemImage,
                    tint: HVTheme.coach
                )

                HVInsightBanner(
                    title: "Not a diagnosis",
                    bodyText: "This is a pattern from your logs, not a diagnosis. HybridVital will not tell you to change medication or treat a condition.",
                    systemImage: "stethoscope",
                    tint: HVTheme.warning
                )

                whySection

                memoryLayers

                askCoachLink

                HVDisclaimer()
            }
            .padding(.horizontal, HVTheme.pagePadding)
            .padding(.vertical, 16)
        }
        .navigationTitle(insight.title)
        .hvInlineNav()
        .hvScreen()
    }

    private var whySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HVSectionHeader(title: "Why this showed up")
            Text(whyCopy)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var whyCopy: String {
        switch insight.kind {
        case "Learned pattern":
            return "Coach compared the last 30 days of energy ratings with fiber. When fiber landed near 12g, afternoon energy followed it down. That’s a learned pattern from your logs — mute or forget it in Memory if it doesn’t feel right."
        case "Rolling metric":
            return "Rolling metrics recompute from the last 7–30 days of training. Zone 2 is 183 of 150 target minutes this week, so this card is a volume check, not a recommendation to push harder."
        case "Live context":
            return "Live context is pulled when you open Coach: today’s protein (76g of 180g) and the low-cook meals that usually close that gap. It uses your permanent protein target and cooking skill without asking you to recap."
        default:
            return "Coach stacked permanent profile, rolling metrics, and live logs. Nothing here is a medical finding."
        }
    }

    private var memoryLayers: some View {
        VStack(alignment: .leading, spacing: 12) {
            HVSectionHeader(title: "Memory layers", accessory: "Automatic")
            ForEach(layerCards) { card in
                HVCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(card.layer.uppercased())
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(card.isPrimary ? HVTheme.coach : .secondary)
                            if card.isPrimary {
                                Text("Primary")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(HVTheme.coach)
                                    .clipShape(Capsule())
                            }
                        }
                        ForEach(card.items) { item in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(item.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 4)
                        }
                        if card.items.isEmpty {
                            Text(card.fallback)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous)
                        .stroke(card.isPrimary ? HVTheme.coach.opacity(0.35) : Color.clear, lineWidth: 1)
                }
            }
        }
    }

    private var askCoachLink: some View {
        NavigationLink {
            CoachChatView(
                services: resolvedServices,
                initialPrompt: "Tell me more about “\(insight.title)” — treat it as a log pattern, not a diagnosis."
            )
        } label: {
            CoachPrimaryLinkLabel(title: "Ask Coach about this")
        }
        .buttonStyle(.plain)
    }

    private var resolvedServices: AppServices {
        services ?? AppServices(
            food: FoodLoggingRepository(context: modelContext),
            training: TrainingRepository(context: modelContext)
        )
    }

    private var primaryLayerName: String {
        switch insight.kind {
        case "Learned pattern": return "Learned patterns"
        case "Rolling metric": return "Rolling metrics"
        case "Live context": return "Permanent profile"
        default: return insight.kind
        }
    }

    private var layerCards: [LayerCard] {
        let order = ["Permanent profile", "Rolling metrics", "Learned patterns"]
        return order.map { layer in
            LayerCard(
                id: layer,
                layer: layer,
                items: DemoCatalog.memories.filter { $0.layer == layer },
                isPrimary: layer == primaryLayerName,
                fallback: "No items in this layer."
            )
        }
    }

    private struct LayerCard: Identifiable {
        let id: String
        let layer: String
        let items: [DemoCatalog.MemoryItem]
        let isPrimary: Bool
        let fallback: String
    }
}
