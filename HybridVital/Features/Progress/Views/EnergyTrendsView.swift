import Charts
import SwiftUI

struct EnergyTrendsView: View {
    let services: AppServices
    @State private var range: ProgressTimeRange
    @State private var snapshot: ProgressSnapshot

    init(services: AppServices, range: ProgressTimeRange = .week) {
        self.services = services
        _range = State(initialValue: range)
        _snapshot = State(initialValue: ProgressSnapshot.load(services: services, range: range))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                Picker("Range", selection: $range) {
                    ForEach(ProgressTimeRange.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Energy range")

                HStack(spacing: 10) {
                    HVMetricTile(
                        label: "Energy",
                        value: String(format: "%.1f", snapshot.averageEnergy),
                        color: HVTheme.accent,
                        caption: "1–10 average"
                    )
                    HVMetricTile(
                        label: "Constipation",
                        value: String(format: "%.1f", snapshot.averageConstipation),
                        color: HVTheme.warning,
                        caption: "severity 1–10"
                    )
                    HVMetricTile(
                        label: "Fiber",
                        value: "\(Int(snapshot.averageFiber.rounded()))g",
                        color: HVTheme.fiber,
                        caption: "daily average"
                    )
                }

                if snapshot.macrosAreSample {
                    HVSampleCaption()
                }

                HVCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HVSectionHeader(title: "Energy & digestion")
                        Chart {
                            ForEach(snapshot.macroDays) { day in
                                LineMark(
                                    x: .value("Day", day.date, unit: .day),
                                    y: .value("Score", day.energy)
                                )
                                .foregroundStyle(by: .value("Metric", "Energy"))
                                .interpolationMethod(.catmullRom)
                                .symbol(by: .value("Metric", "Energy"))

                                LineMark(
                                    x: .value("Day", day.date, unit: .day),
                                    y: .value("Score", day.constipation)
                                )
                                .foregroundStyle(by: .value("Metric", "Constipation"))
                                .interpolationMethod(.catmullRom)
                                .symbol(by: .value("Metric", "Constipation"))
                            }
                        }
                        .chartForegroundStyleScale([
                            "Energy": HVTheme.accent,
                            "Constipation": HVTheme.warning
                        ])
                        .chartYScale(domain: 0...10)
                        .chartXAxis {
                            if range == .week {
                                AxisMarks(values: .stride(by: .day)) { _ in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                                }
                            } else {
                                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                                    AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading, values: [0, 5, 10])
                        }
                        .frame(height: 200)
                    }
                }

                HVInsightBanner(
                    title: "A pattern to notice",
                    bodyText: correlationCopy,
                    systemImage: "leaf.fill",
                    tint: HVTheme.fiber
                )

                Text("This is a personal observation from logged days, not a diagnosis. Fiber, fluids, training load, and sleep all move energy.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HVDisclaimer()
            }
            .padding(HVTheme.pagePadding)
        }
        .navigationTitle("Energy & recovery")
        .hvInlineNav()
        .hvScreen()
        .onChange(of: range) { _, newValue in
            snapshot = ProgressSnapshot.load(services: services, range: newValue)
        }
    }

    private var correlationCopy: String {
        if snapshot.macrosAreSample {
            return "Fiber dip days lined up with lower energy in this sample. A 25g+ fiber day has usually tracked with steadier afternoon energy here — worth watching, not a rule."
        }
        return "If energy dips on lower-fiber days, that’s a correlation to notice with your clinician — not proof that fiber is the only lever."
    }
}
