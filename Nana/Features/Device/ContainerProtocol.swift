import Foundation

/// Mirrors Docs/BLE_SPEC.md. Change the spec first, then this file.
nonisolated enum NanaGATT {
    static let service = "1153E3C4-0AF1-4576-94FB-86B822E893DD"
    static let stock = "ED573018-FB2B-4EEA-91C0-21E9287C1F6A"
    static let capacity = "23F0CCF6-2D84-4B5E-B9A1-AF7337D3B052"

    static let batteryService = "180F"
    static let batteryLevel = "2A19"
}

nonisolated struct StockReading: Equatable, Sendable {
    var count: Int?
    var levelPercent: Int?
    var lidOpen = false

    /// The exact count if the sensor has one, otherwise a count estimated from the fill level.
    func estimatedCount(capacity: Int) -> Int? {
        if let count { return min(count, capacity) }
        guard let levelPercent else { return nil }
        return Int((Double(levelPercent) / 100 * Double(capacity)).rounded())
    }
}

nonisolated enum StockPacket {
    static let supportedVersion: UInt8 = 1
    private static let unknown: UInt8 = 0xFF

    private enum Flag {
        static let countValid: UInt8 = 1 << 0
        static let levelValid: UInt8 = 1 << 1
        static let lidOpen: UInt8 = 1 << 2
    }

    /// Parses the 4-byte Stock characteristic. Returns `nil` for unknown versions or short packets.
    static func parse(_ data: Data) -> StockReading? {
        let bytes = [UInt8](data)
        guard bytes.count >= 4, bytes[0] == supportedVersion else { return nil }
        let flags = bytes[1]
        let count = flags & Flag.countValid != 0 && bytes[2] != unknown ? Int(bytes[2]) : nil
        let level = flags & Flag.levelValid != 0 && bytes[3] != unknown ? min(Int(bytes[3]), 100) : nil
        return StockReading(
            count: count,
            levelPercent: level,
            lidOpen: flags & Flag.lidOpen != 0
        )
    }
}

nonisolated enum ContainerConnection: Equatable, Sendable {
    case notPaired
    case connecting
    case connected
    case disconnected
    /// Bluetooth is off or not allowed. Left-behind nudges pause.
    case unavailable
}

nonisolated enum ContainerEvent: Sendable {
    case connection(ContainerConnection)
    case stock(StockReading)
    case capacity(Int)
    case battery(Int)
}

/// A way of talking to the container: real Bluetooth or the in-memory demo.
protocol ContainerTransport: AnyObject {
    var onEvent: ((ContainerEvent) -> Void)? { get set }
    /// Begins restoring any existing pairing and connection.
    func start()
    /// Shows the system pairing UI. Returns `true` if a container was added.
    func pair() async throws -> Bool
    func forget() async throws
    /// Tries the connection again, e.g. after the user taps Reconnect.
    func reconnect()
}
