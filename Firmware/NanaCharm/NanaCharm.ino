// Nana charm firmware, proof of concept.
// Speaks the Bluetooth contract in Docs/BLE_SPEC.md (v1). Board: ESP32-C3 Super Mini.
// Wiring and the step-by-step build: Firmware/README.md
//
// How it behaves:
// - Stays connected to the iPhone all the time, so the app's left-behind nudge works.
// - With the lid switch: while the lid is open, the slots are read 4 times a second and
//   a new count is sent live once it has held for 1 s. When the lid shuts, they're read
//   one last time and then stay off; only the Bluetooth link stays up.
// - Without it, they're read every second and a new count is sent once it has held for 2 s.
// - Blue LED: one flash when the lid opens, two quick blinks when it shuts and the last
//   count is taken. Otherwise dark unless it's pairing, has just connected, or is asked
//   to identify.
// - After the iPhone disconnects, it advertises fast for 30 s so the phone finds it again
//   quickly, then slowly to save power.

#include <NimBLEDevice.h>
#include "driver/gpio.h"
#include "esp_system.h"

// ============ Settings you may need to change ============

// Turn on once the reed switch is wired between LID_PIN and GND.
const bool HAS_LID_SWITCH = true;

// What LID_PIN reads when the lid is shut. Most 2-wire door reed switches are
// "normally open": the magnet closes them, so shut reads LOW. If the log says
// "open" while the lid is shut (and the other way round), the switch is
// "normally closed": set this to HIGH.
const int LID_SHUT_LEVEL = LOW;

// Extra Serial Monitor output for bring-up: raw lid edges, each slot's reading,
// Bluetooth details and a status line every 5 s. Type h in the Serial Monitor
// for commands. Set to false for battery tests: printing keeps the chip busier.
const bool DEBUG = true;

// What the S pin reads when a wrapper blocks the beam (found in step 1).
const int BLOCKED_LEVEL = HIGH;

// true:  each sensor's VCC goes to its own power pin, switched on only while reading.
// false: every sensor's VCC goes to 3V3 and stays on.
const bool SENSOR_POWER_FROM_GPIO = true;

const int SLOT_COUNT = 3;
const int SLOT_SIGNAL_PINS[SLOT_COUNT] = {4, 6, 0};
const int SLOT_POWER_PINS[SLOT_COUNT] = {5, 7, 1};
const int LID_PIN = 3;     // reed switch to a ground pin; which level is "shut": LID_SHUT_LEVEL
const int LED_PIN = 8;     // onboard blue LED: LOW = on
const int BUTTON_PIN = 9;  // onboard BOOT button: LOW = pressed

// Extra ground pins, held at 0 V, because the board has only one GND pin.
// Slot 2's G -> 10, slot 3's G -> 20, the reed switch's second wire -> 21.
// Once everything shares a breadboard ground, set USE_GROUND_PINS to false.
const bool USE_GROUND_PINS = true;
const int GROUND_PIN_COUNT = 3;
const int GROUND_PINS[GROUND_PIN_COUNT] = {10, 20, 21};

// ============ Bluetooth contract (Docs/BLE_SPEC.md) ============

#define NANA_SERVICE  "1153E3C4-0AF1-4576-94FB-86B822E893DD"
#define STOCK_CHAR    "ED573018-FB2B-4EEA-91C0-21E9287C1F6A"
#define CAPACITY_CHAR "23F0CCF6-2D84-4B5E-B9A1-AF7337D3B052"
#define COMMAND_CHAR  "5DE4E880-7AB1-4F92-9603-7EE3BA3BD02E"
// Advertised instead of NANA_SERVICE while pairing. No GATT service behind it: it only
// tells the app's pairing sheet which charm to list (Docs/BLE_SPEC.md 2).
#define PAIRING_SERVICE "8029197C-AEF8-4F54-8155-96DBF7774EB0"
#define ADVERTISED_NAME "Nana"   // neutral, never describes the contents

const uint8_t PACKET_VERSION = 1;
const uint8_t FLAG_COUNT_VALID = 1 << 0;
const uint8_t FLAG_LID_OPEN = 1 << 2;
const uint8_t UNKNOWN = 0xFF;
const uint8_t CMD_IDENTIFY = 0x01;

// ============ Timing ============

const uint32_t OPEN_POLL_MS = 250;        // lid open: how often the slots are read
const uint32_t OPEN_STABLE_MS = 1000;     // lid open: a count must hold this long to be sent
const uint32_t STABLE_MS = 2000;          // without a lid switch (SEN-5)
const uint32_t POLL_MS = 1000;            // without a lid switch
const uint32_t LID_DEBOUNCE_MS = 50;
const uint32_t FAST_ADVERTISING_MS = 30000;
const uint32_t PAIR_HOLD_MS = 3000;
const uint32_t IDENTIFY_MS = 2000;
// Advertising intervals from Apple's accessory guidelines, in 0.625 ms units.
const uint16_t FAST_INTERVAL = 244;   // 152.5 ms
const uint16_t SLOW_INTERVAL = 1636;  // 1022.5 ms

// ============ State ============

NimBLEServer* server;
NimBLECharacteristic* stockChar;

int count = -1;  // -1 until the first reading
bool lidOpen = false;

volatile bool isConnected = false;
volatile bool justConnected = false;
volatile bool justDisconnected = false;
volatile bool wantsIdentify = false;
volatile bool wantsPublish = false;
volatile uint16_t connHandle = 0;

uint32_t fastAdvertisingUntil = 0;
bool isPairing = false;  // fast advertising started by the button: the LED blinks
uint32_t identifyUntil = 0;
uint32_t connectFlashUntil = 0;
uint32_t closeBlinkUntil = 0;
uint32_t openFlashUntil = 0;

// A slot reading that's polled and only accepted once it has held still.
struct StableReader {
  uint32_t lastPoll = 0;
  int candidate = -1;
  uint32_t since = 0;
};

// ============ Debug output ============

#define debugf(...) \
  do { \
    if (DEBUG) Serial.printf(__VA_ARGS__); \
  } while (0)

const char* resetReasonText() {
  switch (esp_reset_reason()) {
    case ESP_RST_POWERON: return "power on";
    case ESP_RST_SW: return "software restart";
    case ESP_RST_PANIC: return "crash (panic)";
    case ESP_RST_INT_WDT:
    case ESP_RST_TASK_WDT:
    case ESP_RST_WDT: return "watchdog";
    case ESP_RST_BROWNOUT: return "BROWNOUT: the power supply sagged";
    case ESP_RST_DEEPSLEEP: return "woke from deep sleep";
    case ESP_RST_EXT: return "reset pin";
    default: return "other";
  }
}

// NimBLE reports HCI disconnect reasons as 0x200 + the HCI code.
const char* disconnectReasonText(int reason) {
  switch (reason & 0xFF) {
    case 0x08: return "supervision timeout (out of range or signal lost)";
    case 0x13: return "the iPhone closed the link";
    case 0x16: return "the charm closed the link";
    case 0x3D: return "MIC failure (encryption problem)";
    case 0x3E: return "connection failed to establish";
    default: return "see the Bluetooth HCI error codes";
  }
}

// ============ Slot sensors ============

bool readSlot(int slot, bool log) {
  if (SENSOR_POWER_FROM_GPIO) {
    digitalWrite(SLOT_POWER_PINS[slot], HIGH);
    delay(5);  // let the sensor settle
  }
  int blocked = 0;
  for (int i = 0; i < 5; i++) {
    if (digitalRead(SLOT_SIGNAL_PINS[slot]) == BLOCKED_LEVEL) blocked++;
    delay(2);
  }
  if (SENSOR_POWER_FROM_GPIO) digitalWrite(SLOT_POWER_PINS[slot], LOW);
  // 1 to 4 out of 5 means the edge sits right on the beam: the guide needs adjusting.
  if (log) debugf("  slot %d: blocked %d/5 -> %s%s\n", slot + 1, blocked, blocked >= 3 ? "filled" : "empty",
         blocked > 0 && blocked < 5 ? "  (unsteady)" : "");
  return blocked >= 3;
}

// SEN-2: the count is the number of filled slots. Sensors are read one at a time
// so the battery never has to power more than one.
// log: print each slot's reading. Off for repeated polling, which would flood the log.
int readCount(bool log) {
  int filled = 0;
  for (int slot = 0; slot < SLOT_COUNT; slot++) {
    if (readSlot(slot, log)) filled++;
  }
  return filled;
}

// ============ Stock packet ============

void publish() {
  uint8_t flags = 0;
  if (count >= 0) flags |= FLAG_COUNT_VALID;
  if (lidOpen) flags |= FLAG_LID_OPEN;
  uint8_t packet[4] = {PACKET_VERSION, flags, count >= 0 ? (uint8_t)count : UNKNOWN, UNKNOWN};
  stockChar->setValue(packet, sizeof(packet));
  if (isConnected) stockChar->notify();
  Serial.printf("Stock -> %02X %02X %02X %02X  (count %d, lid %s)%s\n",
                packet[0], packet[1], packet[2], packet[3], count, lidOpen ? "open" : "closed",
                isConnected ? "" : "  [not connected: stored for the next read]");
}

// ============ Bluetooth ============

class ServerCallbacks : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer* s, NimBLEConnInfo& info) override {
    connHandle = info.getConnHandle();
    isConnected = true;
    justConnected = true;
    debugf("[ble] connect from %s, interval %.2f ms, latency %d, timeout %d ms\n",
           info.getAddress().toString().c_str(), info.getConnInterval() * 1.25,
           info.getConnLatency(), info.getConnTimeout() * 10);
  }
  void onDisconnect(NimBLEServer* s, NimBLEConnInfo& info, int reason) override {
    isConnected = false;
    justDisconnected = true;
    debugf("[ble] disconnect, reason 0x%03X: %s\n", reason, disconnectReasonText(reason));
  }
  void onConnParamsUpdate(NimBLEConnInfo& info) override {
    debugf("[ble] connection params now: interval %.2f ms, latency %d, timeout %d ms\n",
           info.getConnInterval() * 1.25, info.getConnLatency(), info.getConnTimeout() * 10);
  }
  void onMTUChange(uint16_t mtu, NimBLEConnInfo& info) override {
    debugf("[ble] MTU %d\n", mtu);
  }
};

class StockCallbacks : public NimBLECharacteristicCallbacks {
  void onRead(NimBLECharacteristic* c, NimBLEConnInfo& info) override {
    debugf("[ble] Stock read\n");
  }
  void onSubscribe(NimBLECharacteristic* c, NimBLEConnInfo& info, uint16_t subValue) override {
    debugf("[ble] Stock notifications %s\n", subValue > 0 ? "on" : "off");
    if (subValue > 0) wantsPublish = true;  // spec: notify once when a central subscribes
  }
};

class CommandCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* c, NimBLEConnInfo& info) override {
    NimBLEAttValue value = c->getValue();
    debugf("[ble] Command write, %d byte(s), first 0x%02X\n", (int)value.size(),
           value.size() ? value[0] : 0);
    if (value.size() >= 1 && value[0] == CMD_IDENTIFY) wantsIdentify = true;
    // 0x02 and 0x03 (calibration) don't apply to per-slot sensors, so they're ignored.
  }
};

// pairing: advertise PAIRING_SERVICE, the only ID the app's pairing sheet lists, so
// with two charms in a room only the one whose button was just held shows up.
void startAdvertising(bool fast, bool pairing) {
  NimBLEAdvertising* adv = NimBLEDevice::getAdvertising();
  adv->stop();
  NimBLEAdvertisementData data;  // rebuilt each time, so the old service UUID doesn't linger
  data.setFlags(BLE_HS_ADV_F_DISC_GEN | BLE_HS_ADV_F_BREDR_UNSUP);
  data.addServiceUUID(pairing ? PAIRING_SERVICE : NANA_SERVICE);
  data.setName(ADVERTISED_NAME);
  adv->setAdvertisementData(data);
  uint16_t interval = fast ? FAST_INTERVAL : SLOW_INTERVAL;
  adv->setMinInterval(interval);
  adv->setMaxInterval(interval);
  adv->start();
  fastAdvertisingUntil = fast ? millis() + FAST_ADVERTISING_MS : 0;
  isPairing = pairing;
  Serial.println(pairing ? "Pairing mode for 30 s" : fast ? "Advertising fast for 30 s" : "Advertising slowly");
}

void startPairing() {
  startAdvertising(true, true);
}

void setupBluetooth() {
  NimBLEDevice::init("Nana");
  server = NimBLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());
  server->advertiseOnDisconnect(false);  // loop() restarts it with the right interval

  NimBLEService* nana = server->createService(NANA_SERVICE);
  stockChar = nana->createCharacteristic(STOCK_CHAR, NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);
  stockChar->setCallbacks(new StockCallbacks());
  uint8_t capacity = SLOT_COUNT;
  nana->createCharacteristic(CAPACITY_CHAR, NIMBLE_PROPERTY::READ)->setValue(&capacity, 1);
  nana->createCharacteristic(COMMAND_CHAR, NIMBLE_PROPERTY::WRITE)->setCallbacks(new CommandCallbacks());
  nana->start();

  // No Battery service: this board can't measure its battery without extra parts.
  // The app shows "Connected" without a percentage.
  NimBLEService* info = server->createService("180A");
  info->createCharacteristic("2A29", NIMBLE_PROPERTY::READ)->setValue("Nana");
  info->createCharacteristic("2A24", NIMBLE_PROPERTY::READ)->setValue("Nana C1");
  info->createCharacteristic("2A26", NIMBLE_PROPERTY::READ)->setValue("0.1.0");
  info->start();

  publish();                          // so a read before the first count is "unknown"
  startPairing();
}

void handleBluetoothEvents() {
  if (justConnected) {
    justConnected = false;
    fastAdvertisingUntil = 0;
    isPairing = false;
    connectFlashUntil = millis() + 150;
    Serial.println("iPhone connected");
    // Slower connection events save power. Values follow Apple's accessory guidelines:
    // 150-180 ms interval, latency 4, 6 s supervision timeout.
    server->updateConnParams(connHandle, 120, 144, 4, 600);
  }
  if (justDisconnected) {
    justDisconnected = false;
    Serial.println("iPhone disconnected");
    // Fast at first so the phone reconnects quickly if it's still near, as Apple's
    // accessory guidelines recommend; it drops to slow after 30 s.
    startAdvertising(true, false);
  }
  if (wantsPublish) {
    wantsPublish = false;
    publish();
  }
  if (wantsIdentify) {
    wantsIdentify = false;
    identifyUntil = millis() + IDENTIFY_MS;
    Serial.println("Identify");
  }
  if (fastAdvertisingUntil && !isConnected && (int32_t)(millis() - fastAdvertisingUntil) > 0) {
    startAdvertising(false, false);
  }
}

// ============ Lid and count ============

const char* lidPinText() {
  return digitalRead(LID_PIN) ? "HIGH" : "LOW";
}

// Reads the slots every pollMs and sends a count once it has held for stableMs.
void pollStable(StableReader& r, uint32_t pollMs, uint32_t stableMs) {
  if (millis() - r.lastPoll < pollMs) return;
  r.lastPoll = millis();
  int reading = readCount(false);
  if (reading != r.candidate) {
    r.candidate = reading;
    r.since = millis();
    debugf("[poll] slots now read %d, sending if it holds for %lu ms\n", reading, (unsigned long)stableMs);
  }
  if (r.candidate != count && millis() - r.since >= stableMs) {
    count = r.candidate;
    publish();
  }
}

bool readLidOpenRaw() {
  // Pull-up on: with a normally-open switch, magnet away leaves the pin HIGH.
  return digitalRead(LID_PIN) != LID_SHUT_LEVEL;
}

// Lid open: the slots are read every OPEN_POLL_MS and a count is sent live once it
// has held for OPEN_STABLE_MS. Lid shut: one last read, then the sensors stay off.
void updateWithLidSwitch() {
  static bool rawOpen = readLidOpenRaw();
  static uint32_t rawSince = millis();
  static uint32_t edges = 0;
  static bool needsFinalRead = true;  // also gives a count after power-on with the lid shut
  static StableReader reader;

  bool raw = readLidOpenRaw();
  if (raw != rawOpen) {
    rawOpen = raw;
    rawSince = millis();
    edges++;
    // Several edges for one movement is normal bounce. Edges with nobody touching
    // the lid mean a loose wire or a magnet at the edge of its range.
    debugf("[lid] raw %s (edge %lu)\n", raw ? "open" : "shut", (unsigned long)edges);
  }
  if (rawOpen != lidOpen && millis() - rawSince >= LID_DEBOUNCE_MS) {
    lidOpen = rawOpen;
    Serial.println(lidOpen ? "Lid opened: sensors on" : "Lid closed");
    if (lidOpen) {
      reader = StableReader();
      reader.candidate = count;
      reader.since = millis();
      openFlashUntil = millis() + 150;  // one flash: the sensors are on
      publish();  // SEN-4: an opening is logged; the count follows as it changes
    } else {
      needsFinalRead = true;
    }
  }

  if (lidOpen) {
    pollStable(reader, OPEN_POLL_MS, OPEN_STABLE_MS);
  } else if (needsFinalRead) {
    needsFinalRead = false;
    count = readCount(true);
    publish();  // sent after every close; the app ignores repeats
    closeBlinkUntil = millis() + 400;  // two quick blinks: the last count is in
    debugf("[lid] sensors off until the lid opens\n");
  }
}

void updateByPolling() {
  static StableReader reader;
  pollStable(reader, POLL_MS, STABLE_MS);
}

// ============ Button and LED ============

void updateButton() {
  static uint32_t pressedAt = 0;
  static bool handled = false;
  if (digitalRead(BUTTON_PIN) == LOW) {
    if (pressedAt == 0) pressedAt = millis();
    if (!handled && millis() - pressedAt >= PAIR_HOLD_MS) {
      handled = true;
      if (isConnected) {
        identifyUntil = millis() + IDENTIFY_MS;  // already paired and connected: just blink
      } else {
        startPairing();
      }
    }
  } else {
    pressedAt = 0;
    handled = false;
  }
}

void updateLed() {
  uint32_t now = millis();
  bool on = false;
  if ((int32_t)(identifyUntil - now) > 0) {
    on = (now / 100) % 2;  // fast blink
  } else if ((int32_t)(closeBlinkUntil - now) > 0) {
    on = ((closeBlinkUntil - now) / 100) % 2;  // two quick blinks after the lid shuts
  } else if ((int32_t)(connectFlashUntil - now) > 0) {
    on = true;  // one short flash on connect
  } else if ((int32_t)(openFlashUntil - now) > 0) {
    on = true;  // one flash when the lid opens
  } else if (isPairing && !isConnected) {
    on = (now / 500) % 2;  // slow blink while pairing
  }
  digitalWrite(LED_PIN, on ? LOW : HIGH);
}

// ============ Debug status and Serial commands ============

void printStatus() {
  NimBLEAdvertising* adv = NimBLEDevice::getAdvertising();
  Serial.printf("[status] up %lus | %s | %s | lid %s (pin %s) | count %d%s | heap %lu\n",
                (unsigned long)(millis() / 1000),
                isConnected ? "connected" : "not connected",
                !adv->isAdvertising() ? "not advertising"
                  : fastAdvertisingUntil ? "advertising fast" : "advertising slowly",
                !HAS_LID_SWITCH ? "n/a (HAS_LID_SWITCH off)" : lidOpen ? "open" : "shut",
                lidPinText(),
                count, lidOpen ? " (sensors on)" : "",
                (unsigned long)ESP.getFreeHeap());
}

void printHelp() {
  Serial.println("Commands: s status | r read slots and send | l lid pin for 10 s");
  Serial.println("          p pairing mode | i identify blink | h help");
}

// Prints the lid pin every 200 ms for 10 s, for checking the magnet's range.
void watchLidPin() {
  Serial.println("[lid] watching the pin for 10 s. Move the magnet slowly.");
  for (int i = 0; i < 50; i++) {
    bool open = readLidOpenRaw();
    Serial.printf("[lid] pin %s -> %s\n", lidPinText(), open ? "open" : "shut");
    delay(200);
  }
}

void handleSerialCommands() {
  while (Serial.available()) {
    char c = Serial.read();
    switch (c) {
      case 's': printStatus(); break;
      case 'r':
        Serial.println("[cmd] reading the slots now");
        count = readCount(true);
        publish();
        break;
      case 'l': watchLidPin(); break;
      case 'p': startPairing(); break;
      case 'i': identifyUntil = millis() + IDENTIFY_MS; break;
      case 'h': case '?': printHelp(); break;
      default: break;  // newlines and anything else
    }
  }
}

void updateDebug() {
  static uint32_t lastStatus = 0;
  if (!DEBUG) return;
  handleSerialCommands();
  if (millis() - lastStatus >= 5000) {
    lastStatus = millis();
    printStatus();
  }
}

// ============ Main ============

void setup() {
  Serial.begin(115200);
  // Never wait for the Serial Monitor. By default a print can block for 100 ms when the
  // board is on USB with nothing reading, which made the lid-open reads stall and burst.
  Serial.setTxTimeoutMs(0);
  setCpuFrequencyMhz(80);  // the lowest speed Bluetooth runs at; saves power

  if (USE_GROUND_PINS) {
    for (int i = 0; i < GROUND_PIN_COUNT; i++) {
      pinMode(GROUND_PINS[i], OUTPUT);
      digitalWrite(GROUND_PINS[i], LOW);
      gpio_set_drive_capability((gpio_num_t)GROUND_PINS[i], GPIO_DRIVE_CAP_3);
    }
  }
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, HIGH);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(LID_PIN, INPUT_PULLUP);
  for (int slot = 0; slot < SLOT_COUNT; slot++) {
    // Weakly held at the "empty" level, so a slot with no sensor attached reads
    // empty instead of floating and picking up noise. A connected sensor overrides it.
    pinMode(SLOT_SIGNAL_PINS[slot], BLOCKED_LEVEL == HIGH ? INPUT_PULLDOWN : INPUT_PULLUP);
    if (SENSOR_POWER_FROM_GPIO) {
      pinMode(SLOT_POWER_PINS[slot], OUTPUT);
      digitalWrite(SLOT_POWER_PINS[slot], LOW);
      gpio_set_drive_capability((gpio_num_t)SLOT_POWER_PINS[slot], GPIO_DRIVE_CAP_3);
    }
  }
  lidOpen = HAS_LID_SWITCH && readLidOpenRaw();
  if (DEBUG) {
    delay(1500);  // give the Serial Monitor time to reattach after a reset
    Serial.printf("\n[boot] reset reason: %s\n", resetReasonText());
    Serial.printf("[boot] lid switch %s, shut reads %s, lid now %s (pin %s)\n",
                  HAS_LID_SWITCH ? "on" : "off", LID_SHUT_LEVEL ? "HIGH" : "LOW",
                  readLidOpenRaw() ? "open" : "shut", lidPinText());
    Serial.printf("[boot] blocked reads %s, sensors powered %s, CPU %lu MHz\n",
                  BLOCKED_LEVEL ? "HIGH" : "LOW", SENSOR_POWER_FROM_GPIO ? "from pins" : "from 3V3",
                  (unsigned long)getCpuFrequencyMhz());
  }

  setupBluetooth();
  debugf("[boot] Bluetooth address %s\n", NimBLEDevice::getAddress().toString().c_str());
  Serial.println("Nana charm ready");
  if (DEBUG) printHelp();
}

void loop() {
  handleBluetoothEvents();
  if (HAS_LID_SWITCH) {
    updateWithLidSwitch();
  } else {
    updateByPolling();
  }
  updateButton();
  updateLed();
  updateDebug();
  delay(20);
}
