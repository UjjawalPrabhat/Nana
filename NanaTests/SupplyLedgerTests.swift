import Foundation
import Testing
@testable import Nana

struct SupplyLedgerTests {
    private let start = Date(timeIntervalSince1970: 1_000_000)

    private func entry(_ minutes: Double, _ kind: SupplyEvent.Kind, _ amount: Int) -> SupplyLedger.Entry {
        .init(date: start.addingTimeInterval(minutes * 60), kind: kind, amount: amount)
    }

    @Test func noEventsMeansNotSet() {
        #expect(SupplyLedger.status(for: []) == nil)
        #expect(SupplyLedger.level(of: nil, lowThreshold: 2) == .notSet)
    }

    @Test func refillsAddOnTopOfAdjustments() {
        let status = SupplyLedger.status(for: [entry(0, .adjust, 2), entry(1, .refill, 3)])
        #expect(status?.count == 5)
        #expect(status?.source == .user)
    }

    @Test func refillFromNothingStartsAtZero() {
        #expect(SupplyLedger.status(for: [entry(0, .refill, 4)])?.count == 4)
    }

    @Test func eventsAreReplayedInDateOrderNotInsertionOrder() {
        let status = SupplyLedger.status(for: [entry(5, .refill, 1), entry(0, .adjust, 6)])
        #expect(status?.count == 7)
        #expect(status?.updatedAt == start.addingTimeInterval(300))
    }

    @Test func deviceReadingOverridesAndCarriesSource() {
        let status = SupplyLedger.status(for: [entry(0, .adjust, 10), entry(1, .deviceReading, 3)])
        #expect(status?.count == 3)
        #expect(status?.source == .container)
    }

    @Test func countIsClampedToCapacity() {
        let status = SupplyLedger.status(for: [entry(0, .adjust, 10), entry(1, .refill, 10)])
        #expect(status?.count == SupplyLedger.capacity)
        #expect(SupplyLedger.status(for: [entry(0, .adjust, -3)])?.count == 0)
    }

    @Test(arguments: [(0, SupplyLedger.Level.empty), (1, .low), (2, .low), (3, .available)])
    func levels(count: Int, expected: SupplyLedger.Level) {
        let status = SupplyLedger.Status(count: count, updatedAt: start, source: .user)
        #expect(SupplyLedger.level(of: status, lowThreshold: 2) == expected)
    }

    @Test func maxRefillNeverNegative() {
        #expect(SupplyLedger.maxRefill(currentCount: 4) == 8)
        #expect(SupplyLedger.maxRefill(currentCount: 12) == 0)
        #expect(SupplyLedger.maxRefill(currentCount: 20) == 0)
    }
}
