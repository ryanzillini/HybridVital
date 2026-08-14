import Foundation

struct ZoneCalculator {
    var settings: HeartRateZoneSettings
    private(set) var durations = ZoneDurations()
    private(set) var currentZone: HeartRateZone?
    private var lastTimestamp: Date?
    private var lastZoneNumber: Int?

    enum CrossEvent: Equatable {
        case none
        case enteredZone3
        case returnedToZone2
    }

    init(settings: HeartRateZoneSettings) {
        self.settings = settings
    }

    mutating func ingest(bpm: Double, at date: Date = .now) -> CrossEvent {
        let zone = settings.zone(for: bpm)
        currentZone = zone
        let zoneNumber = zone?.number

        if let lastTimestamp, let lastZoneNumber {
            let delta = date.timeIntervalSince(lastTimestamp)
            if delta > 0, delta < 30 {
                durations.add(seconds: delta, zone: lastZoneNumber)
            }
        }

        var event: CrossEvent = .none
        if let lastZoneNumber, let zoneNumber {
            let wasAbove = lastZoneNumber >= 3
            let isAbove = zoneNumber >= 3
            if !wasAbove, isAbove {
                event = .enteredZone3
            } else if wasAbove, !isAbove {
                event = .returnedToZone2
            }
        }

        lastTimestamp = date
        lastZoneNumber = zoneNumber
        return event
    }
}
