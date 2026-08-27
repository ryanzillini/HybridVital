import SwiftUI

enum FoodLogMethod: String, CaseIterable, Identifiable {
    case camera, library, search, voice, manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .camera: "Take photo"
        case .library: "Photo library"
        case .search: "Search foods"
        case .voice: "Voice log"
        case .manual: "Manual entry"
        }
    }

    var subtitle: String {
        switch self {
        case .camera: "Grok Vision parses the plate"
        case .library: "Analyze an existing photo"
        case .search: "USDA + Open Food Facts"
        case .voice: "Speak a meal in seconds"
        case .manual: "Macros you already know"
        }
    }

    var systemImage: String {
        switch self {
        case .camera: "camera.fill"
        case .library: "photo.on.rectangle"
        case .search: "magnifyingglass"
        case .voice: "mic.fill"
        case .manual: "square.and.pencil"
        }
    }
}
