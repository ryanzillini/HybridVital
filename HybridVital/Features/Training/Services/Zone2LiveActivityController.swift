import ActivityKit
import Foundation

@MainActor
final class Zone2LiveActivityController {
    private var activity: Activity<Zone2ActivityAttributes>?

    func start(startedAt: Date, state: Zone2ActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        endSilently()

        let attributes = Zone2ActivityAttributes(startedAt: startedAt)
        let content = ActivityContent(state: state, staleDate: nil)
        do {
            activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
        } catch {
            print("[Zone2] Live Activity failed to start: \(error)")
        }
    }

    func update(_ state: Zone2ActivityAttributes.ContentState) {
        guard let activity else { return }
        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(30))
        Task {
            await activity.update(content)
        }
    }

    func end() async {
        guard let activity else { return }
        let content = ActivityContent(state: activity.content.state, staleDate: nil)
        await activity.end(content, dismissalPolicy: .immediate)
        self.activity = nil
    }

    private func endSilently() {
        let existing = Activity<Zone2ActivityAttributes>.activities
        guard !existing.isEmpty else { return }
        Task {
            for item in existing {
                await item.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
