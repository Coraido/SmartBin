# SmartBin ESP32 Arduino Setup

## Required Hardware Components
- ESP32 Development Board
- HC-SR04 Ultrasonic Sensor
- SG90 Servo Motor
- Buzzer (Active or Passive)
- Breadboard and Jumper Wires
- USB Cable (for programming ESP32)

## Pin Connections

### Ultrasonic Sensor (HC-SR04)
- VCC → 5V
- GND → GND
- TRIG → GPIO 5
- ECHO → GPIO 18

### Servo Motor
- VCC (Red) → 5V
- GND (Brown/Black) → GND
- Signal (Orange/Yellow) → GPIO 25

### Buzzer
- Positive (+) → GPIO 26
- Negative (-) → GND

## Software Setup

### 1. Get Firebase Credentials

#### API Key:
1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your "SmartBin" project
3. Click the Gear icon (⚙️) → Project Settings
4. Under "General" tab, scroll down to "Your apps"
5. Copy the "Web API Key"

#### Database URL:
1. In Firebase Console, go to "Realtime Database" (NOT Firestore)
2. Click "Create Database" if you haven't already
3. Choose your region and start in "Test mode" (for development)
4. Copy the database URL (it looks like: `https://smartbin-xxxxx-default-rtdb.firebaseio.com/`)

**IMPORTANT:** We're using Firebase Realtime Database, not Firestore, for the ESP32 because it's easier to integrate with the Arduino library.

### 2. Configure the Arduino Code

Open `SmartBin_ESP32.ino` and replace the following:

```cpp
// WiFi Credentials
#define WIFI_SSID "YOUR_WIFI_SSID"        // Your WiFi network name
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD" // Your WiFi password

// Firebase Credentials
#define API_KEY "YOUR_FIREBASE_API_KEY"           // From Firebase Console
#define DATABASE_URL "YOUR_FIREBASE_DATABASE_URL" // Your Realtime Database URL
```

### 3. Upload to ESP32

1. Connect ESP32 to your computer via USB
2. In Arduino IDE, go to **Tools → Board → ESP32 Arduino → ESP32 Dev Module**
3. Go to **Tools → Port** and select the COM port for your ESP32
4. Click the **Upload** button (→)
5. Wait for "Done uploading" message

### 4. Monitor Serial Output

1. Go to **Tools → Serial Monitor**
2. Set baud rate to **115200**
3. You should see output showing:
   - WiFi connection
   - Firebase connection
   - Distance readings
   - Fill level percentage
   - Status updates

## Configuration Settings

You can adjust these values in the code:

- `binHeight = 30` → Height of your bin in centimeters
- `fullThreshold = 80` → Percentage when bin is considered full (triggers buzzer)
- `handThreshold = 10` → Distance in cm to detect hand and open lid
- `closeAngle = 0` → Servo angle when lid is closed
- `openAngle = 100` → Servo angle when lid is open (adjust if needed)

## Troubleshooting

### ESP32 Not Connecting to WiFi
- Check WiFi credentials
- Make sure WiFi is 2.4GHz (ESP32 doesn't support 5GHz)
- Move ESP32 closer to router

### Firebase Connection Failed
- Verify API Key and Database URL
- Check that Realtime Database is created (not just Firestore)
- Make sure Database rules allow read/write in test mode

### Servo Not Moving
- Check power connections (servo needs 5V)
- Verify servo wire is connected to GPIO 25
- Try adjusting `closeAngle` and `openAngle` values

### Buzzer Not Beeping
- Check buzzer polarity (+ to GPIO 26, - to GND)
- Try a different GPIO pin
- Verify `fullThreshold` is set correctly

### Distance Readings Incorrect
- Check ultrasonic sensor connections
- Make sure nothing is blocking the sensor
- Adjust `binHeight` to match your actual bin height

## How It Works

1. **Hand Detection**: When object is detected within 10cm, servo opens lid for 3 seconds
2. **Fill Level Monitoring**: Continuously measures distance and calculates fill percentage
3. **Status Updates**: Sends data to Firebase every 5 seconds
4. **Full Alert**: When fill level ≥ 80%, buzzer beeps and status changes to "FULL"
5. **Firebase Sync**: Flutter app reads real-time data from Firebase

## Next Steps

After uploading the code:
1. Open Serial Monitor to verify it's working
2. Test hand detection by placing hand near sensor
3. Verify Firebase is receiving data in Firebase Console
4. Configure Flutter app to read from Realtime Database
