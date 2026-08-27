import SwiftUI

enum ZonePalette {
    static func color(_ zone: Int) -> Color {
        switch zone {
        case 1: .gray
        case 2: .green
        case 3: .yellow
        case 4: .orange
        case 5: .red
        default: .secondary
        }
    }
}
