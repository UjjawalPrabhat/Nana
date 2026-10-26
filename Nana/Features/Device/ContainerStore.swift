import Foundation
import SwiftData

/// App-wide state for the paired charm. Turns stock readings into
/// `SupplyEvent`s so Home shows them like any other count change, and tracks
/// when the charm went out of range for the left-behind nudge.
@Observable
final class ContainerStore {
    private(set) var connection: ContainerConnection = .notPaired
    private(set) var battery: Int?
    private(set) var firmware: String?
    private(set) var capacity = SupplyLedger.capacity
    private(set) var lastReading: StockReading?
    private(set) var lastSeen: Date?
    /// When the charm went out of range. `nil` while connected, and while
    /// Bluetooth is off so nudges pause.
    private(set) var disconnectedSince: Date? {
        didSet {
            defaults.set(disconnectedSince, forKey: Self.disconnectedSinceKey)
            if disconnectedSince != oldValue { onLinkChange?(disconnectedSince) }
        }
    }
    private(set) var usesDemo: Bool

    /// Called whenever `disconnectedSince` changes.
    @ObservationIgnored var onLinkChange: ((Date?) -> Void)?

    var isPaired: Bool { connection != .notPaired }
    var demo: DemoContainerTransport? { transport as? DemoContainerTransport }

    @ObservationIgnored private var transport: ContainerTransport
    @ObservationIgnored private let modelContext: ModelContext
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let nudges: NudgeScheduling

    private static let useDemoKey = "useDemoContainer"
    private static let lastSeenKey = "container.lastSeen"
    private static let disconnectedSinceKey = "container.disconnectedSince"

    init(
        modelContext: ModelContext,
        nudges: NudgeScheduling,
        defaults: UserDefaults = .standard,
        forceDemo: Bool? = nil
    ) {
        self.modelContext = modelContext
        self.nudges = nudges
        self.defaults = defaults
        let usesDemo = forceDemo ?? (defaults.object(forKey: Self.useDemoKey) as? Bool ?? Self.isSimulator)
        self.usesDemo = usesDemo
        self.transport = Self.makeTransport(demo: usesDemo, defaults: defaults)
        self.lastSeen = defaults.object(forKey: Self.lastSeenKey) as? Date
        self.disconnectedSince = defaults.object(forKey: Self.disconnectedSinceKey) as? Date
        attachTransport()
    }

    func start() {
        transport.start()
    }

    /// Shows the pairing UI. Returns `true` if a charm was paired.
    func pair() async throws -> Bool {
        try await transport.pair()
    }

    func forget() async throws {
        try await transport.forget()
        clearDeviceInfo()
    }

    func reconnect() {
        transport.reconnect()
    }

    func identify() {
        transport.send(.identify)
    }

    func setUsesDemo(_ usesDemo: Bool) {
        guard usesDemo != self.usesDemo else { return }
        defaults.set(usesDemo, forKey: Self.useDemoKey)
        transport.onEvent = nil
        self.usesDemo = usesDemo
        transport = Self.makeTransport(demo: usesDemo, defaults: defaults)
        connection = .notPaired
        clearDeviceInfo()
        attachTransport()
        transport.start()
    }

    private static func makeTransport(demo: Bool, defaults: UserDefaults) -> ContainerTransport {
        demo ? DemoContainerTransport(defaults: defaults) : BLEContainerTransport()
    }

    private func clearDeviceInfo() {
        battery = nil
        firmware = nil
        lastReading = nil
        disconnectedSince = nil
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
            switch state {
            case .connected:
                markSeen()
                disconnectedSince = nil
            case .disconnected:
                if disconnectedSince == nil { disconnectedSince = .now }
            case .notPaired, .unavailable:
                disconnectedSince = nil
            case .connecting:
                break
            }
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
        guard previous?.count != count || previous?.source == .user else { return }
        modelContext.insert(SupplyEvent(kind: .deviceReading, amount: count))
        try? modelContext.save()
        if defaults.bool(forKey: AppSettings.lowSupplyNudgeOn),
           LowSupplyReminder.shouldNotify(previous: previous?.count, current: count) {
            nudges.schedule(.lowSupply, at: .now)
        }
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

#if DEBUG
extension ContainerStore {
    /// In-memory store with a demo charm, for previews.
    static func preview(paired: Bool = true) -> ContainerStore {
        let container = try! ModelContainer(
            for: SupplyEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let defaults = UserDefaults(suiteName: "preview.\(UUID().uuidString)")!
        defaults.set(paired, forKey: DemoContainerTransport.pairedKey)
        let store = ContainerStore(
            modelContext: container.mainContext,
            nudges: SilentNudgeScheduler(),
            defaults: defaults,
            forceDemo: true
        )
        store.start()
        return store
    }
}
#endif
