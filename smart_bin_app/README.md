# SmartBin: IoT Waste Management System

An Arduino/ESP32-based IoT waste management system with Flutter mobile application for real-time bin monitoring and intelligent alerts.

## 📱 Project Overview

SmartBin is an IoT-based dustbin that automatically monitors waste levels using ultrasonic sensors and sends real-time notifications when bins are almost full. This helps maintain cleanliness, reduces manual checking, and supports smart waste management.

## 🎯 Features

- ✅ Real-time bin fill level monitoring
- ✅ Automatic notifications when bins are full
- ✅ Firebase Firestore integration for data storage
- ✅ Firebase Cloud Messaging for push notifications
- ✅ Beautiful, responsive UI matching prototype design
- ✅ Multiple bin management
- ✅ Predictive fill time estimation
- ✅ Status indicators (FULL, OK, EMPTY)

## 🎓 Academic Project Details

**Course:** Application Development  
**Technology Stack:** Flutter, Dart, Firebase, Arduino, ESP32  
**Hardware:** Ultrasonic Sensor, ESP32, LED indicators

## 🏗️ System Architecture

```
ESP32 (Ultrasonic Sensor) 
    ↓ (WiFi)
Firebase Firestore
    ↓ (Real-time Stream)
Flutter Mobile App
    ↓ (FCM)
Push Notifications
```

## 📋 Prerequisites

### Software Requirements
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code
- Arduino IDE
- Firebase CLI (optional)

### Hardware Requirements
- ESP32 microcontroller
- HC-SR04 Ultrasonic Sensor
- LED indicator
- Jumper wires
- Breadboard
- Power supply (5V)
- Bin/Container for prototype

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/Coraido/SmartBin.git
cd SmartBin/smart_bin_app
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project or select existing "SmartBin" project
3. Enable Firestore Database
4. Enable Firebase Cloud Messaging
5. Download `google-services.json` (Android) and place in `android/app/`
6. Download `GoogleService-Info.plist` (iOS) and place in `ios/Runner/`

### 4. Configure Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /bins/{binId} {
      allow read, write: if true; // For development only
    }
    match /deviceTokens/{tokenId} {
      allow read, write: if true; // For development only
    }
  }
}
```

### 5. Run the Application

```bash
flutter run -d chrome  # For web
flutter run            # For connected device
```

## 🔧 ESP32 Setup

See [ESP32_SETUP.md](ESP32_SETUP.md) for detailed Arduino/ESP32 configuration and code.

### Quick Hardware Setup:
1. Connect HC-SR04 to ESP32:
   - VCC → 5V
   - GND → GND
   - TRIG → GPIO 5
   - ECHO → GPIO 18

2. Upload Arduino code from ESP32_SETUP.md
3. Configure WiFi credentials
4. Set Firebase credentials
5. Monitor Serial output for debugging

## 📱 App Structure

```
lib/
├── main.dart                      # App entry point
├── firebase_options.dart          # Firebase configuration
├── models/
│   └── bin_model.dart            # Bin data model
├── screens/
│   ├── get_started_screen.dart   # Welcome/splash screen
│   └── my_bins_screen.dart       # Main dashboard
├── services/
│   └── firebase_service.dart     # Firebase operations
└── widgets/
    └── bin_card.dart             # Bin display card
```

## 🎨 UI Design

The app follows the provided prototype design with:
- Modern Material Design
- Clean, minimalist interface
- Status color coding (Red/Green/Blue)
- Circular progress indicators
- Real-time updates

## 📊 Firebase Data Structure

```json
{
  "bins": {
    "binId1": {
      "name": "Kitchen Bin",
      "fillLevel": 95,
      "status": "FULL",
      "estimatedFullTime": "1-2 hours",
      "lastEmptied": "2025-10-15T10:30:00Z",
      "lastUpdated": "2025-10-16T12:45:00Z"
    }
  }
}
```

## 🔔 Notifications

The app uses Firebase Cloud Messaging for:
- Full bin alerts (≥80% full)
- Scheduled emptying reminders
- System status updates

## 🧪 Testing

### Manual Testing:
1. Place objects above ultrasonic sensor
2. Observe fill level changes in app
3. Test notification delivery
4. Verify real-time synchronization

### Automated Testing:
```bash
flutter test
```

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  firebase_core: ^4.2.0
  cloud_firestore: ^6.0.3
  firebase_messaging: ^16.0.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

## 🎯 Project Objectives

✅ Detect bin fullness automatically using sensors  
✅ Send real-time notifications through the internet  
✅ Improve waste collection efficiency and hygiene  
✅ Support smart city and eco-friendly initiatives  

## 👥 Target Users

- Offices and schools
- Smart homes and eco-friendly households
- Municipal waste departments
- Residential communities

## ⚠️ Limitations

- Requires stable WiFi connection
- Affected by power loss
- Measurement accuracy varies with uneven waste
- Ultrasonic sensors need line-of-sight to waste surface

## 🔮 Future Enhancements

- [ ] Machine learning for better fill prediction
- [ ] Route optimization for waste collection
- [ ] Multiple bin support with ESP32 mesh network
- [ ] Battery backup for power outages
- [ ] Web dashboard for administration
- [ ] Historical data analytics
- [ ] Integration with smart home systems

## 📄 License

This project is for academic purposes as part of Application Development course.

## 👨‍💻 Authors

- Your Name / Team Members
- Course: Application Development
- Institution: [Your Institution Name]

## 🙏 Acknowledgments

- Firebase for backend infrastructure
- Flutter team for excellent framework
- Arduino/ESP32 community for IoT support

## 📞 Support

For issues and questions:
1. Check existing issues on GitHub
2. Review ESP32_SETUP.md for hardware troubleshooting
3. Consult Firebase documentation
4. Contact project team members

## 📚 References

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [ESP32 Arduino Core](https://github.com/espressif/arduino-esp32)
- [HC-SR04 Datasheet](https://cdn.sparkfun.com/datasheets/Sensors/Proximity/HCSR04.pdf)

---

**SmartBin** - Never Overfill Again! 🗑️♻️
