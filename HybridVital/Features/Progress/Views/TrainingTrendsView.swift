import Charts
import SwiftUI

struct TrainingTrendsView: View {
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
                .accessibilityLabel("Training range")

                HStack(spacing: 10) {
                    HVMetricTile(
                        label: "Zone 2 minutes",
                        value: "\(snapshot.trainingDays.reduce(0) { $0 + $1.zone2Minutes })",
                        color: ZonePalette.color(2),
                        caption: range.title.lowercased()
                    )
                    HVMetricTile(
                        label: "Days trained",
                        value: "\(snapshot.trainedDayCount)",
                        color: .primary,
                        caption: "of \(snapshot.trainingDays.count)"
                    )
                    HVMetricTile(
                        label: "Z2 %",
                        value: snapshot.averageZone2Percent.map { "\($0)%" } ?? "—",
                        color: ZonePalette.color(2),
                        caption: "when you trained"
                    )
                }

                if snapshot.trainingIsSample {
                    HVSampleCaption()
                }

                HVCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HVSectionHeader(title: "Zone 2 minutes")
                        Chart(snapshot.trainingDays) { day in
                            BarMark(
                                x: .value("Day", day.date, unit: .day),
                                y: .value("Minutes", day.zone2Minutes)
                            )
                            .foregroundStyle(ZonePalette.color(2))
                            .cornerRadius(4)
                        }
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
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 200)
                    }
                }

                HVCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Consistency, not intensity")
                            .font(.subheadline.weight(.semibold))
                        Text("Zone 2 is a volume practice. Minutes in range beat a few hard surges into Zone 3. Rest days in the bars are part of the plan — they are not a miss.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HVDisclaimer()
            }
            .padding(HVTheme.pagePadding)
        }
        .navigationTitle("Training trends")
        .hvInlineNav()
        .hvScreen()
        .onChange(of: range) { _, newValue in
            snapshot = ProgressSnapshot.load(services: services, range: newValue)
        }
    }
}
