import ActivityKit
import Foundation

@MainActor
final class Zone2LiveActivityController {
    private var activity: Activity<Zone2ActivityAttributes>?
    private var lastState: Zone2ActivityAttributes.ContentState?
    private var pendingState: Zone2ActivityAttributes.ContentState?
    private var isUpdating = false

    func start(startedAt: Date, state: Zone2ActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        endSilently()

        lastState = state
        pendingState = nil
        isUpdating = false

        let attributes = Zone2ActivityAttributes(startedAt: startedAt)
        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(60))
        do {
            activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
        } catch {
            print("[Zone2] Live Activity failed to start: \(error)")
        }
    }

    func update(_ state: Zone2ActivityAttributes.ContentState) {
        guard activity != nil else { return }
        if state == lastState, pendingState == nil { return }
        pendingState = state
        pump()
    }

    func end() async {
        pendingState = nil
        isUpdating = false
        lastState = nil
        guard let activity else { return }
        let content = ActivityContent(state: activity.content.state, staleDate: nil)
        await activity.end(content, dismissalPolicy: .immediate)
        self.activity = nil
    }

    private func pump() {
        guard !isUpdating, let activity, let state = pendingState else { return }
        pendingState = nil
        lastState = state
        isUpdating = true
        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(60))
        Task { @MainActor in
            await activity.update(content)
            self.isUpdating = false
            if self.pendingState != nil {
                self.pump()
            }
        }
    }

    private func endSilently() {
        let existing = Activity<Zone2ActivityAttributes>.activities
        guard !existing.isEmpty else { return }
        for item in existing {
            Task { await item.end(nil, dismissalPolicy: .immediate) }
        }
        activity = nil
    }
}
