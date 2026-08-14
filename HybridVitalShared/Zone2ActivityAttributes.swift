import ActivityKit
import Foundation

nonisolated struct Zone2ActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable, Sendable {
        var heartRate: Int
        var zoneNumber: Int
        var zoneName: String
        var intervalKind: IntervalKind
        var elapsedSeconds: Int
        var timeInZone2Seconds: Int
        var isPaused: Bool
        var isAboveZone3: Bool
    }

    var startedAt: Date
}
