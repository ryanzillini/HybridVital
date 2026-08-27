import SwiftUI

struct WeeklyReportView: View {
    let services: AppServices
    @State private var snapshot: ProgressSnapshot

    init(services: AppServices) {
        self.services = services
        _snapshot = State(initialValue: ProgressSnapshot.load(services: services, range: .week))
    }

    private var summary: String { DemoCatalog.weeklyReportSummary }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                HVCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("This week")
                                .font(.headline)
                            Spacer()
                            if snapshot.macrosAreSample || snapshot.trainingIsSample {
                                HVSampleCaption()
                            }
                        }
                        Text(summary)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 10
                ) {
                    HVMetricTile(
                        label: "Zone 2",
                        value: "\(snapshot.zone2CompletedMinutes) min",
                        color: ZonePalette.color(2),
                        caption: "target \(snapshot.zone2TargetMinutes)"
                    )
                    HVMetricTile(
                        label: "Protein",
                        value: "\(Int(snapshot.averageProtein.rounded()))g",
                        color: HVTheme.protein,
                        caption: "avg vs \(snapshot.proteinTarget)g"
                    )
                    HVMetricTile(
                        label: "Fiber",
                        value: "\(Int(snapshot.averageFiber.rounded()))g",
                        color: HVTheme.fiber,
                        caption: "avg vs \(snapshot.fiberTarget)g"
                    )
                    HVMetricTile(
                        label: "Energy",
                        value: String(format: "%.1f", snapshot.averageEnergy),
                        color: HVTheme.accent,
                        caption: "average / 10"
                    )
                    HVMetricTile(
                        label: "Sessions",
                        value: "\(snapshot.trainedDayCount)",
                        color: .primary,
                        caption: "days with Zone 2"
                    )
                    HVMetricTile(
                        label: "Z2 %",
                        value: snapshot.averageZone2Percent.map { "\($0)%" } ?? "—",
                        color: ZonePalette.color(2),
                        caption: "when training"
                    )
                }

                ShareLink(item: summary) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share report")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(HVTheme.accent)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share report")

                HVDisclaimer()
            }
            .padding(HVTheme.pagePadding)
        }
        .navigationTitle("Weekly report")
        .hvInlineNav()
        .hvScreen()
    }
}
