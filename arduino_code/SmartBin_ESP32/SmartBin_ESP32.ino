/*
 * SmartBin - IoT Waste Management System
 * ESP32 Code with Ultrasonic Sensor, Servo Motor, Buzzer, and Firebase
 * MERGED VERSION - Uses proven lid control from team member + Firebase monitoring
 */

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <ESP32Servo.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ===== WiFi Credentials =====
#define WIFI_SSID "GlobeAtHome_D3FE0_2.4"    // Your Globe At Home WiFi (2.4GHz)
#define WIFI_PASSWORD "c2SVUHDU"              // Your WiFi password

// ===== Firebase Credentials =====
#define API_KEY "AIzaSyCO8ru2HgT_AIs25e3Jrr6TNWNa3LJua0A"
#define DATABASE_URL "https://smartbin-c8ef7-default-rtdb.asia-southeast1.firebasedatabase.app/"

// ===== Pin Definitions =====
// Sensor 1: Lid Control (outside bin, detects hand)
const int trigPin = 26;      // Ultrasonic sensor 1 trigger pin
const int echoPin = 25;      // Ultrasonic sensor 1 echo pin

// Sensor 2: Fill Level Monitoring (inside bin, points down)
const int trigPin2 = 27;     // Ultrasonic sensor 2 trigger pin
const int echoPin2 = 33;     // Ultrasonic sensor 2 echo pin

const int servoPin = 14;     // Servo motor pin
// const int buzzerPin = 13;    // Buzzer pin (DISABLED - buy buzzer hardware later)

// ===== Configuration Settings (Using Team Member's Proven Values) =====
const int openAngle = 100;           // Servo angle when lid is open (from team member)
const int closeAngle = 0;            // Servo angle when lid is closed (from team member)
const int distanceThreshold = 15;    // Distance in cm to trigger lid opening (adjusted for 9cm bin)

// Additional settings for monitoring
const int binHeight = 9;             // Height of bin in cm (measured: sensor to bottom when empty)
const int fullThreshold = 80;        // Percentage when bin is considered full

// ===== Global Variables =====
Servo lidServo;
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Distance measurement variables
// Sensor 1: Lid control
long duration;
float distance;
float averageDistance;
float distanceReadings[3]; // Array to store last 3 readings for stability

// Sensor 2: Fill level monitoring
long duration2;
float fillDistance;
float fillDistanceReadings[3]; // Array for stable fill readings

// Firebase sync variables
unsigned long sendDataPrevMillis = 0;
bool signupOK = false;
int currentFillLevel = 0;
String currentStatus = "EMPTY";
bool isBinFull = false;
bool wifiConnected = false;

// ===== Function Prototypes =====
float readDistance();           // Sensor 1: Lid control distance reading
float readFillDistance();       // Sensor 2: Fill level distance reading
void firebaseTask(void *parameter);  // Background task for Firebase

void setup() {
  // Initialize Serial Monitor (using team member's baud rate for consistency)
  Serial.begin(9600);
  Serial.println("SmartBin System Starting...");

  // Initialize Pins
  // Sensor 1: Lid control
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  
  // Sensor 2: Fill level monitoring
  pinMode(trigPin2, OUTPUT);
  pinMode(echoPin2, INPUT);
  
  // pinMode(buzzerPin, OUTPUT);  // DISABLED - buzzer not connected yet
  
  // Initialize Servo
  lidServo.attach(servoPin);
  lidServo.write(closeAngle); // Start with lid closed
  delay(500); // Give servo time to reach position (from team member's code)
  
  Serial.println("Lid initialized and closed.");

  // Connect to WiFi in background (non-blocking)
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.println("WiFi connecting in background...");

  Serial.println("SmartBin System Ready!");
  Serial.println("================================");
  
  // Create Firebase task on separate core (ESP32 has 2 cores!)
  // Core 0: Firebase updates (background)
  // Core 1: Lid control (main loop - never blocked!)
  xTaskCreatePinnedToCore(
    firebaseTask,   // Function to run
    "FirebaseTask", // Task name
    10000,          // Stack size
    NULL,           // Parameters
    1,              // Priority
    NULL,           // Task handle
    0               // Core 0 (background)
  );
}

void loop() {
  // === PART 1: Lid Control (EXACTLY like team member's working code) ===
  // Measure the distance three times to get a stable reading
  for (int i = 0; i < 3; i++) {
    distanceReadings[i] = readDistance();
    delay(20); // Small delay between readings
  }

  // Calculate the average distance
  averageDistance = (distanceReadings[0] + distanceReadings[1] + distanceReadings[2]) / 3;

  // Print the average distance for debugging
  Serial.print("Average Distance: ");
  Serial.print(averageDistance);
  Serial.println(" cm");

  // Control the servo based on the averaged distance
  if (averageDistance <= distanceThreshold && averageDistance > 0) {
    Serial.println("Object Detected! Opening Lid.");
    lidServo.write(openAngle); // Rotate the servo to the open position
    delay(3000); // Keep the lid open for 3 seconds
  } else {
    lidServo.write(closeAngle); // Keep the servo in the closed position
  }
  
  // === PART 2: Bin Fill Level Monitoring (using SECOND sensor) ===
  // Read from sensor 2 (mounted inside, pointing down)
  for (int i = 0; i < 3; i++) {
    fillDistanceReadings[i] = readFillDistance();
    delay(20);
  }
  
  // Calculate average fill distance
  fillDistance = (fillDistanceReadings[0] + fillDistanceReadings[1] + fillDistanceReadings[2]) / 3;
  
  // Calculate fill level
  if (fillDistance > 0 && fillDistance <= binHeight) {
    int wasteHeight = binHeight - fillDistance;
    currentFillLevel = (wasteHeight * 100) / binHeight;
    currentFillLevel = constrain(currentFillLevel, 0, 100);
    
    if (currentFillLevel >= fullThreshold) {
      currentStatus = "FULL";
      isBinFull = true;
    } else if (currentFillLevel >= 50) {
      currentStatus = "OK";
      isBinFull = false;
    } else {
      currentStatus = "EMPTY";
      isBinFull = false;
    }
    
    // Print fill level info
    Serial.print("Fill Distance: ");
    Serial.print(fillDistance);
    Serial.print(" cm | Fill Level: ");
    Serial.print(currentFillLevel);
    Serial.print("% | Status: ");
    Serial.println(currentStatus);
  }
  
  // === PART 3: Firebase Data Sync ===
  // Running on separate core - doesn't block this loop!
  
  delay(100); // A short delay in the main loop
}

// ===== Function: Read Distance (Team Member's Proven Method) =====
/*
 * readDistance()
 * Triggers the ultrasonic sensor and returns the measured distance in cm.
 * Uses team member's proven formula for accurate readings.
 */
float readDistance() {
  // Send a 10-microsecond pulse to trigger the sensor
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  // Measure the time it takes for the echo pulse to return
  duration = pulseIn(echoPin, HIGH);

  // Calculate the distance in centimeters
  // 0.0343 cm/µs is the speed of sound (from team member's code)
  distance = duration * 0.0343 / 2;

  return distance;
}

// ===== Function: Read Fill Distance (Second Sensor) =====
/*
 * readFillDistance()
 * Reads distance from second sensor (inside bin, pointing down)
 * Measures the distance from sensor to trash surface
 */
float readFillDistance() {
  // Send a 10-microsecond pulse to trigger sensor 2
  digitalWrite(trigPin2, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin2, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin2, LOW);

  // Measure the time it takes for the echo pulse to return
  duration2 = pulseIn(echoPin2, HIGH);

  // Calculate the distance in centimeters
  float dist = duration2 * 0.0343 / 2;

  return dist;
}

// ===== Function: Sound Buzzer =====
// DISABLED - Buzzer hardware not connected yet
// Uncomment this when you add the buzzer component
/*
void soundBuzzer() {
  // Create a beeping pattern
  tone(buzzerPin, 1000, 200); // Beep at 1000Hz for 200ms
  delay(300);
  noTone(buzzerPin);
  delay(700);
}
*/

// ===== Firebase Background Task (Runs on Core 0) =====
void firebaseTask(void *parameter) {
  // Wait for WiFi connection
  Serial.println("[Firebase] Waiting for WiFi...");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.print("[Firebase] WiFi Connected! IP: ");
  Serial.println(WiFi.localIP());
  wifiConnected = true;
  
  // Configure Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  
  // Initialize Firebase
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  // Sign in anonymously
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("[Firebase] Connected successfully!");
  } else {
    Serial.println("[Firebase] Using database URL directly");
  }
  signupOK = true;
  
  // Main Firebase loop - runs forever on Core 0
  while (true) {
    if (Firebase.ready() && signupOK) {
      // Calculate estimated time
      String estimatedTime = "7+ days";
      if (currentFillLevel >= 80) {
        estimatedTime = "1-2 hours";
      } else if (currentFillLevel >= 60) {
        estimatedTime = "6-12 hours";
      } else if (currentFillLevel >= 40) {
        estimatedTime = "1-2 days";
      } else if (currentFillLevel >= 20) {
        estimatedTime = "3-5 days";
      }
      
      // Update Firebase
      Firebase.RTDB.setInt(&fbdo, "bins/kitchen_bin/fill_level", currentFillLevel);
      Firebase.RTDB.setString(&fbdo, "bins/kitchen_bin/status", currentStatus);
      Firebase.RTDB.setString(&fbdo, "bins/kitchen_bin/estimated_full_in", estimatedTime);
      Firebase.RTDB.setString(&fbdo, "bins/kitchen_bin/name", "Kitchen Bin");
      
      Serial.println("[Firebase] ✓ Data synced");
    }
    
    // Update every 10 seconds
    delay(10000);
  }
}

