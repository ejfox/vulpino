import UIKit

/// Centralized haptic feedback
/// Subtle, purposeful feedback that reinforces actions
enum Haptics {

    private static let impactLight = UIImpactFeedbackGenerator(style: .light)
    private static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private static let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let selection = UISelectionFeedbackGenerator()
    private static let notification = UINotificationFeedbackGenerator()

    /// Light tap for selections, toggles
    static func tap() {
        impactLight.impactOccurred()
    }

    /// Medium impact for confirmations
    static func confirm() {
        impactMedium.impactOccurred()
    }

    /// Selection changed feedback
    static func select() {
        selection.selectionChanged()
    }

    /// Success feedback (saved, completed)
    static func success() {
        notification.notificationOccurred(.success)
    }

    /// Warning feedback (validation error, caution)
    static func warning() {
        notification.notificationOccurred(.warning)
    }

    /// Error feedback (failed action)
    static func error() {
        notification.notificationOccurred(.error)
    }

    /// Prepare generators for immediate response
    static func prepare() {
        impactLight.prepare()
        impactMedium.prepare()
        selection.prepare()
        notification.prepare()
    }
}
