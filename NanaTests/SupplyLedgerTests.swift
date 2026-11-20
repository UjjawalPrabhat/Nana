import Foundation
import Testing
@testable import Nana

struct SupplyLedgerTests {
    @Test func countIsClampedToTheCharm() {
        #expect(SupplyLedger.clamped(10) == SupplyLedger.capacity)
        #expect(SupplyLedger.clamped(-3) == 0)
        #expect(SupplyLedger.clamped(2) == 2)
    }

    @Test(arguments: [
        (Optional(3), 1, true), (Optional(2), 1, true), (Optional(1), 0, false),
        (nil, 1, true), (nil, 2, false), (Optional(3), 2, false),
    ])
    func lowNudgeFiresOnlyWhenCrossingIntoLow(previous: Int?, current: Int, expected: Bool) {
        #expect(SupplyLedger.crossedIntoLow(from: previous, to: current) == expected)
    }

    @Test(arguments: [(0, SupplyLedger.Level.empty), (1, .low), (2, .stocked), (3, .full)])
    func levels(count: Int, expected: SupplyLedger.Level) {
        #expect(SupplyLedger.level(of: count) == expected)
    }
}
