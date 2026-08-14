import ActivityKit
import AppIntents
import Foundation

struct ToggleLapIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Toggle Interval"
    static var description = IntentDescription("Log a jog or walk interval during a Zone 2 session.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        LapToggleChannel.post()
        await Zone2LiveActivityOptimisticUpdate.toggleKind()
        return .result()
    }
}

enum Zone2LiveActivityOptimisticUpdate {
    static func toggleKind() async {
        for activity in Activity<Zone2ActivityAttributes>.activities {
            var state = activity.content.state
            state.intervalKind = state.intervalKind.toggled
            let content = ActivityContent(state: state, staleDate: nil)
            await activity.update(content)
        }
    }
}
