import Foundation
import Testing
@testable import Nana

struct HomeStateTests {
    private func status(_ count: Int, _ source: SupplyEvent.Source = .charm) -> SupplyLedger.Status {
        SupplyLedger.Status(count: count, updatedAt: Date(timeIntervalSince1970: 1_000_000), source: source)
    }

    @Test(arguments: [(3, HomeState.Variant.full), (2, .stocked), (1, .low), (0, .empty)])
    func connectedCountsMapToTheBoard(count: Int, expected: HomeState.Variant) {
        let state = HomeState.make(status: status(count), connection: .connected, isLeftBehind: false)
        #expect(state.variant == expected)
        #expect(state.count == count)
        #expect(!state.isStale)
    }

    @Test func readingFromAnOutOfRangeCharmIsUnknown() {
        let state = HomeState.make(status: status(2), connection: .disconnected, isLeftBehind: false)
        #expect(state.variant == .unknown)
        #expect(state.count == 2)
        #expect(state.charmCount == nil)
        #expect(state.isStale)
    }

    @Test func aFixedCountIsTrustedWithoutTheCharm() {
        let state = HomeState.make(status: status(1, .user), connection: .disconnected, isLeftBehind: false)
        #expect(state.variant == .low)
    }

    @Test func nothingRecordedYetIsUnknown() {
        let state = HomeState.make(status: nil, connection: .notPaired, isLeftBehind: false)
        #expect(state.variant == .unknown)
        #expect(state.countText == "–")
        #expect(!state.isPaired)
    }

    @Test func leftBehindWinsAndKeepsTheLastCount() {
        let state = HomeState.make(status: status(2), connection: .disconnected, isLeftBehind: true)
        #expect(state.variant == .away)
        #expect(state.charmCount == 2)
        #expect(state.isStale)
    }

    @Test func onlyLowAndEmptyCarryANote() {
        for variant in HomeState.Variant.allCases {
            let state = HomeState(variant: variant, count: 1, updatedAt: nil, source: .charm, isPaired: true)
            #expect((state.note != nil) == (variant == .low || variant == .empty))
        }
    }
}
