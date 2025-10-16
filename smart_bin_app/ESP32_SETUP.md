# SmartBin ESP32 Arduino Code
# This code reads ultrasonic sensor data and sends it to Firebase

## Hardware Setup:
- ESP32 microcontroller
- HC-SR04 Ultrasonic Sensor
- LED (optional, for status indication)
- Bin container

## Connections:
- Ultrasonic Sensor VCC -> ESP32 5V
- Ultrasonic Sensor GND -> ESP32 GND
- Ultrasonic Sensor TRIG -> ESP32 GPIO 5 (D5)
- Ultrasonic Sensor ECHO -> ESP32 GPIO 18 (D18)
- LED Anode -> ESP32 GPIO 2 (D2)
- LED Cathode -> ESP32 GND (with 220Ω resistor)

## Arduino Libraries Required:
1. WiFi.h (built-in)
2. FirebaseESP32.h
3. ArduinoJson.h

## Installation Steps:
1. Install Arduino IDE
2. Add ESP32 board support:
   - File -> Preferences -> Additional Board Manager URLs
   - Add: https://dl.espressif.com/dl/package_esp32_index.json
3. Install Firebase ESP32 library:
   - Tools -> Manage Libraries -> Search "Firebase ESP32 Client"
4. Install ArduinoJson:
   - Tools -> Manage Libraries -> Search "ArduinoJson"

## Firebase Configuration:
1. Go to Firebase Console (console.firebase.google.com)
2. Select your SmartBin project
3. Go to Project Settings -> Service Accounts
4. Generate new private key
5. Get your Firebase URL and API Key
6. Update the credentials in the code below

---

## Arduino Code (esp32_smartbin.ino):

```cpp
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

// WiFi credentials
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

// Firebase credentials
#define API_KEY "YOUR_FIREBASE_API_KEY"
#define DATABASE_URL "YOUR_FIREBASE_DATABASE_URL" // e.g., "https://smartbin-xxxxx.firebaseio.com"
#define USER_EMAIL "YOUR_EMAIL"
#define USER_PASSWORD "YOUR_PASSWORD"

// Ultrasonic Sensor Pins
#define TRIG_PIN 5
#define ECHO_PIN 18

// LED Pin (optional)
#define LED_PIN 2

// Bin dimensions (in cm)
#define BIN_HEIGHT 30  // Total height of your bin in centimeters
#define SENSOR_OFFSET 5  // Distance from sensor to bin opening

// Firebase objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Bin ID (create this in Firestore first or get it from app)
String binId = "YOUR_BIN_ID";  // Replace with actual bin ID from Firestore

// Timing variables
unsigned long sendDataPrevMillis = 0;
const long sendDataInterval = 10000; // Send data every 10 seconds

void setup() {
  Serial.begin(115200);
  
  // Initialize pins
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(LED_PIN, OUTPUT);
  
  // Connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    digitalWrite(LED_PIN, HIGH);
    delay(250);
    digitalWrite(LED_PIN, LOW);
    delay(250);
  }
  
  Serial.println();
  Serial.print("Connected! IP: ");
  Serial.println(WiFi.localIP());
  digitalWrite(LED_PIN, HIGH);
  
  // Configure Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  
  // Initialize Firebase
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  Serial.println("Firebase initialized!");
}

void loop() {
  // Check if it's time to send data
  if (millis() - sendDataPrevMillis > sendDataInterval || sendDataPrevMillis == 0) {
    sendDataPrevMillis = millis();
    
    // Read distance from ultrasonic sensor
    long distance = getDistance();
    
    // Calculate fill level percentage
    int fillLevel = calculateFillLevel(distance);
    
    // Print to Serial Monitor
    Serial.print("Distance: ");
    Serial.print(distance);
    Serial.print(" cm, Fill Level: ");
    Serial.print(fillLevel);
    Serial.println("%");
    
    // Send data to Firebase
    if (Firebase.ready()) {
      sendToFirebase(fillLevel);
    }
    
    // LED indicator based on fill level
    blinkLED(fillLevel);
  }
}

// Function to measure distance using ultrasonic sensor
long getDistance() {
  // Clear the trigger pin
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  
  // Send 10us pulse to trigger
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  
  // Read the echo pin
  long duration = pulseIn(ECHO_PIN, HIGH, 30000); // Timeout after 30ms
  
  // Calculate distance in cm
  long distance = duration * 0.034 / 2;
  
  // Validate reading
  if (distance == 0 || distance > 400) {
    Serial.println("Invalid reading, using previous value");
    return -1; // Invalid reading
  }
  
  return distance;
}

// Function to calculate fill level percentage
int calculateFillLevel(long distance) {
  if (distance < 0) return -1; // Invalid reading
  
  // Calculate empty space from sensor
  long emptySpace = distance - SENSOR_OFFSET;
  
  // Ensure empty space is within valid range
  if (emptySpace < 0) emptySpace = 0;
  if (emptySpace > BIN_HEIGHT) emptySpace = BIN_HEIGHT;
  
  // Calculate fill percentage (inverted: less distance = more full)
  int fillLevel = 100 - ((emptySpace * 100) / BIN_HEIGHT);
  
  // Constrain between 0 and 100
  if (fillLevel < 0) fillLevel = 0;
  if (fillLevel > 100) fillLevel = 100;
  
  return fillLevel;
}

// Function to send data to Firebase Firestore
void sendToFirebase(int fillLevel) {
  String path = "/bins/" + binId;
  
  // Create JSON object
  FirebaseJson json;
  json.set("fillLevel", fillLevel);
  json.set("lastUpdated", (int)time(nullptr));
  
  // Determine status
  String status;
  if (fillLevel >= 80) status = "FULL";
  else if (fillLevel >= 40) status = "OK";
  else status = "EMPTY";
  json.set("status", status);
  
  // Calculate estimated time
  String estimatedTime;
  if (fillLevel >= 95) estimatedTime = "1-2 hours";
  else if (fillLevel >= 80) estimatedTime = "3-6 hours";
  else if (fillLevel >= 50) estimatedTime = "1-2 days";
  else if (fillLevel >= 30) estimatedTime = "3-5 days";
  else estimatedTime = "7+ days";
  json.set("estimatedFullTime", estimatedTime);
  
  // Update Firebase
  if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", path.c_str(), json.raw(), "fillLevel,status,estimatedFullTime,lastUpdated")) {
    Serial.println("Data sent successfully!");
  } else {
    Serial.print("Failed to send data: ");
    Serial.println(fbdo.errorReason());
  }
}

// LED status indicator
void blinkLED(int fillLevel) {
  if (fillLevel >= 80) {
    // FULL - Rapid blinking
    for (int i = 0; i < 3; i++) {
      digitalWrite(LED_PIN, HIGH);
      delay(100);
      digitalWrite(LED_PIN, LOW);
      delay(100);
    }
  } else if (fillLevel >= 40) {
    // OK - Slow blink
    digitalWrite(LED_PIN, HIGH);
    delay(500);
    digitalWrite(LED_PIN, LOW);
  } else {
    // EMPTY - Solid on
    digitalWrite(LED_PIN, HIGH);
  }
}
```

## Testing Steps:

1. **Upload Code to ESP32:**
   - Connect ESP32 to computer via USB
   - Select correct board and port in Arduino IDE
   - Upload the code

2. **Monitor Serial Output:**
   - Open Serial Monitor (115200 baud)
   - Check WiFi connection status
   - Verify distance readings and fill level calculations

3. **Test Sensor:**
   - Place hand at different heights above sensor
   - Observe fill level changes in Serial Monitor

4. **Verify Firebase Connection:**
   - Check Firebase Console for data updates
   - Verify app receives real-time updates

## Troubleshooting:

- **WiFi won't connect:** Check SSID and password
- **No sensor readings:** Check wiring connections
- **Firebase errors:** Verify API key and database URL
- **Inaccurate readings:** Adjust BIN_HEIGHT and SENSOR_OFFSET values

## Calibration:

1. Measure your bin height accurately
2. Update BIN_HEIGHT constant
3. Measure distance from sensor to bin opening
4. Update SENSOR_OFFSET constant
5. Test with empty and full bin
6. Adjust values as needed

## Notes:

- Ultrasonic sensors work best with flat surfaces
- Avoid loose trash bags that may move
- Keep sensor clean for accurate readings
- Consider using multiple sensors for large bins
