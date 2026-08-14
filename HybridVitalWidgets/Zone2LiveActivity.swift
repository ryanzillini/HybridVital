import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct Zone2LiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Zone2ActivityAttributes.self) { context in
            lockScreen(context: context)
                .activityBackgroundTint(context.state.isAboveZone3 ? Color.orange.opacity(0.35) : Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(context.state.heartRate)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("BPM")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.intervalKind.displayName)
                            .font(.headline)
                        Text(context.state.zoneName)
                            .font(.caption)
                            .foregroundStyle(context.state.isAboveZone3 ? .orange : .green)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(elapsedText(context.state.elapsedSeconds))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(intent: ToggleLapIntent()) {
                            Text(context.state.intervalKind == .jog ? "Walk" : "Jog")
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(context.state.intervalKind == .jog ? .orange : .green)
                    }
                }
            } compactLeading: {
                Text("\(context.state.heartRate)")
                    .font(.caption.bold())
                    .foregroundStyle(context.state.isAboveZone3 ? .orange : .green)
            } compactTrailing: {
                Image(systemName: context.state.intervalKind.systemImage)
            } minimal: {
                Text("\(context.state.heartRate)")
                    .font(.caption2.bold())
            }
        }
    }

    @ViewBuilder
    private func lockScreen(context: ActivityViewContext<Zone2ActivityAttributes>) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(context.state.heartRate)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text(context.state.zoneName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(context.state.isAboveZone3 ? Color.orange : Color.green)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text(elapsedText(context.state.elapsedSeconds))
                    .font(.headline.monospacedDigit())
                Text(context.state.isPaused ? "Paused" : context.state.intervalKind.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(intent: ToggleLapIntent()) {
                    Text(context.state.intervalKind == .jog ? "Entered Z3 — Walk" : "Back to Jog")
                        .font(.subheadline.weight(.bold))
                        .frame(minWidth: 140)
                }
                .buttonStyle(.borderedProminent)
                .tint(context.state.intervalKind == .jog ? .orange : .green)
            }
        }
        .padding(16)
        .foregroundStyle(.white)
    }

    private func elapsedText(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%d:%02d", minutes, remainder)
    }
}
