import Foundation
import Testing
@testable import Nana

struct SupplyLedgerTests {
    private let start = Date(timeIntervalSince1970: 1_000_000)

    private func entry(_ minutes: Double, _ kind: SupplyEvent.Kind, _ amount: Int) -> SupplyLedger.Entry {
        .init(date: start.addingTimeInterval(minutes * 60), kind: kind, amount: amount)
    }

    @Test func noEventsMeansNoStatus() {
        #expect(SupplyLedger.status(for: []) == nil)
    }

    @Test func latestEntryWinsAndCarriesSource() {
        let status = SupplyLedger.status(for: [entry(0, .deviceReading, 3), entry(1, .adjust, 1)])
        #expect(status?.count == 1)
        #expect(status?.source == .user)
    }

    @Test func eventsAreOrderedByDateNotInsertion() {
        let status = SupplyLedger.status(for: [entry(5, .deviceReading, 2), entry(0, .adjust, 3)])
        #expect(status?.count == 2)
        #expect(status?.source == .charm)
        #expect(status?.updatedAt == start.addingTimeInterval(300))
    }

    @Test func countIsClampedToTheCharm() {
        #expect(SupplyLedger.status(for: [entry(0, .adjust, 10)])?.count == SupplyLedger.capacity)
        #expect(SupplyLedger.status(for: [entry(0, .adjust, -3)])?.count == 0)
    }

    @Test(arguments: [(0, SupplyLedger.Level.empty), (1, .low), (2, .stocked), (3, .full)])
    func levels(count: Int, expected: SupplyLedger.Level) {
        #expect(SupplyLedger.level(of: count) == expected)
    }
}
