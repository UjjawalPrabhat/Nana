import Foundation
@testable import Nana

/// Notes every nudge scheduled or cancelled instead of sending it.
final class RecordingScheduler: NudgeScheduling {
    private(set) var scheduled: [(nudge: Nudge, date: Date)] = []
    private(set) var cancels = 0

    func schedule(_ nudge: Nudge, at date: Date) { scheduled.append((nudge, date)) }
    func cancel(_ nudge: Nudge) { cancels += 1 }
}
