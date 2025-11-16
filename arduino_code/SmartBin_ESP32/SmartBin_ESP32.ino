

#include <WiFi.h>
#include <Firebase_ESP_Client.h>


#include <addons/TokenHelper.h>

#include <addons/RTDBHelper.h>


#define WIFI_SSID "GlobeAtHome_D3FE0_2.4"  
#define WIFI_PASSWORD "c2SVUHDU"              


#define API_KEY "AIzaSyCO8ru2HgT_AIs25e3Jrr6TNWNa3LJua0A"
#define DATABASE_URL "https://smartbin-c8ef7-default-rtdb.asia-southeast1.firebasedatabase.app/"


const int trigPin = 27;     
const int echoPin = 33;     


const int binHeight = 10;           
const int fullThreshold = 80;       


FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;


long duration;
float fillDistance;
float fillDistanceReadings[3]; 

unsigned long sendDataPrevMillis = 0;
bool signupOK = false;
volatile int currentFillLevel = 0;     
volatile bool isBinFull = false;        
volatile char currentStatusBuffer[10] = "EMPTY";  
bool wifiConnected = false;


SemaphoreHandle_t dataMutex;


float readFillDistance();     
void firebaseTask(void *parameter);  

void setup() {
  
  Serial.begin(9600);
  Serial.println("SmartBin Fill Monitor Starting...");


  dataMutex = xSemaphoreCreateMutex();

  
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  
  Serial.println("Fill sensor initialized.");


  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.println("WiFi connecting in background...");

  Serial.println("SmartBin Fill Monitor Ready!");
  Serial.println("================================");
  
 
  xTaskCreatePinnedToCore(
    firebaseTask,   
    "FirebaseTask", 
    20000,          
    NULL,           
    1,            
    NULL,           
    0             
  );
}

void loop() {
  
  
  for (int i = 0; i < 3; i++) {
    fillDistanceReadings[i] = readFillDistance();
    delay(20);
  }
  
  /
  fillDistance = (fillDistanceReadings[0] + fillDistanceReadings[1] + fillDistanceReadings[2]) / 3;
  

  if (fillDistance > 0 && fillDistance <= binHeight) {
    int wasteHeight = binHeight - fillDistance;
    int newFillLevel = (wasteHeight * 100) / binHeight;
    newFillLevel = constrain(newFillLevel, 0, 100);
    
 
    if (xSemaphoreTake(dataMutex, portMAX_DELAY) == pdTRUE) {
      currentFillLevel = newFillLevel;
      
      if (currentFillLevel >= fullThreshold) { 
        strcpy((char*)currentStatusBuffer, "FULL");
        isBinFull = true;
      } else if (currentFillLevel > 15) { 
        strcpy((char*)currentStatusBuffer, "IN USE");
        isBinFull = false;
      } else { 
        strcpy((char*)currentStatusBuffer, "EMPTY");
        isBinFull = false;
      }
      
      xSemaphoreGive(dataMutex);  
    }
    
    
    Serial.print("Fill Distance: ");
    Serial.print(fillDistance);
    Serial.print(" cm | Fill Level: ");
    Serial.print(currentFillLevel);
    Serial.print("% | Status: ");
    Serial.println((char*)currentStatusBuffer);
  }
  
  
  
  delay(100); 
}


float readFillDistance() {

  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);


  duration = pulseIn(echoPin, HIGH);


  float dist = duration * 0.0343 / 2;

  return dist;
}


void firebaseTask(void *parameter) {
  
  Serial.println("[Firebase] Waiting for WiFi...");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.print("[Firebase] WiFi Connected! IP: ");
  Serial.println(WiFi.localIP());
  wifiConnected = true;
  

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;


  Serial.println("[Firebase] Signing up for anonymous user...");
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("[Firebase] ✓ Sign up successful");
 
   
  } else {
    Serial.printf("[Firebase] ✗ Sign up failed: %s\n", config.signer.signupError.message.c_str());
  }
  

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  
  delay(2000);


  Serial.println("[Firebase] Starting sync loop...");
  while (true) {
    if (Firebase.ready()) {
      
      int fillLevelSnapshot = 0;
      char statusSnapshot[10];
      
      if (xSemaphoreTake(dataMutex, portMAX_DELAY) == pdTRUE) {
        fillLevelSnapshot = currentFillLevel;
        strcpy(statusSnapshot, (char*)currentStatusBuffer);
        xSemaphoreGive(dataMutex);
      }
      
   
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
    
    
    delay(10000);
  }
}

