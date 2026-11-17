// Step 2: all three slot sensors, and the lid switch if it's wired.
// Each sensor is powered from its own pin and switched on only while it's read,
// which is how the real firmware saves battery.
//
// Wiring: see the pin table in Firmware/README.md.
// Open Tools > Serial Monitor at 115200 baud.

#include "driver/gpio.h"

// What the S pin reads when a wrapper blocks the beam. You found this in step 1.
const int BLOCKED_LEVEL = HIGH;

const int SLOT_COUNT = 3;
const int SLOT_SIGNAL_PINS[SLOT_COUNT] = {4, 6, 0};
const int SLOT_POWER_PINS[SLOT_COUNT] = {5, 7, 1};
const int LID_PIN = 3;  // reed switch between this pin and a ground pin

// Extra ground pins. The board has only one GND pin, so until there's a breadboard,
// these pins are held at 0 V and act as ground: slot 2's G -> 10, slot 3's G -> 20,
// the reed switch's second wire -> 21. Slot 1's G uses the real GND pin.
const int GROUND_PIN_COUNT = 3;
const int GROUND_PINS[GROUND_PIN_COUNT] = {10, 20, 21};

bool readSlot(int slot) {
  digitalWrite(SLOT_POWER_PINS[slot], HIGH);
  delay(5);  // let the sensor's light and receiver settle
  int blocked = 0;
  for (int i = 0; i < 5; i++) {
    if (digitalRead(SLOT_SIGNAL_PINS[slot]) == BLOCKED_LEVEL) blocked++;
    delay(2);
  }
  digitalWrite(SLOT_POWER_PINS[slot], LOW);
  return blocked >= 3;  // majority of 5 samples
}

void setup() {
  Serial.begin(115200);
  for (int i = 0; i < GROUND_PIN_COUNT; i++) {
    pinMode(GROUND_PINS[i], OUTPUT);
    digitalWrite(GROUND_PINS[i], LOW);
    gpio_set_drive_capability((gpio_num_t)GROUND_PINS[i], GPIO_DRIVE_CAP_3);
  }
  for (int slot = 0; slot < SLOT_COUNT; slot++) {
    pinMode(SLOT_SIGNAL_PINS[slot], INPUT);
    pinMode(SLOT_POWER_PINS[slot], OUTPUT);
    digitalWrite(SLOT_POWER_PINS[slot], LOW);
    gpio_set_drive_capability((gpio_num_t)SLOT_POWER_PINS[slot], GPIO_DRIVE_CAP_3);  // strongest output
  }
  pinMode(LID_PIN, INPUT_PULLUP);
}

void loop() {
  int count = 0;
  Serial.print("Slots: ");
  for (int slot = 0; slot < SLOT_COUNT; slot++) {
    bool filled = readSlot(slot);
    if (filled) count++;
    Serial.print(filled ? "[X] " : "[ ] ");
  }
  Serial.print(" count = ");
  Serial.print(count);
  // Magnet near (lid shut) closes the reed switch and pulls the pin LOW.
  Serial.print("   lid: ");
  Serial.println(digitalRead(LID_PIN) == LOW ? "closed" : "open (or no reed switch)");
  delay(500);
}
