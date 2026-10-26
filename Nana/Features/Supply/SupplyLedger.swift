import Foundation

/// Pure supply rules. Kept free of SwiftData and SwiftUI so it can be unit tested.
nonisolated enum SupplyLedger {
    /// Slots in the charm.
    static let capacity = 3
    /// "Running low" means one left.
    static let lowThreshold = 1

    struct Entry: Equatable, Sendable {
        var date: Date
        var kind: SupplyEvent.Kind
        var amount: Int
    }

    struct Status: Equatable, Sendable {
        var count: Int
        var updatedAt: Date
        var source: SupplyEvent.Source
    }

    enum Level: Equatable, Sendable {
        case empty
        case low
        case stocked
        case full
    }

    /// The latest entry wins. Returns `nil` when nothing has been recorded yet.
    static func status(for entries: [Entry]) -> Status? {
        entries.max { $0.date < $1.date }.map {
            Status(count: min(max($0.amount, 0), capacity), updatedAt: $0.date, source: $0.kind.source)
        }
    }

    static func level(of count: Int) -> Level {
        switch count {
        case ...0: .empty
        case ...lowThreshold: .low
        case capacity...: .full
        default: .stocked
        }
    }
}

extension SupplyEvent {
    var ledgerEntry: SupplyLedger.Entry {
        SupplyLedger.Entry(date: date, kind: kind, amount: amount)
    }
}
