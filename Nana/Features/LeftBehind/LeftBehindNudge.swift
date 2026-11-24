import Foundation

/// Keeps the left-behind nudge scheduled for the right moment. The Pod's
/// link is pushed in by the app; this only decides.
@Observable
final class LeftBehindNudge {
    private(set) var disconnectedSince: Date?
    private(set) var isBluetoothOff = false
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
            isPaused: isBluetoothOff,
            wait: TimeInterval(defaults.integer(forKey: AppSettings.leftBehindWaitMinutes) * 60),
            snoozedUntil: snoozedUntil,
            isDismissed: isDismissed
        )
    }

    /// When the nudge is due for this trip, or `nil` if none is.
    var nextNudgeDate: Date? { LeftBehindRules.nudgeDate(for: input) }

    /// What was last handed to the notification scheduler.
    var scheduledFor: Date? { defaults.object(forKey: Self.scheduledForKey) as? Date }

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

    /// Bluetooth off pauses nudges without ending the trip.
    func bluetoothAvailabilityChanged(isAvailable: Bool) {
        guard isBluetoothOff == isAvailable else { return }
        isBluetoothOff = !isAvailable
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
        guard defaults.bool(forKey: AppSettings.leftBehindNudgeOn), let date = nextNudgeDate else {
            scheduler.cancel(.leftBehind)
            // A nudge that already went off is remembered until the trip ends, so
            // pausing (Bluetooth off) and resuming doesn't send it again.
            if disconnectedSince == nil || (scheduledFor.map { $0 > now() } ?? true) {
                defaults.removeObject(forKey: Self.scheduledForKey)
            }
            return
        }
        let previous = scheduledFor
        guard previous != date else { return }
        // One nudge per trip: once it has gone off, only a snooze brings it back.
        if let previous, previous <= now(), date != snoozedUntil { return }
        scheduler.schedule(.leftBehind, at: date)
        defaults.set(date, forKey: Self.scheduledForKey)
    }

    /// Re-sends a nudge that hasn't gone off yet, so its text follows the
    /// Discreet setting. The notification is replaced, not added.
    func refreshPendingText() {
        guard let date = scheduledFor, date > now() else { return }
        scheduler.schedule(.leftBehind, at: date)
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
