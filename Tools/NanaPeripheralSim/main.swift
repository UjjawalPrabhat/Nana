// Pretends to be a Nana container over real Bluetooth, following Docs/BLE_SPEC.md.
//
// Run on a Mac:   swift Tools/NanaPeripheralSim/main.swift
// Then type a number (0–3) and press Return to change the count,
// "l <0-100>" to send a level-only reading, or "q" to quit.
// The first run asks Terminal for Bluetooth permission.

import CoreBluetooth
import Foundation

let serviceUUID = CBUUID(string: "1153E3C4-0AF1-4576-94FB-86B822E893DD")
let stockUUID = CBUUID(string: "ED573018-FB2B-4EEA-91C0-21E9287C1F6A")
let capacityUUID = CBUUID(string: "23F0CCF6-2D84-4B5E-B9A1-AF7337D3B052")
let commandUUID = CBUUID(string: "5DE4E880-7AB1-4F92-9603-7EE3BA3BD02E")
let capacity: UInt8 = 3

final class Simulator: NSObject, CBPeripheralManagerDelegate {
    private var manager: CBPeripheralManager!
    private var stock: CBMutableCharacteristic!
    private var packet: [UInt8] = [0x01, 0x01, 6, 0xFF]

    override init() {
        super.init()
        manager = CBPeripheralManager(delegate: self, queue: .main)
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else {
            print("Bluetooth is not available (state \(peripheral.state.rawValue)).")
            return
        }
        stock = CBMutableCharacteristic(type: stockUUID, properties: [.read, .notify], value: nil, permissions: .readable)
        let capacityCharacteristic = CBMutableCharacteristic(
            type: capacityUUID, properties: .read, value: Data([capacity]), permissions: .readable)
        let command = CBMutableCharacteristic(type: commandUUID, properties: .write, value: nil, permissions: .writeable)
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [stock, capacityCharacteristic, command]
        peripheral.add(service)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error { print("Couldn't add service: \(error)"); return }
        peripheral.startAdvertising([
            CBAdvertisementDataLocalNameKey: "Nana",
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
        ])
        print("Advertising as a Nana container. Count = \(packet[2]). Type a number and press Return.")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        request.value = Data(packet)
        peripheral.respond(to: request, withResult: .success)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            switch request.value?.first {
            case 0x01: print("→ identify: (blink blink)")
            case 0x02: print("→ calibrate empty")
            case 0x03: print("→ calibrate full")
            default: print("→ unknown command")
            }
        }
        peripheral.respond(to: requests[0], withResult: .success)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("iPhone subscribed.")
        publish()
    }

    func setCount(_ count: UInt8) {
        packet = [0x01, 0x01, min(count, capacity), 0xFF]
        publish()
    }

    func setLevel(_ level: UInt8) {
        packet = [0x01, 0x02, 0xFF, min(level, 100)]
        publish()
    }

    private func publish() {
        guard let stock else { return }
        let sent = manager.updateValue(Data(packet), for: stock, onSubscribedCentrals: nil)
        print("Stock → \(packet.map { String(format: "%02X", $0) }.joined(separator: " "))\(sent ? "" : " (queued)")")
    }
}

let simulator = Simulator()

FileHandle.standardInput.readabilityHandler = { handle in
    guard let line = String(data: handle.availableData, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines), !line.isEmpty else { return }
    DispatchQueue.main.async {
        if line == "q" { exit(0) }
        if line.hasPrefix("l "), let level = UInt8(line.dropFirst(2)) {
            simulator.setLevel(level)
        } else if let count = UInt8(line) {
            simulator.setCount(count)
        } else {
            print("Type 0–3, \"l 0-100\", or q.")
        }
    }
}

RunLoop.main.run()
