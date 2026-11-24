// Step 1: one slot sensor.
// Finds out what the sensor reads when a wrapper blocks it.
//
// Wiring (sensor cable -> Super Mini):
//   VCC / +       -> 3V3   (never 5V: the signal would then be 5V and can damage the pin)
//   GND / -       -> GND
//   S / SIGNAL    -> GPIO4
//
// Open Tools > Serial Monitor at 115200 baud.

const int SENSOR_PIN = 4;
const int LED_PIN = 8;  // onboard blue LED, LOW = on

void setup() {
  Serial.begin(115200);
  pinMode(SENSOR_PIN, INPUT);
  pinMode(LED_PIN, OUTPUT);
}

void loop() {
  int value = digitalRead(SENSOR_PIN);
  digitalWrite(LED_PIN, value == HIGH ? LOW : HIGH);  // blue LED on while the pin reads HIGH
  Serial.println(value == HIGH ? "HIGH (1)" : "LOW (0)");
  delay(200);
}
