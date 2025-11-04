/*
 * SmartBin - Fill Level Monitoring System
 * ESP32 Code with Ultrasonic Sensor and Firebase
 * Monitors bin fill level and syncs to Firebase for Flutter app
 */

#include <WiFi.h>
#include <Firebase_ESP_Client.h>

// Provide the token generation process info.
#include <addons/TokenHelper.h>
// Provide the RTDB payload printing info and other helper functions.
#include <addons/RTDBHelper.h>

// ===== WiFi Credentials =====
#define WIFI_SSID "GlobeAtHome_D3FE0_2.4"    // Your Globe At Home WiFi (2.4GHz)
#define WIFI_PASSWORD "c2SVUHDU"              // Your WiFi password

// ===== Firebase Credentials =====
#define API_KEY "AIzaSyCO8ru2HgT_AIs25e3Jrr6TNWNa3LJua0A"
#define DATABASE_URL "https://smartbin-c8ef7-default-rtdb.asia-southeast1.firebasedatabase.app/"

// ===== Pin Definitions =====
// Fill Level Monitoring Sensor (inside bin, points down)
const int trigPin = 27;     // Ultrasonic sensor trigger pin
const int echoPin = 33;     // Ultrasonic sensor echo pin

// ===== Configuration Settings =====
const int binHeight = 10;             // Height of bin in cm (measured: sensor to bottom when empty)
const int fullThreshold = 80;        // Percentage when bin is considered full

// ===== Global Variables =====
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Distance measurement variables for fill level monitoring
long duration;
float fillDistance;
float fillDistanceReadings[3]; // Array for stable fill readings

// Firebase sync variables
unsigned long sendDataPrevMillis = 0;
bool signupOK = false;
volatile int currentFillLevel = 0;      // volatile = shared between cores
volatile bool isBinFull = false;        // volatile = shared between cores
volatile char currentStatusBuffer[10] = "EMPTY";  // Shared status as char array
bool wifiConnected = false;

// Mutex for thread-safe data sharing between cores
SemaphoreHandle_t dataMutex;

// ===== Function Prototypes =====
float readFillDistance();       // Fill level distance reading
void firebaseTask(void *parameter);  // Background task for Firebase

void setup() {
  // Initialize Serial Monitor
  Serial.begin(9600);
  Serial.println("SmartBin Fill Monitor Starting...");

  // Create mutex for safe data sharing between cores
  dataMutex = xSemaphoreCreateMutex();

  // Initialize Pins for fill level monitoring
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  
  Serial.println("Fill sensor initialized.");

  // Connect to WiFi in background (non-blocking)
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.println("WiFi connecting in background...");

  Serial.println("SmartBin Fill Monitor Ready!");
  Serial.println("================================");
  
  // Create Firebase task on separate core (ESP32 has 2 cores!)
  // Core 0: Firebase updates (background)
  // Core 1: Fill monitoring (main loop - never blocked!)
  xTaskCreatePinnedToCore(
    firebaseTask,   // Function to run
    "FirebaseTask", // Task name
    20000,          // Stack size
    NULL,           // Parameters
    1,              // Priority
    NULL,           // Task handle
    0               // Core 0 (background)
  );
}

void loop() {
  // === Bin Fill Level Monitoring ===
  // Read from sensor (mounted inside, pointing down)
  for (int i = 0; i < 3; i++) {
    fillDistanceReadings[i] = readFillDistance();
    delay(20);
  }
  
  // Calculate average fill distance
  fillDistance = (fillDistanceReadings[0] + fillDistanceReadings[1] + fillDistanceReadings[2]) / 3;
  
  // Calculate fill level
  if (fillDistance > 0 && fillDistance <= binHeight) {
    int wasteHeight = binHeight - fillDistance;
    int newFillLevel = (wasteHeight * 100) / binHeight;
    newFillLevel = constrain(newFillLevel, 0, 100);
    
    // Lock mutex before updating shared variables
    if (xSemaphoreTake(dataMutex, portMAX_DELAY) == pdTRUE) {
      currentFillLevel = newFillLevel;
      
      if (currentFillLevel >= fullThreshold) { // 80% and above
        strcpy((char*)currentStatusBuffer, "FULL");
        isBinFull = true;
      } else if (currentFillLevel > 15) { // 16% to 79%
        strcpy((char*)currentStatusBuffer, "IN USE");
        isBinFull = false;
      } else { // 0% to 15%
        strcpy((char*)currentStatusBuffer, "EMPTY");
        isBinFull = false;
      }
      
      xSemaphoreGive(dataMutex);  // Unlock mutex
    }
    
    // Print fill level info
    Serial.print("Fill Distance: ");
    Serial.print(fillDistance);
    Serial.print(" cm | Fill Level: ");
    Serial.print(currentFillLevel);
    Serial.print("% | Status: ");
    Serial.println((char*)currentStatusBuffer);
  }
  
  // Firebase Data Sync running on separate core
  
  delay(100); // A short delay in the main loop
}

// ===== Function: Read Fill Distance =====
/*
 * readFillDistance()
 * Reads distance from sensor (inside bin, pointing down)
 * Measures the distance from sensor to trash surface
 */
float readFillDistance() {
  // Send a 10-microsecond pulse to trigger sensor
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  // Measure the time it takes for the echo pulse to return
  duration = pulseIn(echoPin, HIGH);

  // Calculate the distance in centimeters
  // 0.0343 cm/µs is the speed of sound
  float dist = duration * 0.0343 / 2;

  return dist;
}

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

  // Sign up new user anonymously
  Serial.println("[Firebase] Signing up for anonymous user...");
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("[Firebase] ✓ Sign up successful");
    // The UID is required for all database operations
   
  } else {
    Serial.printf("[Firebase] ✗ Sign up failed: %s\n", config.signer.signupError.message.c_str());
  }
  
  // Initialize Firebase with the new auth data
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  // Give the main loop a moment to get the first sensor reading
  delay(2000);

  // Main Firebase loop - runs forever on Core 0
  Serial.println("[Firebase] Starting sync loop...");
  while (true) {
    if (Firebase.ready()) {
      // Read shared variables safely with mutex
      int fillLevelSnapshot = 0;
      char statusSnapshot[10];
      
      if (xSemaphoreTake(dataMutex, portMAX_DELAY) == pdTRUE) {
        fillLevelSnapshot = currentFillLevel;
        strcpy(statusSnapshot, (char*)currentStatusBuffer);
        xSemaphoreGive(dataMutex);
      }
      
      // Calculate estimated time
      String estimatedTime = "7+ days";
      if (fillLevelSnapshot >= 80) {
        estimatedTime = "1-2 hours";
      } else if (fillLevelSnapshot >= 60) {
        estimatedTime = "6-12 hours";
      } else if (fillLevelSnapshot >= 40) {
        estimatedTime = "1-2 days";
      } else if (fillLevelSnapshot >= 20) {
        estimatedTime = "3-5 days";
      }
      
      Serial.printf("[Firebase] Syncing: Level=%d%%, Status=%s\n", fillLevelSnapshot, statusSnapshot);

      // Update Firebase with snapshot values and check for success
      if (Firebase.RTDB.setInt(&fbdo, "bins/kitchen_bin/fill_level", fillLevelSnapshot)) {
        Serial.println("[Firebase] ✓ Synced fill_level");
      } else {
        Serial.println("[Firebase] ✗ FAILED to sync fill_level: " + fbdo.errorReason());
      }

      if (Firebase.RTDB.setString(&fbdo, "bins/kitchen_bin/status", String(statusSnapshot))) {
        Serial.println("[Firebase] ✓ Synced status");
      } else {
        Serial.println("[Firebase] ✗ FAILED to sync status: " + fbdo.errorReason());
      }

      Firebase.RTDB.setString(&fbdo, "bins/kitchen_bin/estimated_full_in", estimatedTime);
      Firebase.RTDB.setString(&fbdo, "bins/kitchen_bin/name", "Kitchen Bin");
      
    } else {
      Serial.println("[Firebase] ✗ Firebase not ready. Reason: " + fbdo.errorReason());
    }
    
    // Update every 10 seconds
    delay(10000);
  }
}

