import Foundation
import Testing
@testable import Nana

struct NudgesTests {
    @Test(arguments: [Nudge.leftBehind, .lowSupply], [false, true])
    func lockScreenTextNeverSaysWhatsInTheCharm(nudge: Nudge, discreet: Bool) {
        let text = nudge.text(discreet: discreet)
        #expect(!"\(text.title) \(text.body)".localizedCaseInsensitiveContains("condom"))
    }

    @Test func discreetTextIsTheSameForEveryNudge() {
        #expect(Nudge.leftBehind.text(discreet: true) == Nudge.lowSupply.text(discreet: true))
    }

    @Test func nudgesStartOffUntilTheUserAgrees() {
        #expect(AppSettings.defaults[AppSettings.leftBehindNudgeOn] as? Bool == false)
        #expect(AppSettings.defaults[AppSettings.lowSupplyNudgeOn] as? Bool == false)
    }
}
