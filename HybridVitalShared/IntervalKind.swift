import Foundation

nonisolated enum IntervalKind: String, Codable, CaseIterable, Sendable, Hashable {
    case jog
    case walk

    var displayName: String {
        switch self {
        case .jog: "Jog"
        case .walk: "Walk"
        }
    }

    var systemImage: String {
        switch self {
        case .jog: "figure.run"
        case .walk: "figure.walk"
        }
    }

    var toggled: IntervalKind {
        self == .jog ? .walk : .jog
    }
}
