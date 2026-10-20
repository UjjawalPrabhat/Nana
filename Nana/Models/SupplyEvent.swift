import Foundation
import SwiftData

/// One change to the user's supply. The current count is never stored directly;
/// it is derived from this log by `SupplyLedger`, so every number on screen can
/// say where it came from ("Confirmed by you" vs "Reported by container").
@Model
final class SupplyEvent {
    nonisolated enum Kind: String, Codable, Sendable {
        /// The user added `amount` items.
        case refill
        /// The user set the count to exactly `amount`.
        case adjust
        /// The paired container reported `amount` items.
        case deviceReading
    }

    nonisolated enum Source: String, Codable, Sendable {
        case user
        case container
    }

    var date: Date
    var kind: Kind
    var amount: Int
    var source: Source

    init(date: Date = .now, kind: Kind, amount: Int, source: Source = .user) {
        self.date = date
        self.kind = kind
        self.amount = amount
        self.source = source
    }
}
