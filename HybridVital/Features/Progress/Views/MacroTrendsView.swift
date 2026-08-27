import Charts
import SwiftUI

struct MacroTrendsView: View {
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
                .accessibilityLabel("Macro range")

                if snapshot.macrosAreSample {
                    HVSampleCaption()
                }

                macroChart(
                    title: "Protein",
                    unit: "g",
                    color: HVTheme.protein,
                    target: Double(snapshot.proteinTarget),
                    values: snapshot.macroDays.map { ($0.date, $0.proteinG) }
                )

                macroChart(
                    title: "Fiber",
                    unit: "g",
                    color: HVTheme.fiber,
                    target: Double(snapshot.fiberTarget),
                    values: snapshot.macroDays.map { ($0.date, $0.fiberG) }
                )

                macroChart(
                    title: "Calories",
                    unit: "kcal",
                    color: HVTheme.calories,
                    target: Double(snapshot.calorieTarget),
                    values: snapshot.macroDays.map { ($0.date, $0.calories) }
                )

                HVCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cholesterol is informational")
                            .font(.subheadline.weight(.semibold))
                        Text("Daily cholesterol isn’t a coaching target here. If you live with familial hypocholesterolemia, treat meal cholesterol as context for you and your clinician — HybridVital does not diagnose or treat.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HVDisclaimer()
            }
            .padding(HVTheme.pagePadding)
        }
        .navigationTitle("Macro trends")
        .hvInlineNav()
        .hvScreen()
        .onChange(of: range) { _, newValue in
            snapshot = ProgressSnapshot.load(services: services, range: newValue)
        }
    }

    private func macroChart(
        title: String,
        unit: String,
        color: Color,
        target: Double,
        values: [(Date, Double)]
    ) -> some View {
        HVCard {
            VStack(alignment: .leading, spacing: 10) {
                HVSectionHeader(title: title, accessory: "Target \(Int(target.rounded())) \(unit)")
                Chart {
                    ForEach(Array(values.enumerated()), id: \.offset) { _, point in
                        LineMark(
                            x: .value("Day", point.0, unit: .day),
                            y: .value(title, point.1)
                        )
                        .foregroundStyle(color)
                        .interpolationMethod(.catmullRom)
                        AreaMark(
                            x: .value("Day", point.0, unit: .day),
                            y: .value(title, point.1)
                        )
                        .foregroundStyle(color.opacity(0.16))
                        .interpolationMethod(.catmullRom)
                    }
                    RuleMark(y: .value("Target", target))
                        .foregroundStyle(.white.opacity(0.35))
                        .lineStyle(StrokeStyle(dash: [5, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("\(Int(target.rounded()))\(unit == "kcal" ? "" : unit)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
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
                .frame(height: 180)
            }
        }
    }
}
