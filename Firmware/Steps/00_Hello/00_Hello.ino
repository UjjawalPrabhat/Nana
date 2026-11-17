// Step 0: is the board alive?
// Blinks the small blue light on the board once a second and prints a message.
// Nothing needs to be wired.

const int LED_PIN = 8;  // the blue light on the board, LOW = on

void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
}

void loop() {
  digitalWrite(LED_PIN, LOW);   // light on
  Serial.println("Hello from the Nana charm board. Light ON");
  delay(500);
  digitalWrite(LED_PIN, HIGH);  // light off
  Serial.println("Light OFF");
  delay(500);
}
