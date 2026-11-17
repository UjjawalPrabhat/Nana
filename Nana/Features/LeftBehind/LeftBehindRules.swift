import Foundation

/// When a charm counts as left behind, and when to nudge about it.
/// Pure, so the timing can be tested without Bluetooth, location or a clock.
nonisolated enum LeftBehindRules {
    struct Input: Equatable, Sendable {
        /// When the charm went out of range, or `nil` while it's connected
        /// (or Bluetooth is off, which pauses nudges).
        var disconnectedSince: Date?
        /// Inside a saved place. Without location access this stays `false`,
        /// so Nana nudges whenever the charm stays out of range.
        var isInsidePlace: Bool
        /// Short signal drops shouldn't count.
        var wait: TimeInterval
        var snoozedUntil: Date?
        /// "I left it on purpose", until the charm reconnects.
        var isDismissed: Bool
    }

    static let snoozeLength: TimeInterval = 15 * 60

    /// When the nudge should go off, or `nil` if it shouldn't.
    static func nudgeDate(for input: Input) -> Date? {
        guard let since = input.disconnectedSince, !input.isInsidePlace, !input.isDismissed else { return nil }
        let due = since.addingTimeInterval(input.wait)
        guard let snoozedUntil = input.snoozedUntil else { return due }
        return max(due, snoozedUntil)
    }

    /// Whether Home should say the charm stayed behind. Snoozing doesn't
    /// change this; the charm is still behind.
    static func isLeftBehind(_ input: Input, now: Date) -> Bool {
        guard let since = input.disconnectedSince, !input.isInsidePlace, !input.isDismissed else { return false }
        return since.addingTimeInterval(input.wait) <= now
    }
}
