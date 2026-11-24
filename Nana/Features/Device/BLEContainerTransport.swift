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

    /// How long "Connecting" shows before the Pod counts as out of range.
    private static let connectGrace: Duration = .seconds(10)

    func start() {
        session.activate(on: .main) { [weak self] event in
            self?.handle(event)
        }
    }

    func pair() async throws -> Bool {
        guard pickerContinuation == nil else { return false }  // the picker is already up
        // Only a Pod in pairing mode (button just held) advertises this ID, so with
        // two Pods in a room only that one is listed.
        let descriptor = ASDiscoveryDescriptor()
        descriptor.bluetoothServiceUUID = .nanaPairing
        let item = ASPickerDisplayItem(
            name: String(localized: "Nana Pod"),
            productImage: .podProduct,
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
        // and doesn't start a new connect to the Pod being removed.
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
        DebugLog.add("Setup event \(String(describing: event.eventType))")
        switch event.eventType {
        case .activated:
            accessory = session.accessories.first
            if accessory != nil { startCentral() } else { onEvent?(.connection(.notPaired)) }
        case .accessoryAdded:
            accessory = event.accessory
            DebugLog.add("Paired accessory \(event.accessory?.bluetoothIdentifier?.uuidString ?? "with no Bluetooth ID")")
            startCentral()
            pickerContinuation?.resume(returning: true)
            pickerContinuation = nil
        case .accessoryRemoved:
            // Also reached when the Pod is removed in iOS Settings.
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
            DebugLog.add("No peripheral for the paired identifier \(identifier)", isError: true)
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
            // No timeout: iOS keeps this pending and connects whenever the Pod is in range.
            DebugLog.add("Connect pending")
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

    /// Callbacks can still arrive for a Pod that was just forgotten.
    private func isCurrent(_ peripheral: CBPeripheral) -> Bool {
        accessory != nil && peripheral === self.peripheral
    }
}

extension BLEContainerTransport: @preconcurrency CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DebugLog.add("Bluetooth state: \(central.state.debugName)")
        // With no Pod paired, AccessorySetupKit withdraws Bluetooth access, which
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
            DebugLog.add("Restored peripheral, state \(restored.state.rawValue)")
            peripheral = restored
            restored.delegate = self
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DebugLog.add("Connected")
        guard isCurrent(peripheral) else { return }
        didBecomeConnected(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DebugLog.add("Disconnected: \(error?.localizedDescription ?? "no error")")
        guard isCurrent(peripheral) else { return }
        onEvent?(.connection(.disconnected))
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DebugLog.add("Failed to connect: \(error?.localizedDescription ?? "no error")", isError: true)
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
        DebugLog.add("Services: \(found) \(error?.localizedDescription ?? "")")
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let found = service.characteristics?.map(\.uuid.uuidString).joined(separator: ", ") ?? "none"
        DebugLog.add("Characteristics of \(service.uuid.uuidString): \(found)")
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
            DebugLog.add("Read of \(characteristic.uuid.uuidString) failed: \(error?.localizedDescription ?? "no value")", isError: true)
            return
        }
        switch characteristic.uuid {
        case .nanaStock:
            let hex = value.map { String(format: "%02X", $0) }.joined(separator: " ")
            if let reading = StockPacket.parse(value) {
                DebugLog.add("Stock \(hex): count \(reading.count ?? -1), lid \(reading.lidOpen ? "open" : "shut")")
                onEvent?(.stock(reading))
            } else {
                DebugLog.add("Stock \(hex) rejected: wrong version or too short", isError: true)
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

private extension CBManagerState {
    var debugName: String {
        switch self {
        case .poweredOn: "on"
        case .poweredOff: "off"
        case .unauthorized: "not allowed (no Pod paired)"
        case .unsupported: "unsupported"
        case .resetting: "resetting"
        default: "unknown"
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
