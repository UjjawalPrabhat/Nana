import Foundation
import SwiftData

/// App-wide state for the paired container. Turns stock readings into
/// `SupplyEvent`s so Home shows them like any other count change.
@Observable
final class ContainerStore {
    private(set) var connection: ContainerConnection = .notPaired
    private(set) var battery: Int?
    private(set) var firmware: String?
    private(set) var capacity = SupplyLedger.capacity
    private(set) var lastReading: StockReading?
    private(set) var lastSeen: Date?
    private(set) var usesDemo: Bool

    var isPaired: Bool { connection != .notPaired }
    var demo: DemoContainerTransport? { transport as? DemoContainerTransport }

    @ObservationIgnored private var transport: ContainerTransport
    @ObservationIgnored private let modelContext: ModelContext
    @ObservationIgnored private let defaults: UserDefaults

    private static let useDemoKey = "useDemoContainer"
    private static let lastSeenKey = "container.lastSeen"

    init(modelContext: ModelContext, defaults: UserDefaults = .standard, forceDemo: Bool? = nil) {
        self.modelContext = modelContext
        self.defaults = defaults
        let usesDemo = forceDemo ?? (defaults.object(forKey: Self.useDemoKey) as? Bool ?? Self.isSimulator)
        self.usesDemo = usesDemo
        self.transport = usesDemo ? DemoContainerTransport(defaults: defaults) : BLEContainerTransport()
        self.lastSeen = defaults.object(forKey: Self.lastSeenKey) as? Date
        attachTransport()
    }

    func start() {
        transport.start()
    }

    /// Shows the pairing UI. Returns `true` if a container was paired.
    func pair() async throws -> Bool {
        try await transport.pair()
    }

    func forget() async throws {
        try await transport.forget()
        battery = nil
        firmware = nil
        lastReading = nil
    }

    func identify() {
        transport.send(.identify)
    }

    func setUsesDemo(_ usesDemo: Bool) {
        guard usesDemo != self.usesDemo else { return }
        defaults.set(usesDemo, forKey: Self.useDemoKey)
        transport.onEvent = nil
        self.usesDemo = usesDemo
        transport = usesDemo ? DemoContainerTransport(defaults: defaults) : BLEContainerTransport()
        connection = .notPaired
        battery = nil
        firmware = nil
        lastReading = nil
        attachTransport()
        transport.start()
    }

    // MARK: Events

    private func attachTransport() {
        transport.onEvent = { [weak self] event in
            self?.handle(event)
        }
    }

    private func handle(_ event: ContainerEvent) {
        switch event {
        case .connection(let state):
            connection = state
            if state == .connected { markSeen() }
        case .stock(let reading):
            markSeen()
            lastReading = reading
            record(reading)
        case .capacity(let value):
            capacity = value
        case .battery(let value):
            battery = value
        case .firmware(let value):
            firmware = value
        }
    }

    private func record(_ reading: StockReading) {
        guard !reading.lidOpen, let count = reading.estimatedCount(capacity: capacity) else { return }
        let entries = (try? modelContext.fetch(FetchDescriptor<SupplyEvent>()))?.map(\.ledgerEntry) ?? []
        let previous = SupplyLedger.status(for: entries)
        // Reconnects re-send the same reading; only log real changes.
        guard previous?.count != count else { return }
        modelContext.insert(SupplyEvent(kind: .deviceReading, amount: count, source: .container))
        try? modelContext.save()
        LowSupplyReminder.supplyChanged(from: previous?.count, to: count, defaults: defaults)
    }

    private func markSeen() {
        lastSeen = .now
        defaults.set(lastSeen, forKey: Self.lastSeenKey)
    }

    private static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }
}

extension ContainerStore {
    /// In-memory store with a demo container, for previews.
    static func preview(paired: Bool = true) -> ContainerStore {
        let container = try! ModelContainer(
            for: SupplyEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let defaults = UserDefaults(suiteName: "preview.\(UUID().uuidString)")!
        defaults.set(paired, forKey: "demoContainer.paired")
        let store = ContainerStore(modelContext: container.mainContext, defaults: defaults, forceDemo: true)
        store.start()
        return store
    }
}
