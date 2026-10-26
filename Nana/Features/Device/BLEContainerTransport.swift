import AccessorySetupKit
import CoreBluetooth
import SwiftUI

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
    private var commandCharacteristic: CBCharacteristic?
    private var pickerContinuation: CheckedContinuation<Bool, Error>?

    func start() {
        session.activate(on: .main) { [weak self] event in
            self?.handle(event)
        }
    }

    func pair() async throws -> Bool {
        let descriptor = ASDiscoveryDescriptor()
        descriptor.bluetoothServiceUUID = CBUUID(string: NanaGATT.service)
        let item = ASPickerDisplayItem(
            name: String(localized: "Nana charm"),
            productImage: Self.productImage,
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
        if let peripheral { central?.cancelPeripheralConnection(peripheral) }
        try await session.removeAccessory(accessory)
    }

    func reconnect() {
        guard let central else { return }
        if let peripheral, peripheral.state != .disconnected {
            central.cancelPeripheralConnection(peripheral)
        }
        connectIfPossible(central)
    }

    func send(_ command: ContainerCommand) {
        guard let peripheral, let commandCharacteristic else { return }
        peripheral.writeValue(Data([command.rawValue]), for: commandCharacteristic, type: .withResponse)
    }

    // MARK: AccessorySetupKit

    private func handle(_ event: ASAccessoryEvent) {
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
            accessory = nil
            peripheral = nil
            commandCharacteristic = nil
            onEvent?(.connection(.notPaired))
        case .pickerDidDismiss:
            // Fires after `.accessoryAdded` on success, so this only resolves a cancel.
            pickerContinuation?.resume(returning: false)
            pickerContinuation = nil
        default:
            break
        }
    }

    // MARK: CoreBluetooth

    private func startCentral() {
        onEvent?(.connection(.connecting))
        if let central {
            connectIfPossible(central)
        } else {
            central = CBCentralManager(
                delegate: self,
                queue: .main,
                options: [CBCentralManagerOptionRestoreIdentifierKey: "nana.container.central"]
            )
        }
    }

    private func connectIfPossible(_ central: CBCentralManager) {
        guard central.state == .poweredOn, let identifier = accessory?.bluetoothIdentifier else { return }
        let target = peripheral ?? central.retrievePeripherals(withIdentifiers: [identifier]).first
        guard let target else { return }
        peripheral = target
        target.delegate = self
        if target.state != .connected {
            // No timeout: iOS keeps this pending and connects whenever the container is in range.
            central.connect(target)
        }
    }

    private static var productImage: UIImage {
        let renderer = ImageRenderer(content: CharmView(count: SupplyLedger.capacity, scale: 0.75))
        renderer.scale = 3
        return renderer.uiImage ?? UIImage()
    }
}

extension BLEContainerTransport: @preconcurrency CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            connectIfPossible(central)
        } else {
            onEvent?(.connection(.unavailable))
        }
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        if let restored = (dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral])?.first {
            peripheral = restored
            restored.delegate = self
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        onEvent?(.connection(.connected))
        peripheral.discoverServices([
            CBUUID(string: NanaGATT.service),
            CBUUID(string: NanaGATT.batteryService),
            CBUUID(string: NanaGATT.deviceInfoService),
        ])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        commandCharacteristic = nil
        onEvent?(.connection(.disconnected))
        if accessory != nil { central.connect(peripheral) }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        onEvent?(.connection(.disconnected))
        if accessory != nil { central.connect(peripheral) }
    }
}

extension BLEContainerTransport: @preconcurrency CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics ?? [] {
            switch characteristic.uuid {
            case CBUUID(string: NanaGATT.stock), CBUUID(string: NanaGATT.batteryLevel):
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
            case CBUUID(string: NanaGATT.capacity), CBUUID(string: NanaGATT.firmwareRevision):
                peripheral.readValue(for: characteristic)
            case CBUUID(string: NanaGATT.command):
                commandCharacteristic = characteristic
            default:
                break
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let value = characteristic.value else { return }
        switch characteristic.uuid {
        case CBUUID(string: NanaGATT.stock):
            if let reading = StockPacket.parse(value) { onEvent?(.stock(reading)) }
        case CBUUID(string: NanaGATT.capacity):
            if let capacity = value.first, capacity > 0 { onEvent?(.capacity(Int(capacity))) }
        case CBUUID(string: NanaGATT.batteryLevel):
            if let level = value.first { onEvent?(.battery(Int(min(level, 100)))) }
        case CBUUID(string: NanaGATT.firmwareRevision):
            onEvent?(.firmware(String(decoding: value, as: UTF8.self)))
        default:
            break
        }
    }
}
