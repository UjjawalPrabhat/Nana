import Foundation
import Testing
@testable import Nana

struct LeftBehindRulesTests {
    private let since = Date(timeIntervalSince1970: 1_000_000)

    private func input(
        disconnected: Bool = true,
        inside: Bool = false,
        snoozedUntil: Date? = nil,
        dismissed: Bool = false
    ) -> LeftBehindRules.Input {
        .init(disconnectedSince: disconnected ? since : nil, isInsidePlace: inside, wait: 120,
              snoozedUntil: snoozedUntil, isDismissed: dismissed)
    }

    @Test func nudgesAfterTheWait() {
        #expect(LeftBehindRules.nudgeDate(for: input()) == since.addingTimeInterval(120))
        #expect(!LeftBehindRules.isLeftBehind(input(), now: since.addingTimeInterval(119)))
        #expect(LeftBehindRules.isLeftBehind(input(), now: since.addingTimeInterval(120)))
    }

    @Test func staysQuietWhileConnectedInsideAPlaceOrDismissed() {
        #expect(LeftBehindRules.nudgeDate(for: input(disconnected: false)) == nil)
        #expect(LeftBehindRules.nudgeDate(for: input(inside: true)) == nil)
        #expect(LeftBehindRules.nudgeDate(for: input(dismissed: true)) == nil)
    }

    @Test func snoozeMovesTheNudgeButNotTheState() {
        let later = since.addingTimeInterval(900)
        #expect(LeftBehindRules.nudgeDate(for: input(snoozedUntil: later)) == later)
        #expect(LeftBehindRules.isLeftBehind(input(snoozedUntil: later), now: since.addingTimeInterval(300)))
    }

    @Test func snoozeEndingBeforeTheWaitIsIgnored() {
        let early = since.addingTimeInterval(30)
        #expect(LeftBehindRules.nudgeDate(for: input(snoozedUntil: early)) == since.addingTimeInterval(120))
    }
}

@MainActor
struct LeftBehindNudgeTests {
    private final class RecordingScheduler: NudgeScheduling {
        var scheduled: [Date] = []
        var cancels = 0
        func schedule(_ nudge: Nudge, at date: Date) { scheduled.append(date) }
        func cancel(_ nudge: Nudge) { cancels += 1 }
    }

    private let now = Date(timeIntervalSince1970: 2_000_000)
    private let scheduler = RecordingScheduler()
    private let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: "tests.\(UUID().uuidString)")!
        defaults.register(defaults: AppSettings.defaults)
    }

    private func makeNudge() -> LeftBehindNudge {
        LeftBehindNudge(scheduler: scheduler, defaults: defaults, now: { [now] in now })
    }

    @Test func schedulesOnceForOneTrip() {
        let nudge = makeNudge()
        nudge.charmLinkChanged(disconnectedSince: now)
        nudge.placeChanged(isInside: false)
        nudge.reschedule()
        #expect(scheduler.scheduled == [now.addingTimeInterval(120)])
    }

    @Test func enteringAPlaceCancels() {
        let nudge = makeNudge()
        nudge.charmLinkChanged(disconnectedSince: now)
        nudge.placeChanged(isInside: true)
        #expect(scheduler.cancels == 1)
        #expect(!nudge.isLeftBehind(at: now.addingTimeInterval(600)))
    }

    @Test func leavingAPlaceLaterNudgesForTheOldDisconnect() {
        let nudge = makeNudge()
        nudge.placeChanged(isInside: true)
        nudge.charmLinkChanged(disconnectedSince: now)
        nudge.placeChanged(isInside: false)
        #expect(scheduler.scheduled == [now.addingTimeInterval(120)])
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
        #expect(scheduler.scheduled.last == now.addingTimeInterval(LeftBehindRules.snoozeLength))
    }

    @Test func switchedOffNeverSchedules() {
        defaults.set(false, forKey: AppSettings.leftBehindNudgeOn)
        let nudge = makeNudge()
        nudge.charmLinkChanged(disconnectedSince: now)
        #expect(scheduler.scheduled.isEmpty)
    }
}
