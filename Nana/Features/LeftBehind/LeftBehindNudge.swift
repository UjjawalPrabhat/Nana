import Foundation

/// Keeps the left-behind nudge scheduled for the right moment. The charm's
/// link and the place check are pushed in by the app; this only decides.
@Observable
final class LeftBehindNudge {
    private(set) var disconnectedSince: Date?
    private var isInsidePlace = false
    private(set) var snoozedUntil: Date?
    private(set) var isDismissed: Bool

    @ObservationIgnored private let scheduler: NudgeScheduling
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let now: () -> Date

    private static let snoozedUntilKey = "leftBehind.snoozedUntil"
    private static let dismissedKey = "leftBehind.dismissed"
    private static let scheduledForKey = "leftBehind.scheduledFor"

    init(scheduler: NudgeScheduling, defaults: UserDefaults = .standard, now: @escaping () -> Date = { .now }) {
        self.scheduler = scheduler
        self.defaults = defaults
        self.now = now
        snoozedUntil = defaults.object(forKey: Self.snoozedUntilKey) as? Date
        isDismissed = defaults.bool(forKey: Self.dismissedKey)
    }

    private var input: LeftBehindRules.Input {
        LeftBehindRules.Input(
            disconnectedSince: disconnectedSince,
            isInsidePlace: isInsidePlace,
            wait: TimeInterval(defaults.integer(forKey: AppSettings.leftBehindWaitMinutes) * 60),
            snoozedUntil: snoozedUntil,
            isDismissed: isDismissed
        )
    }

    /// Time-based, so views re-check it on a timer.
    func isLeftBehind(at date: Date) -> Bool {
        LeftBehindRules.isLeftBehind(input, now: date)
    }

    func charmLinkChanged(disconnectedSince: Date?) {
        self.disconnectedSince = disconnectedSince
        if disconnectedSince == nil {
            // Back in range: this trip is over.
            setSnoozed(until: nil)
            setDismissed(false)
        }
        reschedule()
    }

    func placeChanged(isInside: Bool) {
        isInsidePlace = isInside
        reschedule()
    }

    func snooze() {
        setSnoozed(until: now().addingTimeInterval(LeftBehindRules.snoozeLength))
        reschedule()
    }

    func leftOnPurpose() {
        setDismissed(true)
        reschedule()
    }

    /// Call after the on/off switch or the wait time changes.
    func reschedule() {
        guard defaults.bool(forKey: AppSettings.leftBehindNudgeOn),
              let date = LeftBehindRules.nudgeDate(for: input)
        else {
            scheduler.cancel(.leftBehind)
            defaults.removeObject(forKey: Self.scheduledForKey)
            return
        }
        // Already scheduled, or already delivered: don't nudge twice for one trip.
        guard defaults.object(forKey: Self.scheduledForKey) as? Date != date else { return }
        scheduler.schedule(.leftBehind, at: date)
        defaults.set(date, forKey: Self.scheduledForKey)
    }

    private func setSnoozed(until date: Date?) {
        snoozedUntil = date
        defaults.set(date, forKey: Self.snoozedUntilKey)
    }

    private func setDismissed(_ dismissed: Bool) {
        isDismissed = dismissed
        defaults.set(dismissed, forKey: Self.dismissedKey)
    }
}
