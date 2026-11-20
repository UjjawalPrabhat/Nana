import Foundation
import OSLog
import SwiftData

/// App-wide state for the paired charm. Records stock readings as
/// `SupplyEvent`s and tracks when the charm went out of range for the
/// left-behind nudge.
@Observable
final class ContainerStore {
    private(set) var connection: ContainerConnection = .notPaired
    private(set) var battery: Int?
    /// When the charm went out of range. `nil` while connected or not paired.
    /// Bluetooth turning off doesn't change it; see `onAvailabilityChange`.
    private(set) var disconnectedSince: Date? {
        didSet {
            guard disconnectedSince != oldValue else { return }
            defaults.set(disconnectedSince, forKey: Self.disconnectedSinceKey)
            onLinkChange?(disconnectedSince)
        }
    }
    private(set) var usesDemo: Bool

    /// Called whenever `disconnectedSince` changes.
    @ObservationIgnored var onLinkChange: ((Date?) -> Void)?
    /// Called with `false` while Bluetooth is off, so nudges pause.
    @ObservationIgnored var onAvailabilityChange: ((Bool) -> Void)?

    var isPaired: Bool { connection != .notPaired }
    var demo: DemoContainerTransport? { transport as? DemoContainerTransport }
    /// The demo charm is paired and should be labelled as such (not while taking
    /// App Store screenshots, where it stands in for a real one).
    var isDemoRunning: Bool { usesDemo && isPaired && !AppSettings.isTakingScreenshots }

    @ObservationIgnored private var transport: ContainerTransport
    @ObservationIgnored private let modelContext: ModelContext
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let nudges: NudgeScheduling
    /// What the charm reports it holds; only used to turn a fill level into a count.
    @ObservationIgnored private var capacity = SupplyLedger.capacity

    private static let useDemoKey = "useDemoContainer"
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
        // `bool(forKey:)` also reads "YES"/"NO" from launch arguments.
        let usesDemo = forceDemo ?? (defaults.object(forKey: Self.useDemoKey) != nil
            ? defaults.bool(forKey: Self.useDemoKey) : Self.isSimulator)
        self.usesDemo = usesDemo
        self.transport = Self.makeTransport(demo: usesDemo, defaults: defaults)
        self.disconnectedSince = defaults.object(forKey: Self.disconnectedSinceKey) as? Date
        attachTransport()
        keepOnlyLatestReading()
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

    /// Switches to the built-in demo charm and pairs it, so the app can be tried
    /// (and reviewed) without hardware.
    func startDemo() async {
        setUsesDemo(true)
        _ = try? await transport.pair()
    }

    /// Leaves the demo. Its made-up count is deleted so it can't pass for a real one.
    func stopDemo() async {
        try? await transport.forget()
        setUsesDemo(false)
        try? SupplyEvent.deleteAll(in: modelContext)
        try? modelContext.save()
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
            onAvailabilityChange?(state != .unavailable)
            switch state {
            case .connected, .notPaired:
                disconnectedSince = nil
            case .disconnected:
                if disconnectedSince == nil { disconnectedSince = .now }
            case .unavailable, .connecting:
                break
            }
        case .stock(let reading):
            record(reading)
        case .capacity(let value):
            capacity = value
        case .battery(let value):
            battery = value
        }
    }

    private func record(_ reading: StockReading) {
        // Counts arrive live while the lid is open (Docs/BLE_SPEC.md 3.2), so they're recorded either way.
        guard let estimate = reading.estimatedCount(capacity: capacity) else {
            Logger.charm.debug("Reading not recorded: no count or level")
            return
        }
        // Clamped like the stored count is when shown, so the two compare equal.
        let count = SupplyLedger.clamped(estimate)
        let current = (try? modelContext.fetch(SupplyEvent.latest))?.first
        let previous = current?.status.count
        // Reconnects re-send the same reading; only log real changes.
        guard previous != count else {
            Logger.charm.debug("Reading not recorded: count \(count) unchanged")
            return
        }
        Logger.charm.debug("Recorded count \(count) (was \(previous ?? -1))")
        // Only the current count is kept: no timeline of when condoms left the charm.
        if let current {
            current.amount = count
            current.date = .now
            current.kind = .deviceReading
        } else {
            modelContext.insert(SupplyEvent(kind: .deviceReading, amount: count))
        }
        try? modelContext.save()
        if defaults.bool(forKey: AppSettings.lowSupplyNudgeOn),
           SupplyLedger.crossedIntoLow(from: previous, to: count) {
            nudges.schedule(.lowSupply, at: .now)
        }
    }

    /// Earlier builds kept every reading. Drops all but the newest.
    private func keepOnlyLatestReading() {
        let all = (try? modelContext.fetch(FetchDescriptor<SupplyEvent>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
        guard all.count > 1 else { return }
        all.dropFirst().forEach(modelContext.delete)
        try? modelContext.save()
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
    /// Kept alive for the whole preview session: a context whose container has been
    /// released traps on its next save.
    private static let previewContainer = try! ModelContainer(
        for: SupplyEvent.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    static func preview(paired: Bool = true) -> ContainerStore {
        let container = previewContainer
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
