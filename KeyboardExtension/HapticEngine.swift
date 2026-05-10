import UIKit
import CoreHaptics

/// Wraps UIImpactFeedbackGenerator with a Full Access gate.
/// All methods silently no-op when Full Access is off or the device lacks haptic hardware.
final class HapticEngine {
    static let shared = HapticEngine()
    private(set) var hasFullAccess = false
    private init() {}

    /// Call once in `viewWillAppear` after `UIInputViewController.hasFullAccess` is known.
    func configure(hasFullAccess: Bool) {
        self.hasFullAccess = hasFullAccess
    }

    func keyTap()    { fire(.light) }
    func deleteTap() { fire(.medium) }
    func returnTap() { fire(.rigid) }
    func spaceTap()  { fire(.light) }

    func shiftToggle() {
        guard hasFullAccess, isCapable else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Private

    private var isCapable: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    private func fire(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hasFullAccess, isCapable else { return }
        let g = UIImpactFeedbackGenerator(style: style)
        g.prepare()
        g.impactOccurred()
    }
}
