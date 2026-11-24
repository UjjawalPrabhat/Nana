# Nana container — BLE contract (v1)

This is the agreement between the Nana container firmware and the Nana iPhone app.
Build the firmware to this spec and the app will work with it without changes.
If something here doesn't fit the hardware, change this document first, then the code on both sides.

Status: **draft v1**. The app already implements this contract against a mock device and the macOS simulator in `Tools/NanaPeripheralSim`.

## 1. Roles

| | Role |
|---|---|
| Container | BLE **peripheral** (GATT server) |
| iPhone app | BLE **central** (GATT client) |

The iPhone pairs with the container through Apple's **AccessorySetupKit** picker. The picker finds the container by the **pairing UUID in its advertising packet**, which the container advertises only in pairing mode (section 2).

## 2. Advertising

| Field | Value |
|---|---|
| Complete 128-bit service UUID | `1153E3C4-0AF1-4576-94FB-86B822E893DD` (Nana service). In pairing mode, the pairing UUID `8029197C-AEF8-4F54-8155-96DBF7774EB0` instead |
| Local name | `Nana` (keep it neutral, never describe the contents) |
| Interval | 100–200 ms for the first 30 s after power-on or the pairing button; then 1–2 s to save battery |
| Address | LE privacy (resolvable private address) recommended so the container can't be tracked |

Holding the **pairing button** for 3 s enters pairing mode for 30 s: fast advertising with the pairing UUID in place of the Nana service UUID. The pairing UUID has no GATT service behind it; it only tells the app's pairing sheet which container to list, so with two containers in a room only the one whose button was held shows up. The container also enters pairing mode at power-on. After a disconnect it advertises fast under `Nana` for 30 s, so the phone reconnects quickly, then slowly. On the proof-of-concept board this is the ESP32-C3's BOOT button (GPIO9); its final place on the Pod isn't decided.

## 3. GATT

### 3.1 Nana service `1153E3C4-0AF1-4576-94FB-86B822E893DD`

| Characteristic | UUID | Properties | Format |
|---|---|---|---|
| Stock | `ED573018-FB2B-4EEA-91C0-21E9287C1F6A` | Read, Notify | 4 bytes, see 3.2 |
| Capacity | `23F0CCF6-2D84-4B5E-B9A1-AF7337D3B052` | Read | `u8`: max items the container holds (3 on the Pod) |
| Command | `5DE4E880-7AB1-4F92-9603-7EE3BA3BD02E` | Write (with response) | `u8` opcode, see 3.3 |

### 3.2 Stock packet (4 bytes, little-endian where it matters)

| Byte | Name | Meaning |
|---|---|---|
| 0 | `version` | Packet format version. **1** for this spec. The app ignores packets with a version it doesn't know. |
| 1 | `flags` | bit 0 `countValid`: byte 2 holds an exact count<br>bit 1 `levelValid`: byte 3 holds a level<br>bit 2 `lidOpen`: lid is open right now (the count is live and may keep changing)<br>bit 3 `needsCalibration`: the sensor needs calibration<br>bits 4–7 reserved, send 0 |
| 2 | `count` | Items in the container, `0…capacity`. `0xFF` = unknown. |
| 3 | `levelPercent` | Approximate fill level, `0…100`. `0xFF` = unknown. |

This works whichever sensor the hardware team picks:

- **The sensor gives an exact count** (e.g. per-slot switches or IR): set `countValid`. `levelPercent` is optional.
- **The sensor gives a level only** (e.g. load cell or ToF distance): set `levelValid` only. The app converts the level to an estimated count (`round(level / 100 × capacity)`).

Example: 3 items, exact count, lid closed → `01 01 03 FF`.

**When to notify:**

- **Lid opens:** notify once with `lidOpen` set and the last count. Switch the sensors on.
- **While the lid is open:** read the sensors a few times a second and notify whenever the count changes and has held for about 1 s. The app records these counts as they arrive.
- **Lid closes:** read once more, notify with `lidOpen` clear, then switch the sensors off. While shut, the container only keeps the Bluetooth link (the app needs it for the left-behind nudge).
- **No lid switch:** read about once a second and notify when the count has held for about 2 s.
- Also notify once when a central subscribes.

### 3.3 Command opcodes

| Opcode | Name | Container does |
|---|---|---|
| `0x01` | identify | Blinks the LED (or buzzes) for about 2 s, so the user can tell which container is theirs |
| `0x02` | calibrateEmpty | Stores the current sensor value as "empty" |
| `0x03` | calibrateFull | Stores the current sensor value as "full" (= capacity) |

Unknown opcodes may be ignored. (The proof-of-concept firmware accepts every write and acts only on `identify`.)

> App support in v1: the app sends no commands yet and ignores the `needsCalibration` flag. Calibration UI comes later, so firmware may calibrate from the button for now.

### 3.4 Standard services (please include)

| Service | Characteristic | Notes |
|---|---|---|
| Battery `0x180F` | Battery Level `0x2A19` (Read, Notify) | `u8` 0–100. Optional: leave the service out if the hardware can't measure its battery, and the app shows "Connected" without a level. The proof of concept leaves it out. |
| Device Information `0x180A` | Manufacturer `0x2A29`, Model `0x2A24`, Firmware `0x2A26` (Read) | UTF-8 strings, e.g. `Nana`, `Nana C1`, `0.1.0` |

## 4. Security and privacy

- **v1 (prototype):** no encryption, so bring-up is easier.
- **v1.1 (before user testing):** require an **encrypted link** (LE Secure Connections, bonding) for the Nana service. iOS shows its standard pairing prompt once, and the app handles both modes.
- The container stores **no** user data, only calibration values.
- Never put the count in the advertising data. It is only readable after connecting.

## 5. Behaviour the app relies on

1. The container accepts reconnection from a bonded iPhone at any time. The app reconnects in the background (CoreBluetooth state restoration) to receive Stock notifications.
2. **The app treats a dropped connection as "out of range".** After the wait the user picks (1, 2 or 5 minutes), it sends the left-behind nudge. So the firmware must never drop an idle connection on its own (no idle timeout, no sleep that ends the link) and should keep advertising while disconnected so the phone reconnects as soon as it is back in range.
3. One connection at a time is fine.
4. After power loss, any calibration values persist (NVS/flash). The per-slot sensors on the proof of concept need none.

## 6. Reference firmware

The proof-of-concept firmware is [`Firmware/NanaCharm`](../Firmware/NanaCharm/NanaCharm.ino) (ESP32-C3 Super Mini + NimBLE-Arduino 2.x). [`Firmware/README.md`](../Firmware/README.md) covers wiring and the build.

## 7. Testing without hardware

- **iOS Simulator:** the app's demo Pod ("No Pod yet? Try a demo", in every build) implements this contract in memory.
- **Real iPhone, no hardware:** run `swift Tools/NanaPeripheralSim/main.swift` on a Mac. The Mac advertises as a Nana container, and you type a number to change the count.
- **Generic tools:** nRF Connect or LightBlue can read and write the characteristics above.

## Changelog

- v1 (2026-10-20): first draft.
- v1 (2026-11-10): capacity examples use 3; Battery service optional; pairing button is BOOT on the proof of concept; reference firmware moved to `Firmware/`.
- v1 (2026-11-19): pairing mode advertises the pairing UUID; the app's pairing sheet lists only those.
- v1 (2026-11-19): counts stream live while the lid is open and the app records them; sensors are off while the lid is shut.
