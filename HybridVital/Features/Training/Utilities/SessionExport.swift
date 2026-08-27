import Foundation
import SwiftUI
import UIKit

enum SessionExportFormat: String {
    case json
    case csv
}

enum SessionExport {
    static func shareItems(for session: TrainingSession, format: SessionExportFormat) throws -> [URL] {
        let stamp = filenameStamp(session.startedAt)
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("HybridVital-\(stamp)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        switch format {
        case .json:
            let url = folder.appendingPathComponent("HybridVital-Zone2-\(stamp).json")
            try payload(from: session).encodedJSON().write(to: url, options: .atomic)
            return [url]
        case .csv:
            let hrURL = folder.appendingPathComponent("HybridVital-Zone2-\(stamp)-heartrate.csv")
            let lapsURL = folder.appendingPathComponent("HybridVital-Zone2-\(stamp)-laps.csv")
            try heartRateCSV(from: session).write(to: hrURL, atomically: true, encoding: .utf8)
            try lapsCSV(from: session).write(to: lapsURL, atomically: true, encoding: .utf8)
            return [hrURL, lapsURL]
        }
    }

    private static func payload(from session: TrainingSession) -> Payload {
        Payload(
            id: session.id,
            startedAt: session.startedAt,
            endedAt: session.endedAt,
            durationSeconds: session.durationSeconds,
            healthKitWorkoutUUID: session.healthKitWorkoutUUID,
            avgHR: session.avgHR,
            maxHR: session.maxHR,
            minHR: session.minHR,
            activeCalories: session.activeCalories,
            distanceMeters: session.distanceMeters,
            intervalCount: session.intervalCount,
            avgJogSeconds: session.avgJogSeconds,
            avgWalkSeconds: session.avgWalkSeconds,
            longestJogSeconds: session.longestJogSeconds,
            fastestRecoverySeconds: session.fastestRecoverySeconds,
            fatigueNote: session.fatigueNote,
            notes: session.notes,
            zoneDurations: session.zoneDurations,
            intervals: intervalPayloads(from: session),
            heartRate: session.downsampledHR
        )
    }

    private static func intervalPayloads(from session: TrainingSession) -> [IntervalPayload] {
        let sorted = session.sortedIntervals
        var payloads: [IntervalPayload] = []
        payloads.reserveCapacity(sorted.count)
        for interval in sorted {
            payloads.append(IntervalPayload(interval))
        }
        return payloads
    }

    private static func heartRateCSV(from session: TrainingSession) -> String {
        var rows = ["timestamp,bpm"]
        for point in session.downsampledHR {
            rows.append("\(iso(point.timestamp)),\(csvNumber(point.bpm))")
        }
        return rows.joined(separator: "\n") + "\n"
    }

    private static func lapsCSV(from session: TrainingSession) -> String {
        var rows = [
            "kind,startedAt,endedAt,durationSeconds,startHR,endHR,avgHR,maxHR,minHR,timeToReenterZone2Seconds"
        ]
        for interval in session.sortedIntervals {
            rows.append(lapRow(from: interval))
        }
        return rows.joined(separator: "\n") + "\n"
    }

    private static func lapRow(from interval: WorkoutInterval) -> String {
        let ended: String
        if let endedAt = interval.endedAt {
            ended = iso(endedAt)
        } else {
            ended = ""
        }
        return [
            interval.kind.rawValue,
            iso(interval.startedAt),
            ended,
            csvNumber(interval.durationSeconds),
            csvNumber(interval.startHR),
            csvNumber(interval.endHR),
            csvNumber(interval.avgHR),
            csvNumber(interval.maxHR),
            csvNumber(interval.minHR),
            csvNumber(interval.timeToReenterZone2Seconds)
        ].joined(separator: ",")
    }

    private static func filenameStamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd-HHmm"
        return formatter.string(from: date)
    }

    nonisolated private static func iso(_ date: Date) -> String {
        date.ISO8601Format()
    }

    private static func csvNumber(_ value: Double?) -> String {
        guard let value else { return "" }
        if value == value.rounded() {
            return String(Int(value.rounded()))
        }
        return String(format: "%.3f", value)
    }
}

private struct Payload: Encodable {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Double
    var healthKitWorkoutUUID: UUID?
    var avgHR: Double?
    var maxHR: Double?
    var minHR: Double?
    var activeCalories: Double?
    var distanceMeters: Double?
    var intervalCount: Int
    var avgJogSeconds: Double?
    var avgWalkSeconds: Double?
    var longestJogSeconds: Double?
    var fastestRecoverySeconds: Double?
    var fatigueNote: String?
    var notes: String?
    var zoneDurations: ZoneDurations
    var intervals: [IntervalPayload]
    var heartRate: [HRSamplePoint]
}

private struct IntervalPayload: Encodable {
    var id: UUID
    var kind: IntervalKind
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Double
    var startHR: Double?
    var endHR: Double?
    var avgHR: Double?
    var maxHR: Double?
    var minHR: Double?
    var timeToReenterZone2Seconds: Double?

    init(_ interval: WorkoutInterval) {
        id = interval.id
        kind = interval.kind
        startedAt = interval.startedAt
        endedAt = interval.endedAt
        durationSeconds = interval.durationSeconds
        startHR = interval.startHR
        endHR = interval.endHR
        avgHR = interval.avgHR
        maxHR = interval.maxHR
        minHR = interval.minHR
        timeToReenterZone2Seconds = interval.timeToReenterZone2Seconds
    }
}

private extension Payload {
    func encodedJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onComplete: () -> Void = {}

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            Task { @MainActor in
                onComplete()
            }
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
