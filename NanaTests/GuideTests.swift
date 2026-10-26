import Testing
@testable import Nana

struct GuideTests {
    @Test func bananaShowsEveryStep() {
        #expect(GuideStep.steps(for: .banana).count == 8)
    }

    @Test func eggplantSkipsTheForeskinStep() {
        let steps = GuideStep.steps(for: .eggplant)
        #expect(steps.count == 7)
        #expect(!steps.contains { $0.illustration == .peel })
    }

    @Test func stepsStayInOrder() {
        #expect(GuideStep.steps(for: .banana).map(\.illustration) == [
            .check, .tear, .side, .peel, .pinch, .roll, .after, .lube,
        ])
    }
}
