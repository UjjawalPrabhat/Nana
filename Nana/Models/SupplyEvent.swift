import Foundation
import SwiftData

/// One change to the charm's count. The current count is never stored directly;
/// `SupplyLedger` derives it from this log, so Home can say where a number came
/// from ("Set by you" vs a live reading).
@Model
final class SupplyEvent {
    nonisolated enum Kind: String, Codable, Sendable {
        /// The user set the count to exactly `amount` with Fix count.
        case adjust
        /// The paired charm reported `amount` items.
        case deviceReading

        var source: Source { self == .deviceReading ? .charm : .user }
    }

    nonisolated enum Source: Sendable {
        case user
        case charm
    }

    var date: Date
    var kind: Kind
    var amount: Int

    init(date: Date = .now, kind: Kind, amount: Int) {
        self.date = date
        self.kind = kind
        self.amount = amount
    }
}
