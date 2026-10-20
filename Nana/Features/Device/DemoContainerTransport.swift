import Foundation

/// In-memory container that speaks the same contract as the real one.
/// Used in the Simulator, for demos, and until the hardware is ready.
final class DemoContainerTransport: ContainerTransport {
    var onEvent: ((ContainerEvent) -> Void)?

    private let defaults: UserDefaults
    private let pairedKey = "demoContainer.paired"
    private let countKey = "demoContainer.count"
    private let capacity = SupplyLedger.capacity

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isPaired: Bool { defaults.bool(forKey: pairedKey) }

    private var count: Int {
        get { defaults.object(forKey: countKey) as? Int ?? 6 }
        set { defaults.set(min(max(newValue, 0), capacity), forKey: countKey) }
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
        defaults.set(true, forKey: pairedKey)
        connect()
        return true
    }

    func forget() async throws {
        defaults.set(false, forKey: pairedKey)
        onEvent?(.connection(.notPaired))
    }

    func send(_ command: ContainerCommand) {}

    /// Simulates the user taking items out or refilling, then closing the lid.
    func simulateChange(by delta: Int) {
        count += delta
        publishStock()
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
        // Round-trip through the real packet format so the parser is exercised too.
        let packet = StockPacket.encode(StockReading(count: count))
        if let reading = StockPacket.parse(packet) { onEvent?(.stock(reading)) }
    }
}
