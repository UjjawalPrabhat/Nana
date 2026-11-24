import Foundation

/// Pure supply rules. Kept free of SwiftData and SwiftUI so it can be unit tested.
nonisolated enum SupplyLedger {
    /// Slots in the Pod.
    static let capacity = 3
    /// "Running low" means one left.
    static let lowThreshold = 1

    struct Status: Equatable, Sendable {
        var count: Int
        var updatedAt: Date
    }

    enum Level: Sendable {
        case empty
        case low
        case stocked
        case full
    }

    /// Keeps a count within what the Pod can hold.
    static func clamped(_ count: Int) -> Int {
        min(max(count, 0), capacity)
    }

    /// True when the count has just dropped to "running low", so the nudge is sent
    /// once and not again on every reading after that.
    static func crossedIntoLow(from previous: Int?, to current: Int) -> Bool {
        guard current <= lowThreshold else { return false }
        guard let previous else { return true }
        return previous > lowThreshold
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
    var status: SupplyLedger.Status {
        SupplyLedger.Status(count: SupplyLedger.clamped(amount), updatedAt: date)
    }
}
