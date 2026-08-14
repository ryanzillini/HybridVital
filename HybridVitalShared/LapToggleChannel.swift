import Foundation

nonisolated enum LapToggleStore {
    static let appGroupID = "group.com.hybridvital.HybridVital"
    private static let key = "pendingLapToggles"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func enqueue(date: Date = .now) {
        var items = load()
        items.append(date.timeIntervalSince1970)
        defaults.set(items, forKey: key)
    }

    static func drain() -> [Date] {
        let items = load()
        defaults.removeObject(forKey: key)
        return items.map { Date(timeIntervalSince1970: $0) }
    }

    private static func load() -> [Double] {
        defaults.array(forKey: key) as? [Double] ?? []
    }
}

nonisolated enum LapToggleChannel {
    static let notificationName = "com.hybridvital.zone2.toggleLap"

    private static let handlerLock = NSLock()
    private static var onToggle: (@Sendable () -> Void)?
    private static var isListening = false

    static func post() {
        LapToggleStore.enqueue()
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(notificationName as CFString),
            nil,
            nil,
            true
        )
    }

    static func startListening(_ handler: @escaping @Sendable () -> Void) {
        handlerLock.lock()
        onToggle = handler
        let alreadyListening = isListening
        isListening = true
        handlerLock.unlock()

        guard !alreadyListening else { return }

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            { _, _, _, _, _ in
                LapToggleChannel.handlerLock.lock()
                let handler = LapToggleChannel.onToggle
                LapToggleChannel.handlerLock.unlock()
                handler?()
            },
            notificationName as CFString,
            nil,
            .deliverImmediately
        )
    }
}
