import UIKit

struct HapticCoach {
    func enteredZone3() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
    }

    func returnedToZone2() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func lapConfirmed() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
