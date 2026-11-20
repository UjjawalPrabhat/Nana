import AccessorySetupKit
import CoreBluetooth
import OSLog
import UIKit

/// Real container: AccessorySetupKit for pairing, CoreBluetooth for data.
///
/// AccessorySetupKit shows Apple's own pairing sheet and gives the app access to
/// just this accessory, so there is no general Bluetooth permission prompt.
final class BLEContainerTransport: NSObject, ContainerTransport {
    var onEvent: ((ContainerEvent) -> Void)?

    private let session = ASAccessorySession()
    private var accessory: ASAccessory?
    private var central: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var pickerContinuation: CheckedContinuation<Bool, Error>?
    /// Reports "out of range" if a connect attempt hasn't succeeded in time.
    private var connectTimeout: Task<Void, Never>?

    /// How long "Connecting" shows before the charm counts as out of range.
    private static let connectGrace: Duration = .seconds(10)

    func start() {
        session.activate(on: .main) { [weak self] event in
            self?.handle(event)
        }
    }

    func pair() async throws -> Bool {
        guard pickerContinuation == nil else { return false }  // the picker is already up
        // Only a charm in pairing mode (button just held) advertises this ID, so with
        // two charms in a room only that one is listed.
        let descriptor = ASDiscoveryDescriptor()
        descriptor.bluetoothServiceUUID = .nanaPairing
        let item = ASPickerDisplayItem(
            name: String(localized: "Nana charm"),
            productImage: .charmProduct,
            descriptor: descriptor
        )
        return try await withCheckedThrowingContinuation { continuation in
            pickerContinuation = continuation
            session.showPicker(for: [item]) { [weak self] error in
                guard let error else { return }
                Task { @MainActor in
                    self?.pickerContinuation?.resume(throwing: error)
                    self?.pickerContinuation = nil
                }
            }
        }
    }

    func forget() async throws {
        guard let accessory else { return }
        // Let go first, so the disconnect that follows isn't treated as "out of range"
        // and doesn't start a new connect to the charm being removed.
        let peripheral = self.peripheral
        release()
        if let peripheral { central?.cancelPeripheralConnection(peripheral) }
        do {
            try await session.removeAccessory(accessory)
            // `.accessoryRemoved` reports this too; don't depend on it arriving.
            onEvent?(.connection(.notPaired))
        } catch {
            self.accessory = accessory
            startCentral()
            throw error
        }
    }

    // MARK: AccessorySetupKit

    private func handle(_ event: ASAccessoryEvent) {
        Logger.charm.debug("Setup event \(String(describing: event.eventType), privacy: .public)")
        switch event.eventType {
        case .activated:
            accessory = session.accessories.first
            if accessory != nil { startCentral() } else { onEvent?(.connection(.notPaired)) }
        case .accessoryAdded:
            accessory = event.accessory
            startCentral()
            pickerContinuation?.resume(returning: true)
            pickerContinuation = nil
        case .accessoryRemoved:
            // Also reached when the charm is removed in iOS Settings.
            if let peripheral { central?.cancelPeripheralConnection(peripheral) }
            release()
            onEvent?(.connection(.notPaired))
        case .pickerDidDismiss:
            // Fires after `.accessoryAdded` on success, so this only resolves a cancel.
            pickerContinuation?.resume(returning: false)
            pickerContinuation = nil
        default:
            break
        }
    }

    private func release() {
        accessory = nil
        peripheral = nil
        connectTimeout?.cancel()
    }

    // MARK: CoreBluetooth

    private func startCentral() {
        if central == nil {
            central = CBCentralManager(
                delegate: self,
                queue: .main,
                options: [CBCentralManagerOptionRestoreIdentifierKey: "nana.container.central"]
            )
        }
        showConnecting()
        connectIfPossible()
    }

    private func connectIfPossible() {
        guard let central, central.state == .poweredOn, let identifier = accessory?.bluetoothIdentifier else { return }
        guard let target = peripheral ?? central.retrievePeripherals(withIdentifiers: [identifier]).first else {
            Logger.charm.error("No peripheral for the paired identifier \(identifier, privacy: .public)")
            return
        }
        peripheral = target
        target.delegate = self
        switch target.state {
        case .connected:
            didBecomeConnected(target)  // e.g. restored by iOS while still connected
        case .connecting:
            break
        default:
            // No timeout: iOS keeps this pending and connects whenever the charm is in range.
            Logger.charm.debug("Connect pending")
            central.connect(target)
        }
    }

    private func showConnecting() {
        connectTimeout?.cancel()
        // A background wake (state restoration, Bluetooth back on) only gets a few
        // seconds, too short for the grace period: out of range is out of range.
        if UIApplication.shared.applicationState == .background {
            if peripheral?.state != .connected { onEvent?(.connection(.disconnected)) }
            return
        }
        onEvent?(.connection(.connecting))
        connectTimeout = Task { [weak self] in
            try? await Task.sleep(for: Self.connectGrace)
            guard !Task.isCancelled, let self, self.accessory != nil,
                  self.peripheral?.state != .connected else { return }
            self.onEvent?(.connection(.disconnected))
        }
    }

    private func didBecomeConnected(_ peripheral: CBPeripheral) {
        connectTimeout?.cancel()
        onEvent?(.connection(.connected))
        peripheral.discoverServices([.nanaService, .batteryService])
    }

    /// Callbacks can still arrive for a charm that was just forgotten.
    private func isCurrent(_ peripheral: CBPeripheral) -> Bool {
        accessory != nil && peripheral === self.peripheral
    }
}

extension BLEContainerTransport: @preconcurrency CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Logger.charm.debug("Bluetooth state \(central.state.rawValue)")
        // With no charm paired, AccessorySetupKit withdraws Bluetooth access, which
        // reads as "unauthorized". That isn't Bluetooth being off, so it's ignored.
        guard accessory != nil else { return }
        if central.state == .poweredOn {
            showConnecting()
            connectIfPossible()
        } else {
            connectTimeout?.cancel()
            onEvent?(.connection(.unavailable))
        }
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        if let restored = (dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral])?.first {
            Logger.charm.debug("Restored peripheral, state \(restored.state.rawValue)")
            peripheral = restored
            restored.delegate = self
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Logger.charm.debug("Connected")
        guard isCurrent(peripheral) else { return }
        didBecomeConnected(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Logger.charm.debug("Disconnected: \(error?.localizedDescription ?? "no error", privacy: .public)")
        guard isCurrent(peripheral) else { return }
        onEvent?(.connection(.disconnected))
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Logger.charm.error("Failed to connect: \(error?.localizedDescription ?? "no error", privacy: .public)")
        guard isCurrent(peripheral) else { return }
        onEvent?(.connection(.disconnected))
        // Wait before retrying, so a persistent failure doesn't become a tight loop.
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            self?.connectIfPossible()
        }
    }
}

extension BLEContainerTransport: @preconcurrency CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let found = peripheral.services?.map(\.uuid.uuidString).joined(separator: ", ") ?? "none"
        Logger.charm.debug("Services: \(found, privacy: .public) \(error?.localizedDescription ?? "", privacy: .public)")
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let found = service.characteristics?.map(\.uuid.uuidString).joined(separator: ", ") ?? "none"
        Logger.charm.debug("Characteristics of \(service.uuid.uuidString, privacy: .public): \(found, privacy: .public)")
        for characteristic in service.characteristics ?? [] {
            switch characteristic.uuid {
            case .nanaStock, .batteryLevel:
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
            case .nanaCapacity:
                peripheral.readValue(for: characteristic)
            default:
                break
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let value = characteristic.value else {
            Logger.charm.error("Read of \(characteristic.uuid.uuidString, privacy: .public) failed: \(error?.localizedDescription ?? "no value", privacy: .public)")
            return
        }
        switch characteristic.uuid {
        case .nanaStock:
            let hex = value.map { String(format: "%02X", $0) }.joined(separator: " ")
            if let reading = StockPacket.parse(value) {
                Logger.charm.debug("Stock \(hex, privacy: .public): count \(reading.count ?? -1), lid \(reading.lidOpen ? "open" : "shut", privacy: .public)")
                onEvent?(.stock(reading))
            } else {
                Logger.charm.error("Stock \(hex, privacy: .public) rejected: wrong version or too short")
            }
        case .nanaCapacity:
            if let capacity = value.first, capacity > 0 { onEvent?(.capacity(Int(capacity))) }
        case .batteryLevel:
            if let level = value.first { onEvent?(.battery(Int(min(level, 100)))) }
        default:
            break
        }
    }
}

private extension CBUUID {
    static let nanaService = CBUUID(string: NanaGATT.service)
    static let nanaPairing = CBUUID(string: NanaGATT.pairingService)
    static let nanaStock = CBUUID(string: NanaGATT.stock)
    static let nanaCapacity = CBUUID(string: NanaGATT.capacity)
    static let batteryService = CBUUID(string: NanaGATT.batteryService)
    static let batteryLevel = CBUUID(string: NanaGATT.batteryLevel)
}
