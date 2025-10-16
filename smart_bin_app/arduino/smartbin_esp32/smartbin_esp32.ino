// Simplified ESP32 code for SmartBin
// This is a basic version that works with Firebase Realtime Database

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// WiFi Configuration
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// Firebase Configuration (use your project URL)
const char* firebaseHost = "https://smartbin-xxxxx.firebaseio.com"; // Replace with your Firebase URL
const char* firebaseAuth = "YOUR_DATABASE_SECRET_OR_API_KEY"; // Get from Firebase Console

// Ultrasonic Sensor Pins
const int trigPin = 5;
const int echoPin = 18;

// LED Pin
const int ledPin = 2;

// Bin Configuration
const int BIN_HEIGHT = 30; // Total bin height in cm
const int SENSOR_OFFSET = 5; // Distance from sensor to bin top

// Bin ID - Create this in your Firebase Firestore manually first
String binId = "bin001"; // Change this to match your bin ID in Firestore

void setup() {
  Serial.begin(115200);
  
  // Initialize pins
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(ledPin, OUTPUT);
  
  // Connect to WiFi
  Serial.println("Connecting to WiFi...");
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    digitalWrite(ledPin, !digitalRead(ledPin));
  }
  
  Serial.println("\nWiFi connected!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
  digitalWrite(ledPin, HIGH);
  delay(2000);
}

void loop() {
  // Read distance from sensor
  long distance = measureDistance();
  
  // Calculate fill level
  int fillLevel = calculateFillLevel(distance);
  
  // Print to serial
  Serial.print("Distance: ");
  Serial.print(distance);
  Serial.print(" cm | Fill Level: ");
  Serial.print(fillLevel);
  Serial.println("%");
  
  // Send to Firebase
  if (WiFi.status() == WL_CONNECTED) {
    sendToFirebase(fillLevel);
  }
  
  // LED indicator
  blinkLED(fillLevel);
  
  // Wait 10 seconds before next reading
  delay(10000);
}

long measureDistance() {
  // Clear trigger
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  
  // Send pulse
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  
  // Read echo
  long duration = pulseIn(echoPin, HIGH, 30000);
  long distance = duration * 0.034 / 2;
  
  // Validate
  if (distance == 0 || distance > 400) {
    return -1;
  }
  
  return distance;
}

int calculateFillLevel(long distance) {
  if (distance < 0) return 0;
  
  long emptySpace = distance - SENSOR_OFFSET;
  if (emptySpace < 0) emptySpace = 0;
  if (emptySpace > BIN_HEIGHT) emptySpace = BIN_HEIGHT;
  
  int fillLevel = 100 - ((emptySpace * 100) / BIN_HEIGHT);
  
  if (fillLevel < 0) fillLevel = 0;
  if (fillLevel > 100) fillLevel = 100;
  
  return fillLevel;
}

void sendToFirebase(int fillLevel) {
  HTTPClient http;
  
  // Construct URL - Using REST API
  String url = String(firebaseHost) + "/bins/" + binId + ".json";
  if (strlen(firebaseAuth) > 0) {
    url += "?auth=" + String(firebaseAuth);
  }
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  // Create JSON
  StaticJsonDocument<200> doc;
  doc["fillLevel"] = fillLevel;
  doc["lastUpdated"] = millis();
  
  // Determine status
  if (fillLevel >= 80) {
    doc["status"] = "FULL";
    doc["estimatedFullTime"] = "1-2 hours";
  } else if (fillLevel >= 40) {
    doc["status"] = "OK";
    doc["estimatedFullTime"] = "3 days";
  } else {
    doc["status"] = "EMPTY";
    doc["estimatedFullTime"] = "7+ days";
  }
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  // Send PATCH request
  int httpResponseCode = http.PATCH(jsonString);
  
  if (httpResponseCode > 0) {
    Serial.print("Data sent! Response: ");
    Serial.println(httpResponseCode);
  } else {
    Serial.print("Error sending data: ");
    Serial.println(httpResponseCode);
  }
  
  http.end();
}

void blinkLED(int fillLevel) {
  if (fillLevel >= 80) {
    // FULL - Fast blink
    digitalWrite(ledPin, HIGH);
    delay(100);
    digitalWrite(ledPin, LOW);
    delay(100);
    digitalWrite(ledPin, HIGH);
    delay(100);
    digitalWrite(ledPin, LOW);
  } else if (fillLevel >= 40) {
    // OK - Slow blink
    digitalWrite(ledPin, HIGH);
    delay(300);
    digitalWrite(ledPin, LOW);
  } else {
    // EMPTY - Steady on
    digitalWrite(ledPin, HIGH);
  }
}
