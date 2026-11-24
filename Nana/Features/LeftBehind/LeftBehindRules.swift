import Foundation

/// When a Pod counts as left behind, and when to nudge about it.
/// Pure, so the timing can be tested without Bluetooth or a clock.
nonisolated enum LeftBehindRules {
    struct Input: Equatable, Sendable {
        /// When the Pod went out of range, or `nil` while it's connected.
        var disconnectedSince: Date?
        /// Bluetooth is off, so nobody can tell where the Pod is. Nudges pause,
        /// but the trip (and any snooze or dismissal) carries on.
        var isPaused = false
        /// Short signal drops shouldn't count.
        var wait: TimeInterval
        var snoozedUntil: Date?
        /// "I left it on purpose", until the Pod reconnects.
        var isDismissed: Bool
    }

    static let snoozeLength: TimeInterval = 15 * 60

    /// When the nudge should go off, or `nil` if it shouldn't.
    static func nudgeDate(for input: Input) -> Date? {
        guard let since = input.disconnectedSince, !input.isPaused, !input.isDismissed else { return nil }
        let due = since.addingTimeInterval(input.wait)
        guard let snoozedUntil = input.snoozedUntil else { return due }
        return max(due, snoozedUntil)
    }

    /// Whether Home should say the Pod stayed behind. Snoozing doesn't
    /// change this; the Pod is still behind.
    static func isLeftBehind(_ input: Input, now: Date) -> Bool {
        guard let since = input.disconnectedSince, !input.isPaused, !input.isDismissed else { return false }
        return since.addingTimeInterval(input.wait) <= now
    }
}
