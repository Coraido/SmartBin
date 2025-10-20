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
#define WIFI_SSID "YOUR_WIFI_SSID"        // Replace with your WiFi name
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD" // Replace with your WiFi password

// ===== Firebase Credentials =====
#define API_KEY "AIzaSyCO8ru2HgT_AIs25e3Jrr6TNWNa3LJua0A"
#define DATABASE_URL "https://smartbin-c8ef7-default-rtdb.asia-southeast1.firebasedatabase.app/"

// ===== Pin Definitions (Using Team Member's Pin Layout) =====
const int trigPin = 26;      // Ultrasonic sensor trigger pin
const int echoPin = 25;      // Ultrasonic sensor echo pin
const int servoPin = 14;     // Servo motor pin (from team member's code)
const int buzzerPin = 13;    // Buzzer pin (changed to avoid conflict)

// ===== Configuration Settings (Using Team Member's Proven Values) =====
const int openAngle = 100;           // Servo angle when lid is open (from team member)
const int closeAngle = 0;            // Servo angle when lid is closed (from team member)
const int distanceThreshold = 20;    // Distance in cm to trigger lid opening (from team member)

// Additional settings for monitoring
const int binHeight = 30;            // Height of bin in cm
const int fullThreshold = 80;        // Percentage when bin is considered full

// ===== Global Variables =====
Servo lidServo;
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Distance measurement variables (from team member's code)
long duration;
float distance;
float averageDistance;
float distanceReadings[3]; // Array to store last 3 readings for stability

// Firebase sync variables
unsigned long sendDataPrevMillis = 0;
bool signupOK = false;
int currentFillLevel = 0;
String currentStatus = "EMPTY";
bool isBinFull = false;

// ===== Function Prototypes =====
float readDistance();           // From team member - proven distance reading
void controlLid();              // From team member - proven lid control
void soundBuzzer();            // Buzzer alert
void updateFirebase();         // Firebase sync
void checkBinStatus();         // Monitor bin fill level

void setup() {
  // Initialize Serial Monitor (using team member's baud rate for consistency)
  Serial.begin(9600);
  Serial.println("SmartBin System Starting...");

  // Initialize Pins (using team member's pin configuration)
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(buzzerPin, OUTPUT);
  
  // Initialize Servo (using team member's proven method)
  lidServo.attach(servoPin);
  lidServo.write(closeAngle); // Start with lid closed
  delay(500); // Give servo time to reach position (from team member's code)
  
  Serial.println("Lid initialized and closed.");

  // Connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());

  // Configure Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  // Sign up to Firebase
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Firebase signup successful");
    signupOK = true;
  } else {
    Serial.printf("Firebase signup failed: %s\n", config.signer.signupError.message.c_str());
  }

  // Assign the callback function for token generation
  config.token_status_callback = tokenStatusCallback;
  
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Serial.println("SmartBin System Ready!");
}

void loop() {
  // === PART 1: Lid Control (Using Team Member's Proven Method) ===
  controlLid();
  
  // === PART 2: Bin Fill Level Monitoring ===
  checkBinStatus();
  
  // === PART 3: Firebase Data Sync (Every 5 seconds) ===
  if (Firebase.ready() && signupOK && (millis() - sendDataPrevMillis > 5000 || sendDataPrevMillis == 0)) {
    sendDataPrevMillis = millis();
    updateFirebase();
  }
  
  // === PART 4: Buzzer Alert (If bin is full) ===
  if (isBinFull) {
    soundBuzzer();
  }
  
  delay(100); // Short delay in main loop (from team member's code)
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

// ===== Function: Control Lid (Team Member's Proven Logic) =====
/*
 * controlLid()
 * Uses averaged distance readings for stable lid control.
 * Opens lid when object is within threshold, keeps open for 3 seconds.
 */
void controlLid() {
  // Measure distance three times for stability (team member's method)
  for (int i = 0; i < 3; i++) {
    distanceReadings[i] = readDistance();
    delay(20); // Small delay between readings
  }

  // Calculate average distance for more reliable detection
  averageDistance = (distanceReadings[0] + distanceReadings[1] + distanceReadings[2]) / 3;

  // Print average distance for debugging
  Serial.print("Average Distance: ");
  Serial.print(averageDistance);
  Serial.println(" cm");

  // Control servo based on averaged distance (team member's logic)
  if (averageDistance <= distanceThreshold && averageDistance > 0) {
    Serial.println("Object Detected! Opening Lid.");
    lidServo.write(openAngle);  // Open the lid
    delay(3000);                // Keep open for 3 seconds
  } else {
    lidServo.write(closeAngle); // Keep closed
  }
}

// ===== Function: Sound Buzzer =====
void soundBuzzer() {
  // Create a beeping pattern
  tone(BUZZER_PIN, 1000, 200); // Beep at 1000Hz for 200ms
  delay(300);
  noTone(BUZZER_PIN);
  delay(700);
}

// ===== Function: Check Bin Fill Level Status =====
/*
 * checkBinStatus()
 * Monitors the bin fill level by measuring the distance from sensor to waste.
 * Separate from lid control to avoid interference.
 */
void checkBinStatus() {
  // Take a single reading for fill level monitoring
  float fillDistance = readDistance();
  
  // Calculate fill level (distance from sensor to waste)
  if (fillDistance > 0 && fillDistance <= binHeight) {
    int wasteHeight = binHeight - fillDistance;
    currentFillLevel = (wasteHeight * 100) / binHeight;
    
    // Ensure fill level is between 0 and 100
    currentFillLevel = constrain(currentFillLevel, 0, 100);
    
    // Determine status based on fill level
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
    
    Serial.print("Fill Distance: ");
    Serial.print(fillDistance);
    Serial.print(" cm | Fill Level: ");
    Serial.print(currentFillLevel);
    Serial.print("% | Status: ");
    Serial.println(currentStatus);
  }
}

// ===== Function: Update Firebase =====
void updateFirebase() {
  // Calculate estimated time until full
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
  
  // Update bin data in Firebase
  if (Firebase.RTDB.setInt(&fbdo, "bins/kitchen_bin/fill_level", currentFillLevel)) {
    Serial.println("Fill level updated");
  } else {
    Serial.println("Failed to update fill level: " + fbdo.errorReason());
  }
  
  if (Firebase.RTDB.setString(&fbdo, "bins/kitchen_bin/status", currentStatus)) {
    Serial.println("Status updated");
  } else {
    Serial.println("Failed to update status: " + fbdo.errorReason());
  }
  
  if (Firebase.RTDB.setString(&fbdo, "bins/kitchen_bin/name", "Kitchen Bin")) {
    Serial.println("Name updated");
  } else {
    Serial.println("Failed to update name: " + fbdo.errorReason());
  }
  
  if (Firebase.RTDB.setString(&fbdo, "bins/kitchen_bin/estimated_full_in", estimatedTime)) {
    Serial.println("Estimated time updated");
  } else {
    Serial.println("Failed to update estimated time: " + fbdo.errorReason());
  }
  
  // Update timestamp
  if (Firebase.RTDB.setTimestamp(&fbdo, "bins/kitchen_bin/last_updated")) {
    Serial.println("Timestamp updated");
  } else {
    Serial.println("Failed to update timestamp: " + fbdo.errorReason());
  }
  
  Serial.println("--------------------------------");
}
