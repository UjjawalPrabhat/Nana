import Foundation

/// What Home shows, worked out from the ledger, the charm's link and the
/// left-behind check. Pure, so every variant on the board has a test.
nonisolated struct HomeState: Equatable, Sendable {
    enum Variant: String, CaseIterable, Sendable {
        case full, stocked, low, empty, unknown, away
    }

    var variant: Variant
    /// The last count we know, or `nil` if there has never been one.
    var count: Int?
    /// When the shown count was last confirmed, for the status chip.
    var updatedAt: Date?
    var isPaired: Bool

    static func make(
        status: SupplyLedger.Status?,
        connection: ContainerConnection,
        isLeftBehind: Bool
    ) -> HomeState {
        let isPaired = connection != .notPaired
        func state(_ variant: Variant) -> HomeState {
            HomeState(variant: variant, count: status?.count, updatedAt: status?.updatedAt, isPaired: isPaired)
        }

        if isLeftBehind { return state(.away) }
        guard let status, connection == .connected else { return state(.unknown) }

        return switch SupplyLedger.level(of: status.count) {
        case .full: state(.full)
        case .stocked: state(.stocked)
        case .low: state(.low)
        case .empty: state(.empty)
        }
    }

    /// Stale counts are drawn in a softer ink.
    var isStale: Bool { variant == .unknown || variant == .away }

    var countText: String { count.map(String.init) ?? "–" }

    /// The charm shows striped slots when the count can't be trusted, and the
    /// last count (dimmed) when it's simply out of reach.
    var charmCount: Int? { variant == .unknown ? nil : count }

    var countLabel: LocalizedStringResource {
        switch variant {
        case .full: "in your charm.\nAll set."
        case .stocked, .empty: "left in\nyour charm"
        case .low: "left.\nRestock soon."
        case .unknown where count == nil: "nothing\ncounted yet"
        case .unknown, .away: "last we\nknew"
        }
    }

    var statusText: LocalizedStringResource {
        let time = updatedAt?.formatted(date: .omitted, time: .shortened)
        switch variant {
        case .away:
            return "Out of range"
        case .unknown:
            if !isPaired { return "No charm paired" }
            guard let time else { return "Not connected yet" }
            return "Not updated since \(time)"
        case .full, .stocked, .low, .empty:
            return "Connected, just now"
        }
    }

    var note: LocalizedStringResource? {
        switch variant {
        case .low: "Running low"
        case .empty: "Restock before you head out"
        default: nil
        }
    }
}

#if DEBUG
extension HomeState {
    /// The board's example for each variant.
    static func sample(_ variant: Variant) -> HomeState {
        let counts: [Variant: Int] = [.full: 3, .stocked: 2, .low: 1, .empty: 0, .unknown: 2, .away: 2]
        return HomeState(variant: variant, count: counts[variant], updatedAt: .now.addingTimeInterval(-3600),
                         isPaired: true)
    }

    /// `-NanaHomeVariant away` shows that variant, for screenshots.
    static var launchArgumentSample: HomeState? {
        UserDefaults.standard.string(forKey: "NanaHomeVariant").flatMap(Variant.init).map(sample)
    }
}
#endif
