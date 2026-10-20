import Foundation
import SwiftData

/// One change to the user's supply. The current count is never stored directly;
/// `SupplyLedger` derives it from this log, so every number on screen can say
/// where it came from ("Confirmed by you" vs "Reported by container").
@Model
final class SupplyEvent {
    nonisolated enum Kind: String, Codable, Sendable {
        /// The user added `amount` items.
        case refill
        /// The user set the count to exactly `amount`.
        case adjust
        /// The paired container reported `amount` items.
        case deviceReading

        var source: Source { self == .deviceReading ? .container : .user }
    }

    nonisolated enum Source: Sendable {
        case user
        case container
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
