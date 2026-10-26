import Foundation

/// In-memory container that speaks the same contract as the real one.
/// Used in the Simulator, for demos, and until the hardware is ready.
final class DemoContainerTransport: ContainerTransport {
    var onEvent: ((ContainerEvent) -> Void)?

    static let pairedKey = "demoContainer.paired"
    private static let countKey = "demoContainer.count"

    private let defaults: UserDefaults
    private let capacity = SupplyLedger.capacity

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private var isPaired: Bool { defaults.bool(forKey: Self.pairedKey) }

    private var count: Int {
        get { defaults.object(forKey: Self.countKey) as? Int ?? 2 }
        set { defaults.set(min(max(newValue, 0), capacity), forKey: Self.countKey) }
    }

    func start() {
        guard isPaired else {
            onEvent?(.connection(.notPaired))
            return
        }
        connect()
    }

    func pair() async throws -> Bool {
        try await Task.sleep(for: .seconds(1))
        defaults.set(true, forKey: Self.pairedKey)
        connect()
        return true
    }

    func forget() async throws {
        defaults.set(false, forKey: Self.pairedKey)
        onEvent?(.connection(.notPaired))
    }

    func reconnect() {
        guard isPaired else { return }
        connect()
    }

    func send(_ command: ContainerCommand) {}

    /// Simulates the user taking items out or refilling, then closing the lid.
    func simulateChange(by delta: Int) {
        count += delta
        publishStock()
    }

    /// Simulates walking away from the charm, or coming back to it.
    func simulateInRange(_ inRange: Bool) {
        guard isPaired else { return }
        if inRange { connect() } else { onEvent?(.connection(.disconnected)) }
    }

    private func connect() {
        onEvent?(.connection(.connecting))
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            guard let self, self.isPaired else { return }
            self.onEvent?(.connection(.connected))
            self.onEvent?(.capacity(self.capacity))
            self.onEvent?(.battery(82))
            self.onEvent?(.firmware("demo"))
            self.publishStock()
        }
    }

    private func publishStock() {
        onEvent?(.stock(StockReading(count: count)))
    }
}
