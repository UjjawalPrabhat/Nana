import Foundation
import Testing
@testable import Nana

struct LeftBehindRulesTests {
    private let since = Date(timeIntervalSince1970: 1_000_000)

    private func input(
        disconnected: Bool = true,
        snoozedUntil: Date? = nil,
        dismissed: Bool = false
    ) -> LeftBehindRules.Input {
        .init(disconnectedSince: disconnected ? since : nil, wait: 120,
              snoozedUntil: snoozedUntil, isDismissed: dismissed)
    }

    @Test func nudgesAfterTheWait() {
        #expect(LeftBehindRules.nudgeDate(for: input()) == since.addingTimeInterval(120))
        #expect(!LeftBehindRules.isLeftBehind(input(), now: since.addingTimeInterval(119)))
        #expect(LeftBehindRules.isLeftBehind(input(), now: since.addingTimeInterval(120)))
    }

    @Test func staysQuietWhileConnectedOrDismissed() {
        #expect(LeftBehindRules.nudgeDate(for: input(disconnected: false)) == nil)
        #expect(LeftBehindRules.nudgeDate(for: input(dismissed: true)) == nil)
    }

    @Test func snoozeMovesTheNudgeButNotTheState() {
        let later = since.addingTimeInterval(900)
        #expect(LeftBehindRules.nudgeDate(for: input(snoozedUntil: later)) == later)
        #expect(LeftBehindRules.isLeftBehind(input(snoozedUntil: later), now: since.addingTimeInterval(300)))
    }

    @Test func bluetoothOffPausesTheNudge() {
        var paused = input()
        paused.isPaused = true
        #expect(LeftBehindRules.nudgeDate(for: paused) == nil)
        #expect(!LeftBehindRules.isLeftBehind(paused, now: since.addingTimeInterval(600)))
    }

    @Test func snoozeEndingBeforeTheWaitIsIgnored() {
        let early = since.addingTimeInterval(30)
        #expect(LeftBehindRules.nudgeDate(for: input(snoozedUntil: early)) == since.addingTimeInterval(120))
    }
}

@MainActor
final class LeftBehindNudgeTests {
    private let now = Date(timeIntervalSince1970: 2_000_000)
    private let scheduler = RecordingScheduler()
    private let suiteName = "tests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    /// Moved forward by tests that need the nudge to have gone off already.
    private var clock: Date

    init() {
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.register(defaults: AppSettings.defaults)
        defaults.set(true, forKey: AppSettings.leftBehindNudgeOn)
        clock = now
    }

    deinit {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    private func makeNudge() -> LeftBehindNudge {
        LeftBehindNudge(scheduler: scheduler, defaults: defaults, now: { [unowned self] in clock })
    }

    /// Out of range long enough for the nudge (due at +2 min) to have gone off.
    private func makeNudgeThatAlreadyWentOff() -> LeftBehindNudge {
        let nudge = makeNudge()
        nudge.charmLinkChanged(disconnectedSince: now)
        clock = now.addingTimeInterval(600)
        return nudge
    }

    @Test func schedulesOnceForOneTrip() {
        let nudge = makeNudge()
        nudge.charmLinkChanged(disconnectedSince: now)
        nudge.reschedule()
        #expect(scheduler.scheduled.map(\.date) == [now.addingTimeInterval(120)])
    }

    @Test func reconnectingEndsTheTrip() {
        let nudge = makeNudge()
        nudge.charmLinkChanged(disconnectedSince: now)
        nudge.leftOnPurpose()
        nudge.charmLinkChanged(disconnectedSince: nil)
        #expect(!nudge.isDismissed)
        #expect(nudge.snoozedUntil == nil)
    }

    @Test func snoozeReschedulesFifteenMinutesOut() {
        let nudge = makeNudge()
        nudge.charmLinkChanged(disconnectedSince: now)
        nudge.snooze()
        #expect(scheduler.scheduled.last?.date == now.addingTimeInterval(LeftBehindRules.snoozeLength))
    }

    @Test func bluetoothOffKeepsTheTripAndItsSnooze() {
        let nudge = makeNudge()
        nudge.charmLinkChanged(disconnectedSince: now)
        nudge.snooze()
        nudge.bluetoothAvailabilityChanged(isAvailable: false)
        #expect(scheduler.cancels == 1)
        #expect(!nudge.isLeftBehind(at: now.addingTimeInterval(600)))
        nudge.bluetoothAvailabilityChanged(isAvailable: true)
        #expect(nudge.snoozedUntil == now.addingTimeInterval(LeftBehindRules.snoozeLength))
        #expect(nudge.isLeftBehind(at: now.addingTimeInterval(600)))
    }

    @Test func raisingTheWaitAfterTheNudgeDoesNotRepeatIt() {
        let nudge = makeNudgeThatAlreadyWentOff()
        defaults.set(5, forKey: AppSettings.leftBehindWaitMinutes)
        nudge.reschedule()
        #expect(scheduler.scheduled.count == 1)
    }

    @Test func bluetoothOffAndOnAfterTheNudgeDoesNotRepeatIt() {
        let nudge = makeNudgeThatAlreadyWentOff()
        nudge.bluetoothAvailabilityChanged(isAvailable: false)
        nudge.bluetoothAvailabilityChanged(isAvailable: true)
        #expect(scheduler.scheduled.count == 1)
    }

    @Test func snoozingAfterTheNudgeStillNudgesAgain() {
        let nudge = makeNudgeThatAlreadyWentOff()
        nudge.snooze()
        #expect(scheduler.scheduled.map(\.date).last == clock.addingTimeInterval(LeftBehindRules.snoozeLength))
    }

    @Test func discreetChangeRewritesOnlyAPendingNudge() {
        let nudge = makeNudge()
        nudge.charmLinkChanged(disconnectedSince: now)
        nudge.refreshPendingText()
        #expect(scheduler.scheduled.map(\.date) == Array(repeating: now.addingTimeInterval(120), count: 2))

        clock = now.addingTimeInterval(600)
        nudge.refreshPendingText()
        #expect(scheduler.scheduled.count == 2)
    }

    @Test func switchedOffNeverSchedules() {
        defaults.set(false, forKey: AppSettings.leftBehindNudgeOn)
        let nudge = makeNudge()
        nudge.charmLinkChanged(disconnectedSince: now)
        #expect(scheduler.scheduled.isEmpty)
    }
}
