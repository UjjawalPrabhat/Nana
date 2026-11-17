# Nana charm: hardware build guide

Proof of concept: a plastic container with 3 condom slots that tells the Nana app how many are left.
Work through the steps in order. Each step ends with a **checkpoint**. Don't move on until it passes.

| Folder | What it is |
|---|---|
| `Steps/01_OneSensor` | Test one slot sensor |
| `Steps/02_AllSlots` | Test all three slots and the lid |
| `NanaCharm` | The real firmware. Talks to the app as described in [`Docs/BLE_SPEC.md`](../Docs/BLE_SPEC.md) |

## Parts

| Part | Job |
|---|---|
| ESP32-C3 Super Mini | The brain, with Bluetooth. Has a blue LED (GPIO8) and a BOOT button (GPIO9) |
| 3× optical endstop (red board, black U-shaped sensor) | One per slot. An infrared beam crosses the gap; a wrapper edge in the gap blocks it |
| Reed switch (door sensor, 2 parts) | Lid open or shut. The magnet half goes on the lid |
| Breadboard + male-to-male jumpers | Shares the board's single GND pin between all the parts |
| ESP32 WROOM DevKit V1 | Spare. Not used in these steps |
| CR2032 + holder | Battery experiment, last step only |
| Multimeter | Measuring battery drain in step 7 |

## Safety rules

1. **Never power a sensor from the 5V pin.** Its signal would be 5V, and the ESP32-C3's pins only take 3.3V.
2. **Never connect the CR2032 and the USB cable at the same time.** USB would push current into the coin cell, which can make it leak or burst. Switch the holder off before you plug in USB.
3. Unplug USB before you change any wiring.

## Pin map

The Super Mini, USB port at the top:

```
              USB-C
        ┌─────[===]─────┐
 GPIO5  │●             ●│ 5V      ← don't use
 GPIO6  │●             ●│ GND     ← shared by everything, via the breadboard
 GPIO7  │●             ●│ 3V3
 GPIO8  │●  (blue LED) ●│ GPIO4
 GPIO9  │●  (BOOT btn) ●│ GPIO3
 GPIO10 │●             ●│ GPIO2   ← leave free (affects booting)
 GPIO20 │●             ●│ GPIO1
 GPIO21 │●             ●│ GPIO0
        └───────────────┘
```

This is the **front** (chip side). The pin numbers are printed on the **back**, so the sides swap when you flip it. When in doubt, flip the board and read the label.

The sensors' pins are labelled **V** (power), **S** (signal) and **G** (ground) on the back of the red board. Put a bit of tape with V, S or G on each wire at the sensor's plug: the far ends of the cable all look the same.

| What | Wire | Super Mini pin |
|---|---|---|
| Slot 1 sensor | S | GPIO4 |
| | V | GPIO5 (the pin powers the sensor only while reading it) |
| | G | GND |
| Slot 2 sensor | S | GPIO6 |
| | V | GPIO7 |
| | G | GPIO10 (acts as ground) |
| Slot 3 sensor | S | GPIO0 |
| | V | GPIO1 |
| | G | GPIO20 (acts as ground) |
| Reed switch | either wire | GPIO3 |
| | other wire | GPIO21 (acts as ground) |

The board has only one GND pin, so pins 10, 20 and 21 are held at 0 V by the firmware and act as extra ground pins (`GROUND_PINS`). Every wire goes straight from a part onto a board pin; no breadboard needed. With pin-ended jumpers and a breadboard you can instead share the real GND and set `USE_GROUND_PINS = false` in `NanaCharm`.

## Step 0: set up the computer

1. Install **Arduino IDE 2** from arduino.cc.
   On a Mac with an M chip, also run `softwareupdate --install-rosetta --agree-to-license` in Terminal. Without it, every compile fails with "bad CPU type in executable".
2. **Arduino IDE → Settings → Additional boards manager URLs**, paste:
   `https://espressif.github.io/arduino-esp32/package_esp32_index.json`
3. **Tools → Board → Boards Manager**, search **esp32**, install **esp32 by Espressif Systems**.
4. **Tools → Manage Libraries**, search **NimBLE-Arduino**, install the one **by h2zero**.
5. Plug in the Super Mini with a USB-C cable that carries data. Some cables only charge.
6. **Tools → Board → esp32 → ESP32C3 Dev Module**.
7. **Tools → USB CDC On Boot → Enabled**. Without this, the Serial Monitor stays empty.
8. **Tools → Port**: choose the one that looks like `/dev/cu.usbmodem…`.

**If an upload fails:** hold **BOOT**, tap **RESET**, let go of BOOT, then upload again. After uploading, tap **RESET** once.

✅ **Checkpoint 0:** open `Steps/01_OneSensor` and press Upload. You see "Done uploading" or "Hard resetting".

## Step 1: one sensor

1. Wire the slot 1 sensor: **V → 3V3**, **G → GND**, **S → GPIO4**. Use the labels printed next to the sensor's connector.
2. Upload `Steps/01_OneSensor`, then open **Tools → Serial Monitor** at **115200** baud.
3. Push a strip of paper into the gap and pull it out. The value should flip between HIGH and LOW. The small light on the sensor board changes too.
4. Do the same with the **sealed edge of a real condom wrapper**.
5. Measure the gap width with a ruler.

✅ **Checkpoint 1:** write down:
- what the Serial Monitor shows while the gap is **blocked** (HIGH or LOW) → that's `BLOCKED_LEVEL`
- whether the wrapper edge flips it every time, and how deep it has to go in
- the gap width in mm

If blocked reads **LOW**, change `BLOCKED_LEVEL` to `LOW` in `Steps/02_AllSlots` and in `NanaCharm`.

## Step 2: all three slots

1. Wire all three sensors and, if it has arrived, the reed switch, using the **pin map**. Note that each sensor's **VCC now goes to its own pin**, not 3V3.
2. Upload `Steps/02_AllSlots` and open the Serial Monitor.
3. Put wrappers in and take them out, one slot at a time.

✅ **Checkpoint 2:** each slot shows `[X]` when filled and `[ ]` when empty, and the count matches. With the reed switch: moving the magnet half away shows "open", and touching it back shows "closed".

If a sensor never changes while powered from its pin, it may need more current than the pin gives. Move just that sensor's VCC to 3V3, then set `SENSOR_POWER_FROM_GPIO = false` in `NanaCharm` (all sensors then stay on, so tell us).

## Step 3: Bluetooth, tested with a phone app

1. Upload `NanaCharm`. The Serial Monitor shows `Nana charm ready` and `Advertising fast (pairing)`, and the blue LED blinks slowly for 30 s.
2. On an iPhone, install **nRF Connect** (free). Scan, find **Nana**, tap **Connect**. The blue LED flashes once.
3. Open the service starting `1153E3C4`:
   - **Stock** (`ED573018…`): tap the read arrow. You see 4 bytes, e.g. `01-01-02-FF` = version 1, count valid, **2 condoms**.
   - Tap the subscribe arrows on Stock, then change a slot. About 2 s later a new value arrives.
   - **Capacity** (`23F0CCF6…`) reads `03`.
   - **Command** (`5DE4E880…`): write the hex byte `01`. The LED blinks fast for 2 s.
4. **Disconnect in nRF Connect** before step 4. The charm only takes one phone at a time.

✅ **Checkpoint 3:** reading, notifying and identify all work.

## Step 4: pair with the Nana app

1. Build the Nana app from Xcode onto a **real iPhone**. Bluetooth doesn't work in the Simulator.
2. In the app: **Settings → Demo charm → Use demo charm** must be **off**. If you already paired the demo, choose **Forget this charm** first.
3. On the charm, **hold BOOT for 3 s**. The LED blinks slowly, which means it's in pairing mode.
4. In the app, tap **Pair your charm**. Apple's sheet shows the Nana charm. Tap it and connect.
5. Change a slot, wait 2 s. The number on Home updates.

✅ **Checkpoint 4:** the Home count follows the slots. Walk away with the phone until it disconnects (Home says out of range after the wait you picked). Walk back: it reconnects on its own within about 10 s.

## Step 5: lid switch

When the reed switch has arrived and checkpoint 2 shows the lid working:

1. In `NanaCharm`, set `HAS_LID_SWITCH = true` and upload.
2. Open the lid, change slots, close the lid. About 2 s after closing, the count is sent.
3. Opening and closing without changing anything leaves the count unchanged.

✅ **Checkpoint 5:** the count only changes after the lid closes.

## Step 6: into the container

- Each slot needs a **guide** (a cardboard or plastic channel) so the wrapper's sealed edge always lands in the sensor's gap. This is what makes the count reliable.
- Measured on our sensors (2026-11-10): the gap is **3 mm wide and 8 mm deep**, and the beam sits about **2 mm below the top**. Blocked reads **HIGH**. Make each guide hold the wrapper's sealed edge **4–6 mm deep** in the gap: past the beam, clear of the bottom.
- Mount the reed switch's sensor half on the box and the magnet half on the lid, lined up when shut. The gap should be under about 1 cm.
- Keep the Super Mini where you can still reach the USB port and the BOOT button.
- Run checkpoints 2 to 5 again with everything inside.

## Step 7: power (do this last)

1. With USB power, use the multimeter in **current (mA)** mode to measure how much the charm draws while connected.
2. Then try the CR2032. **USB unplugged**, holder switched off:
   - Holder red wire → **3V3**, black → **GND**.
   - Switch on.
3. Most likely result: it starts, then restarts over and over when Bluetooth begins. A coin cell can't deliver the bursts of current the radio needs. Report what you see and we'll pick the next option.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Serial Monitor is empty | Tools → USB CDC On Boot → **Enabled**, re-upload, tap RESET |
| Port doesn't show up | Try another cable (data, not charge-only). Hold BOOT while plugging in |
| Upload fails | BOOT + RESET trick in step 0 |
| nRF Connect doesn't see "Nana" | Hold BOOT 3 s for fast advertising. Make sure no other phone is connected |
| App can't find the charm | Disconnect it in nRF Connect, hold BOOT 3 s, then pair again |
| Bluetooth range is only a few metres | Known weakness of some Super Mini clones' antennas. Note it, and we'll see whether it matters |
| A red light on the board is always on | The power LED. It's normal, and it does waste battery; we'll deal with it later |
