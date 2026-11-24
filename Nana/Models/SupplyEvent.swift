import Foundation
import SwiftData

/// The Pod's latest reading. Only one is kept (see `ContainerStore.record`), so
/// there is no history of when condoms left the Pod.
@Model
final class SupplyEvent {
    nonisolated enum Kind: String, Codable, Sendable {
        /// The paired Pod reported `amount` items.
        case deviceReading
        // Created by earlier (TestFlight) builds and no longer made. Kept so their
        // stored events still decode; launch drops all but the newest anyway.
        /// A count set by hand.
        case adjust
        /// Items added by hand.
        case refill
    }

    var date: Date
    var kind: Kind
    var amount: Int

    init(date: Date = .now, kind: Kind, amount: Int) {
        self.date = date
        self.kind = kind
        self.amount = amount
    }

    /// Deletes every reading, one by one. SwiftData's bulk `delete(model:)` traps
    /// when the context has other changes pending or a live `@Query` is watching.
    static func deleteAll(in context: ModelContext) throws {
        try context.fetch(FetchDescriptor<SupplyEvent>()).forEach(context.delete)
    }

    /// Just the newest event: the latest reading is the current count.
    static let newestFirst = SortDescriptor<SupplyEvent>(\.date, order: .reverse)

    static var latest: FetchDescriptor<SupplyEvent> {
        var descriptor = FetchDescriptor<SupplyEvent>(sortBy: [newestFirst])
        descriptor.fetchLimit = 1
        return descriptor
    }
}
