import Foundation

/// Pure supply rules. Kept free of SwiftData and SwiftUI so it can be unit tested.
nonisolated enum SupplyLedger {
    /// How many items the container holds. Update once the hardware is final.
    static let capacity = 12

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
        case notSet
        case empty
        case low
        case available
    }

    /// Replays the log in date order. Returns `nil` when nothing has been recorded yet.
    static func status(for entries: [Entry]) -> Status? {
        var status: Status?
        for entry in entries.sorted(by: { $0.date < $1.date }) {
            let count = switch entry.kind {
            case .refill: (status?.count ?? 0) + entry.amount
            case .adjust, .deviceReading: entry.amount
            }
            status = Status(count: min(max(count, 0), capacity), updatedAt: entry.date, source: entry.kind.source)
        }
        return status
    }

    static func level(of status: Status?, lowThreshold: Int) -> Level {
        guard let status else { return .notSet }
        if status.count == 0 { return .empty }
        if status.count <= lowThreshold { return .low }
        return .available
    }

    /// The most a refill can add without overflowing the container.
    static func maxRefill(currentCount: Int) -> Int {
        max(0, capacity - currentCount)
    }
}

extension SupplyEvent {
    var ledgerEntry: SupplyLedger.Entry {
        SupplyLedger.Entry(date: date, kind: kind, amount: amount)
    }
}
