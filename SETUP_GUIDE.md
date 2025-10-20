# SmartBin - Complete Setup Guide

## 🎯 What We've Accomplished

✅ **Arduino Code Created** - ESP32 code with ultrasonic sensor, servo, buzzer, and Firebase  
✅ **Flutter App Updated** - Real-time data streaming from Firebase Realtime Database  
✅ **Notification System Ready** - Push notifications when bin is full  
✅ **Auto Lid Feature** - Lid opens automatically when hand detected  
✅ **Buzzer Alert** - Beeps when bin is 80% full  

---

## 📋 Step-by-Step Setup

### STEP 1: Configure Firebase Realtime Database

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your "SmartBin" project
3. Click **"Realtime Database"** (NOT Firestore!)
4. Click **"Create Database"**
5. Choose your region
6. Start in **"Test mode"**
7. Click **"Enable"**

**Copy your Database URL** - it looks like:
```
https://smartbin-xxxxx-default-rtdb.firebaseio.com/
```

### STEP 2: Get Firebase Credentials

#### API Key:
1. Click **Gear icon** (⚙️) → **Project Settings**
2. Under "Your apps", find **"Web API Key"**
3. Copy it (starts with `AIza...`)

### STEP 3: Configure ESP32 Code

Open `arduino_code/SmartBin_ESP32/SmartBin_ESP32.ino`

Replace these lines (around line 8-13):

```cpp
#define WIFI_SSID "YOUR_WIFI_SSID"           // Your WiFi name
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"   // Your WiFi password
#define API_KEY "YOUR_FIREBASE_API_KEY"      // From Step 2
#define DATABASE_URL "YOUR_FIREBASE_DATABASE_URL"  // From Step 1
```

Example:
```cpp
#define WIFI_SSID "MyHomeWiFi"
#define WIFI_PASSWORD "MyPassword123"
#define API_KEY "AIzaSyB1234567890abcdefg"
#define DATABASE_URL "https://smartbin-c8ef7-default-rtdb.firebaseio.com/"
```

### STEP 4: Add Buzzer to Your Circuit

You showed me your circuit with the ultrasonic sensor and servo. Now add a buzzer:

**Buzzer Connections:**
- **Positive (+)** → ESP32 GPIO 26
- **Negative (-)** → GND

Your complete circuit should have:
- Ultrasonic: TRIG→GPIO5, ECHO→GPIO18  
- Servo: Signal→GPIO25
- Buzzer: (+)→GPIO26

### STEP 5: Upload ESP32 Code

1. Connect ESP32 via USB
2. Open Arduino IDE
3. **File → Open** → Select `SmartBin_ESP32.ino`
4. **Tools → Board → ESP32 Dev Module**
5. **Tools → Port** → Select your COM port
6. Click **Upload** button (→)
7. Wait for "Done uploading"

### STEP 6: Test ESP32

1. **Tools → Serial Monitor**
2. Set baud rate to **115200**
3. You should see:
   ```
   SmartBin System Starting...
   Connecting to WiFi..
   Connected with IP: 192.168.x.x
   Firebase signup successful
   SmartBin System Ready!
   Distance: 25 cm | Fill Level: 16% | Status: EMPTY
   ```

### STEP 7: Verify Data in Firebase

1. Go back to Firebase Console
2. Click **Realtime Database**
3. You should see:
   ```
   bins
     └─ kitchen_bin
          ├─ name: "Kitchen Bin"
          ├─ fill_level: 16
          ├─ status: "EMPTY"
          ├─ estimated_full_in: "7+ days"
          └─ last_updated: 1729345678000
   ```

### STEP 8: Run Flutter App

Open terminal in VS Code:

```bash
cd smart_bin_app
flutter run -d chrome
```

Or for Windows:
```bash
flutter run -d windows
```

### STEP 9: Test the System

**Test Auto Lid:**
- Place your hand within 10cm of the ultrasonic sensor
- Lid should open automatically
- Wait 3 seconds - lid closes

**Test Fill Detection:**
- Place objects in the bin to increase fill level
- Watch Serial Monitor show increasing percentage
- Check Flutter app updates in real-time

**Test Full Alert:**
- Fill bin to 80% or more
- Buzzer should start beeping
- Flutter app should show "FULL" status in red

---

## 🔔 How It All Works Together

```
ESP32 → Ultrasonic Sensor
   ↓
Measures Distance
   ↓
Calculates Fill Level (%)
   ↓
Sends to Firebase Realtime Database
   ↓
Flutter App Listens (Real-time Stream)
   ↓
Updates UI Automatically
   ↓
If Fill ≥ 80% → Show Notification
```

**AND**

```
Hand Near Sensor (< 10cm)
   ↓
ESP32 Detects
   ↓
Servo Opens Lid
   ↓
Wait 3 seconds
   ↓
Servo Closes Lid
```

**AND**

```
Fill Level ≥ 80%
   ↓
ESP32 Activates Buzzer
   ↓
Beeping Pattern
   ↓
Continues until bin is emptied
```

---

## ⚙️ Customization Options

### Adjust Bin Height

In `SmartBin_ESP32.ino` (line 25):
```cpp
const int binHeight = 30;  // Change to your bin height in cm
```

### Change Full Threshold

```cpp
const int fullThreshold = 80;  // Change percentage for "FULL" status
```

### Adjust Hand Detection Distance

```cpp
const int handThreshold = 10;  // Distance in cm to trigger lid
```

### Change Servo Angles

```cpp
const int closeAngle = 0;    // Adjust if lid doesn't close fully
const int openAngle = 100;   // Adjust if lid doesn't open fully
```

---

## 🐛 Troubleshooting

### Problem: ESP32 Not Connecting to WiFi

**Solutions:**
- Double-check WiFi name and password (case-sensitive!)
- Make sure WiFi is 2.4GHz (ESP32 doesn't support 5GHz)
- Move ESP32 closer to router
- Try hotspot from your phone

### Problem: Firebase Connection Failed

**Solutions:**
- Verify API Key (should start with `AIza`)
- Check Database URL ends with `/`
- Make sure you created **Realtime Database**, not Firestore
- Check Firebase Console → Database → Rules:
  ```json
  {
    "rules": {
      ".read": true,
      ".write": true
    }
  }
  ```

### Problem: Flutter App Shows "No bins found"

**Solutions:**
- Make sure ESP32 is running and connected
- Click "Create Test Bin" button in the app
- Manually add data in Firebase Console
- Check browser console (F12) for errors

### Problem: Servo Not Moving

**Solutions:**
- Check 5V power connection
- Verify signal wire on GPIO 25
- Try changing `closeAngle` and `openAngle` values
- Test with a different servo

### Problem: Buzzer Not Beeping

**Solutions:**
- Check polarity (+ to GPIO 26)
- Test with an LED first
- Try passive buzzer if using active (or vice versa)
- Change `BUZZER_PIN` in code

### Problem: Inaccurate Distance Readings

**Solutions:**
- Make sure sensor is mounted straight
- Keep sensor clear of obstructions
- Adjust `binHeight` to match your bin
- Try different TRIG/ECHO pins if needed

---

## 📱 Firebase Database Rules (Production)

When you're ready to deploy, change rules to:

```json
{
  "rules": {
    "bins": {
      ".read": true,
      "$binId": {
        ".write": "auth != null"
      }
    },
    "deviceTokens": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

This allows:
- Anyone to READ bin data (for the app)
- Only authenticated users/devices to WRITE

---

## 🎉 Success Checklist

- [ ] Firebase Realtime Database created
- [ ] ESP32 code configured with WiFi and Firebase credentials
- [ ] Buzzer added to circuit
- [ ] Code uploaded to ESP32
- [ ] Serial Monitor shows successful connection
- [ ] Data visible in Firebase Console
- [ ] Flutter app running
- [ ] App shows real-time data
- [ ] Hand detection opens lid
- [ ] Buzzer beeps when full
- [ ] App updates automatically

---

## 📞 Need Help?

- Check Serial Monitor output for errors
- Look at Firebase Console → Realtime Database for data
- Open browser console (F12) when running Flutter app
- Review `arduino_code/README.md` for detailed hardware setup

---

## 🚀 Next Steps (Optional Enhancements)

1. **Add More Bins**: Duplicate the code for multiple bins
2. **Email Notifications**: Set up Firebase Cloud Functions
3. **History Tracking**: Log fill levels over time
4. **Schedule Emptying**: Predict when collection is needed
5. **User Authentication**: Add login to secure the app
6. **Mobile App**: Deploy to Android/iOS

---

**Good luck with your SmartBin project! 🗑️✨**
