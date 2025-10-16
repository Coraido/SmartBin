# SmartBin Quick Start Guide

## 🚀 Quick Setup (5 Steps)

### Step 1: Setup Firebase (10 minutes)

1. **Create Firebase Project**
   - Go to https://console.firebase.google.com
   - Click "Add Project"
   - Name it "SmartBin"
   - Disable Google Analytics (optional)

2. **Setup Firestore Database**
   - Click "Firestore Database" in left menu
   - Click "Create Database"
   - Start in **Test Mode**
   - Choose location closest to you

3. **Create Initial Bin Document**
   - In Firestore, click "Start Collection"
   - Collection ID: `bins`
   - Document ID: Auto-generate (or use `bin001`)
   - Add fields:
     ```
     name: "Kitchen Bin" (string)
     fillLevel: 0 (number)
     status: "EMPTY" (string)
     estimatedFullTime: "7+ days" (string)
     lastEmptied: [Current timestamp]
     lastUpdated: [Current timestamp]
     ```

4. **Get Firebase Credentials**
   - Project Settings (gear icon) > General
   - Copy your API Key
   - Copy Project ID
   - Note your Firebase URL: `https://smartbin-xxxxx.firebaseio.com`

5. **Add Firebase to App**
   - Download `google-services.json` for Android
   - Place in `android/app/` folder
   - Already configured in your project!

---

### Step 2: Run Flutter App (2 minutes)

```bash
cd smart_bin_app
flutter pub get
flutter run -d chrome
```

Your app should now show at: **http://localhost:8080**

---

### Step 3: Hardware Assembly (15 minutes)

**Components Needed:**
- ESP32 Dev Board
- HC-SR04 Ultrasonic Sensor
- LED (any color)
- 220Ω Resistor
- Breadboard
- Jumper Wires
- USB Cable
- Container/Bin

**Wiring Diagram:**

```
HC-SR04 Ultrasonic Sensor:
  VCC  → ESP32 5V (or VIN)
  GND  → ESP32 GND
  TRIG → ESP32 GPIO 5
  ECHO → ESP32 GPIO 18

LED Indicator:
  Anode (+) → ESP32 GPIO 2
  Cathode (-) → 220Ω Resistor → ESP32 GND
```

**Visual Layout:**
```
         ESP32
    ┌─────────────┐
    │ GPIO 5  → TRIG (HC-SR04)
    │ GPIO 18 → ECHO (HC-SR04)
    │ 5V/VIN  → VCC (HC-SR04)
    │ GND     → GND (HC-SR04)
    │             
    │ GPIO 2  → LED (+)
    │ GND     → 220Ω → LED (-)
    └─────────────┘
```

---

### Step 4: Upload Arduino Code (5 minutes)

1. **Install Arduino IDE**
   - Download from https://www.arduino.cc/en/software

2. **Add ESP32 Support**
   - File → Preferences
   - Additional Board Manager URLs: 
     ```
     https://dl.espressif.com/dl/package_esp32_index.json
     ```
   - Tools → Board → Boards Manager
   - Search "esp32" → Install

3. **Install Libraries**
   - Tools → Manage Libraries
   - Install: **ArduinoJson** (by Benoit Blanchon)
   - Install: **HTTPClient** (built-in)

4. **Configure the Code**
   - Open `arduino/smartbin_esp32/smartbin_esp32.ino`
   - Update these lines:
     ```cpp
     const char* ssid = "YOUR_WIFI_NAME";
     const char* password = "YOUR_WIFI_PASSWORD";
     const char* firebaseHost = "https://smartbin-xxxxx.firebaseio.com";
     String binId = "YOUR_BIN_ID_FROM_FIRESTORE";
     ```

5. **Upload to ESP32**
   - Connect ESP32 via USB
   - Tools → Board → ESP32 Dev Module
   - Tools → Port → (Select your COM port)
   - Click Upload ⬆️

6. **Monitor Output**
   - Tools → Serial Monitor (115200 baud)
   - You should see:
     ```
     Connecting to WiFi...
     WiFi connected!
     Distance: 25 cm | Fill Level: 15%
     Data sent! Response: 200
     ```

---

### Step 5: Test the System (5 minutes)

1. **Test Sensor Reading**
   - Open Serial Monitor
   - Place hand above sensor
   - Watch distance change

2. **Test App Sync**
   - Keep Serial Monitor open
   - Open app at http://localhost:8080
   - Click "Get Started"
   - You should see your bin with real-time data!

3. **Test Full Bin Alert**
   - Cover sensor completely with hand
   - Wait 10 seconds
   - Bin should show 90-100% full
   - Status changes to "FULL" (red)

4. **Calibrate (if needed)**
   - Measure your bin height in cm
   - Update in Arduino code:
     ```cpp
     const int BIN_HEIGHT = 30; // Your bin height
     ```
   - Re-upload code

---

## 📱 Using the App

### Main Features:

1. **View All Bins**
   - See fill levels in real-time
   - Color-coded status (Red/Green/Blue)
   - Estimated time until full

2. **Notifications**
   - Click bell icon to enable
   - Get alerts when bins are ≥80% full

3. **Last Emptied Info**
   - Bottom section shows recently emptied bin
   - Time since last empty

---

## 🔧 Troubleshooting

### App Issues:

**Problem:** No bins showing
- **Solution:** Check Firebase Firestore has bins collection
- Create a bin manually in Firebase Console

**Problem:** Old data, not updating
- **Solution:** Check ESP32 Serial Monitor for errors
- Verify Firebase URL in Arduino code

### Hardware Issues:

**Problem:** ESP32 won't connect to WiFi
- **Solution:** 
  - Check SSID and password
  - Ensure 2.4GHz WiFi (ESP32 doesn't support 5GHz)
  - Move closer to router

**Problem:** Inaccurate distance readings
- **Solution:**
  - Check sensor wiring
  - Ensure sensor faces flat surface
  - Update BIN_HEIGHT and SENSOR_OFFSET

**Problem:** No LED blinking
- **Solution:**
  - Check LED polarity (longer leg = positive)
  - Verify 220Ω resistor is connected
  - Test with different LED

### Firebase Issues:

**Problem:** Permission denied errors
- **Solution:** Set Firestore rules to test mode:
  ```javascript
  allow read, write: if true;
  ```

**Problem:** Data not updating
- **Solution:**
  - Check Firebase URL format
  - Verify bin ID matches in code and Firestore
  - Check API key

---

## 📊 Next Steps

### Enhance Your Project:

1. **Add More Bins**
   - Wire additional sensors to different GPIO pins
   - Create new bin documents in Firestore
   - Update binId in code

2. **Improve Notifications**
   - Setup Firebase Cloud Functions
   - Send email alerts
   - SMS integration

3. **Add Features**
   - Historical data charts
   - Weekly statistics
   - Emptying schedule
   - Admin dashboard

4. **Optimize Hardware**
   - Add battery backup
   - Solar panel charging
   - Weatherproof enclosure
   - Better sensor placement

---

## 📚 Helpful Resources

- **Flutter Docs:** https://flutter.dev/docs
- **Firebase Console:** https://console.firebase.google.com
- **ESP32 Pinout:** https://randomnerdtutorials.com/esp32-pinout-reference-gpios/
- **HC-SR04 Tutorial:** https://randomnerdtutorials.com/esp32-hc-sr04-ultrasonic-arduino/

---

## ✅ Checklist for Demo/Presentation

- [ ] Firebase project created and configured
- [ ] Flutter app running and displaying bins
- [ ] ESP32 connected to WiFi
- [ ] Sensor readings working
- [ ] Real-time sync between hardware and app
- [ ] LED indicators working
- [ ] Tested full/empty scenarios
- [ ] Screenshots/screen recording ready
- [ ] Demo script prepared
- [ ] Backup plan (pre-recorded video)

---

## 💡 Demo Tips

1. **Start with app running** - Show clean UI first
2. **Demonstrate sensor** - Wave hand to show real-time updates
3. **Show Firebase Console** - Prove data is syncing
4. **Test notifications** - Trigger full bin alert
5. **Explain architecture** - Show system diagram
6. **Discuss applications** - Smart cities, offices, homes
7. **Future improvements** - Show vision for scaling

---

## 🎓 For Your Report/Documentation

Include these sections:
1. Introduction & Objectives
2. System Architecture Diagram
3. Hardware Components List
4. Software Stack
5. Implementation Screenshots
6. Testing Results
7. Challenges & Solutions
8. Future Enhancements
9. Conclusion
10. References

---

**Need Help?** 
- Check `README.md` for detailed documentation
- Review `ESP32_SETUP.md` for Arduino details
- Test each component separately first
- Use Serial Monitor for debugging

**Good luck with your project! 🎉**
