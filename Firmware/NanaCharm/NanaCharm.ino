// Nana charm firmware, proof of concept.
// Speaks the Bluetooth contract in Docs/BLE_SPEC.md (v1). Board: ESP32-C3 Super Mini.
// Wiring and the step-by-step build: Firmware/README.md
//
// How it behaves:
// - Stays connected to the iPhone all the time, so the app's left-behind nudge works.
// - The slot sensors are off almost all the time. With the lid switch, they're read
//   once, 2 s after the lid closes. Without it, they're read every second and a new
//   count is sent once it has held for 2 s.
// - The blue LED stays dark unless it's pairing, has just connected, or is asked to identify.

#include <NimBLEDevice.h>
#include "driver/gpio.h"

// ============ Settings you may need to change ============

// Turn on once the reed switch is wired between LID_PIN and GND.
const bool HAS_LID_SWITCH = false;

// What the S pin reads when a wrapper blocks the beam (found in step 1).
const int BLOCKED_LEVEL = HIGH;

// true:  each sensor's VCC goes to its own power pin, switched on only while reading.
// false: every sensor's VCC goes to 3V3 and stays on.
const bool SENSOR_POWER_FROM_GPIO = true;

const int SLOT_COUNT = 3;
const int SLOT_SIGNAL_PINS[SLOT_COUNT] = {4, 6, 0};
const int SLOT_POWER_PINS[SLOT_COUNT] = {5, 7, 1};
const int LID_PIN = 3;     // reed switch to a ground pin: LOW = lid shut
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

const uint8_t PACKET_VERSION = 1;
const uint8_t FLAG_COUNT_VALID = 1 << 0;
const uint8_t FLAG_LID_OPEN = 1 << 2;
const uint8_t UNKNOWN = 0xFF;
const uint8_t CMD_IDENTIFY = 0x01;

// ============ Timing ============

const uint32_t STABLE_MS = 2000;          // SEN-5: slots must hold still this long
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
uint32_t identifyUntil = 0;
uint32_t connectFlashUntil = 0;

// ============ Slot sensors ============

bool readSlot(int slot) {
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
  return blocked >= 3;
}

// SEN-2: the count is the number of filled slots. Sensors are read one at a time
// so the battery never has to power more than one.
int readCount() {
  int filled = 0;
  for (int slot = 0; slot < SLOT_COUNT; slot++) {
    if (readSlot(slot)) filled++;
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
  Serial.printf("Stock -> %02X %02X %02X %02X  (count %d, lid %s)\n",
                packet[0], packet[1], packet[2], packet[3], count, lidOpen ? "open" : "closed");
}

// ============ Bluetooth ============

class ServerCallbacks : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer* s, NimBLEConnInfo& info) override {
    connHandle = info.getConnHandle();
    isConnected = true;
    justConnected = true;
  }
  void onDisconnect(NimBLEServer* s, NimBLEConnInfo& info, int reason) override {
    isConnected = false;
    justDisconnected = true;
  }
};

class StockCallbacks : public NimBLECharacteristicCallbacks {
  void onSubscribe(NimBLECharacteristic* c, NimBLEConnInfo& info, uint16_t subValue) override {
    if (subValue > 0) wantsPublish = true;  // spec: notify once when a central subscribes
  }
};

class CommandCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* c, NimBLEConnInfo& info) override {
    NimBLEAttValue value = c->getValue();
    if (value.size() >= 1 && value[0] == CMD_IDENTIFY) wantsIdentify = true;
    // 0x02 and 0x03 (calibration) don't apply to per-slot sensors, so they're ignored.
  }
};

void startAdvertising(bool fast) {
  NimBLEAdvertising* adv = NimBLEDevice::getAdvertising();
  adv->stop();
  uint16_t interval = fast ? FAST_INTERVAL : SLOW_INTERVAL;
  adv->setMinInterval(interval);
  adv->setMaxInterval(interval);
  adv->start();
  fastAdvertisingUntil = fast ? millis() + FAST_ADVERTISING_MS : 0;
  Serial.println(fast ? "Advertising fast (pairing) for 30 s" : "Advertising slowly");
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

  NimBLEAdvertising* adv = NimBLEDevice::getAdvertising();
  adv->addServiceUUID(NANA_SERVICE);  // the app's pairing sheet finds the charm by this
  adv->setName("Nana");               // neutral, never describes the contents
  publish();                          // so a read before the first count is "unknown"
  startAdvertising(true);
}

void handleBluetoothEvents() {
  if (justConnected) {
    justConnected = false;
    fastAdvertisingUntil = 0;
    connectFlashUntil = millis() + 150;
    Serial.println("iPhone connected");
    // Slower connection events save power. Values follow Apple's accessory guidelines:
    // 150-180 ms interval, latency 4, 6 s supervision timeout.
    server->updateConnParams(connHandle, 120, 144, 4, 600);
  }
  if (justDisconnected) {
    justDisconnected = false;
    Serial.println("iPhone disconnected");
    startAdvertising(false);  // keep advertising so the phone reconnects when it's back
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
    startAdvertising(false);
  }
}

// ============ Lid and count ============

bool readLidOpenRaw() {
  return digitalRead(LID_PIN) == HIGH;  // magnet away: reed opens, pull-up wins
}

void updateWithLidSwitch() {
  static bool rawOpen = readLidOpenRaw();
  static uint32_t rawSince = millis();
  static uint32_t changedAt = millis();
  static bool needsReading = true;  // read once after power-on

  bool raw = readLidOpenRaw();
  if (raw != rawOpen) {
    rawOpen = raw;
    rawSince = millis();
  }
  if (rawOpen != lidOpen && millis() - rawSince >= LID_DEBOUNCE_MS) {
    lidOpen = rawOpen;
    changedAt = millis();
    Serial.println(lidOpen ? "Lid opened" : "Lid closed");
    if (lidOpen) {
      publish();  // SEN-4: an opening is logged, the count doesn't change
    } else {
      needsReading = true;
    }
  }
  if (!lidOpen && needsReading && millis() - changedAt >= STABLE_MS) {
    needsReading = false;
    count = readCount();
    publish();  // sent after every close; the app ignores repeats
  }
}

void updateByPolling() {
  static uint32_t lastPoll = 0;
  static int candidate = -1;
  static uint32_t candidateSince = 0;

  if (millis() - lastPoll < POLL_MS) return;
  lastPoll = millis();
  int reading = readCount();
  if (reading != candidate) {
    candidate = reading;
    candidateSince = millis();
  }
  if (candidate != count && millis() - candidateSince >= STABLE_MS) {
    count = candidate;
    publish();
  }
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
        startAdvertising(true);
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
  } else if ((int32_t)(connectFlashUntil - now) > 0) {
    on = true;  // one short flash on connect
  } else if (fastAdvertisingUntil && !isConnected) {
    on = (now / 500) % 2;  // slow blink while pairing
  }
  digitalWrite(LED_PIN, on ? LOW : HIGH);
}

// ============ Main ============

void setup() {
  Serial.begin(115200);
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
    pinMode(SLOT_SIGNAL_PINS[slot], INPUT);
    if (SENSOR_POWER_FROM_GPIO) {
      pinMode(SLOT_POWER_PINS[slot], OUTPUT);
      digitalWrite(SLOT_POWER_PINS[slot], LOW);
      gpio_set_drive_capability((gpio_num_t)SLOT_POWER_PINS[slot], GPIO_DRIVE_CAP_3);
    }
  }
  lidOpen = HAS_LID_SWITCH && readLidOpenRaw();

  setupBluetooth();
  Serial.println("Nana charm ready");
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
  delay(20);
}
