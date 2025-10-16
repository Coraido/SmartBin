# SmartBin System Architecture & Diagrams

## 1. System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         SMARTBIN SYSTEM                              │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│   HARDWARE      │         │   CLOUD/BACKEND  │         │   CLIENT APP     │
│   LAYER         │         │   LAYER          │         │   LAYER          │
└─────────────────┘         └──────────────────┘         └──────────────────┘

┌─────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│                 │         │                  │         │                  │
│  HC-SR04        │         │   Firebase       │         │   Flutter App    │
│  Ultrasonic     │─WiFi───▶│   Firestore      │◀──HTTP──│   (Dart)         │
│  Sensor         │         │   Database       │         │                  │
│                 │         │                  │         │  • Get Started   │
│     ↓           │         │   ┌──────────┐   │         │  • My Bins       │
│                 │         │   │ bins/    │   │         │  • Real-time UI  │
│  ESP32          │         │   │  bin001  │   │         │                  │
│  Microcontroller│         │   │  bin002  │   │         │                  │
│                 │         │   └──────────┘   │         │                  │
│  • Measures     │         │                  │         │                  │
│  • Calculates   │         │   Firebase       │         │                  │
│  • Sends Data   │         │   Cloud          │────FCM──▶│  Push            │
│                 │         │   Messaging      │         │  Notifications   │
│     ↓           │         │                  │         │                  │
│                 │         └──────────────────┘         └──────────────────┘
│  LED Indicator  │
│  • Full: Fast   │
│  • OK: Slow     │
│  • Empty: On    │
│                 │
└─────────────────┘
```

## 2. Data Flow Diagram

```
[ESP32 Sensor] ──(1. Measure Distance)──▶ [Ultrasonic Sensor]
                                                │
                                                │ 2. Return Distance (cm)
                                                ▼
[ESP32 Processor] ◀──────────────────────────────┘
       │
       │ 3. Calculate Fill Level (%)
       │
       ├─────────────▶ [LED Indicator] (Visual Status)
       │
       │ 4. Create JSON Payload
       │    {
       │      "fillLevel": 85,
       │      "status": "FULL",
       │      "lastUpdated": timestamp
       │    }
       │
       │ 5. HTTP POST via WiFi
       ▼
[Firebase Firestore]
       │
       │ 6. Real-time Stream
       │
       ▼
[Flutter App - StreamBuilder]
       │
       │ 7. Update UI
       │
       ▼
[User's Phone Screen]
       │
       │ 8. If fillLevel >= 80%
       ▼
[Firebase Cloud Messaging]
       │
       │ 9. Push Notification
       ▼
[User's Phone - Notification]
```

## 3. Component Interaction Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                    SmartBin Components                        │
└──────────────────────────────────────────────────────────────┘

┌─────────────┐      ┌──────────────┐      ┌─────────────────┐
│  Physical   │      │   Digital    │      │   User          │
│  Layer      │      │   Layer      │      │   Interface     │
└─────────────┘      └──────────────┘      └─────────────────┘

    Bin                  ESP32              Flutter App
    │                      │                     │
    │ Waste Level         │                     │
    │─────────────────────▶│                     │
    │                      │                     │
    │                      │ fillLevel: 85%      │
    │                      │─────────────────────▶│
    │                      │                     │
    │                      │                     │ Display
    │                      │                     │ Status
    │                      │                     │
    │                      │◀─────────────────────│
    │                      │  Mark as Emptied    │
    │                      │                     │
    │◀─────────────────────│                     │
    │ (User Empties Bin)   │ Reset to 0%         │
    │                      │─────────────────────▶│
    │                      │                     │ Update
    │                      │                     │ Display
```

## 4. Hardware Wiring Diagram

```
                    ESP32 Development Board
        ┌────────────────────────────────────────┐
        │                                        │
        │  ┌──────┐      ┌──────┐      ┌──────┐│
        │  │ 3.3V │      │  5V  │      │ GND  ││
        │  └───┬──┘      └───┬──┘      └───┬──┘│
        │      │             │              │   │
        │      │             │              │   │
        │  ┌───┴──┐      ┌───┴──┐      ┌───┴──┐│
        │  │ GPIO │      │ GPIO │      │ GPIO ││
        │  │  5   │      │  18  │      │  2   ││
        │  └───┬──┘      └───┬──┘      └───┬──┘│
        │      │             │              │   │
        └──────┼─────────────┼──────────────┼───┘
               │             │              │
               │TRIG    ECHO│              │
          ┌────┴────┬────────┴────┐        │
          │   VCC   │    GND      │        │
          │    ↑    │     ↓       │        │
          │    5V   │    GND      │        │
          └─────────┴─────────────┘        │
          HC-SR04 Ultrasonic Sensor        │
                                           │
                                    ┌──────┴────┐
                                    │    LED    │
                                    │  (+) (-)  │
                                    │    │  │   │
                                    │    │  └───┼─── GND
                                    │    │      │
                                    │    └──[220Ω Resistor]
                                    │           │
                                    └───────────┘

Connections Summary:
• HC-SR04 VCC  → ESP32 5V/VIN
• HC-SR04 TRIG → ESP32 GPIO 5
• HC-SR04 ECHO → ESP32 GPIO 18
• HC-SR04 GND  → ESP32 GND
• LED Anode    → ESP32 GPIO 2
• LED Cathode  → 220Ω Resistor → ESP32 GND
```

## 5. App Screen Flow

```
┌─────────────────────┐
│   App Launches      │
│                     │
│  ┌───────────────┐  │
│  │  Firebase     │  │
│  │  Initialize   │  │
│  └───────┬───────┘  │
│          │          │
│          ▼          │
│  ┌───────────────┐  │
│  │ Get Started   │  │
│  │   Screen      │  │
│  │               │  │
│  │  [Icon]       │  │
│  │  Smart Bin    │  │
│  │               │  │
│  │ [Get Started] │──┼─── Click Button
│  └───────────────┘  │
└─────────────────────┘
            │
            ▼
┌─────────────────────┐
│  My Bins Screen     │
│                     │
│  ┌──────────────┐   │
│  │  OVERVIEW    │   │
│  │  My Bins   🔔 │   │
│  └──────────────┘   │
│                     │
│  ┌──────────────┐   │
│  │ Kitchen Bin  │   │
│  │  [95%] FULL  │◀──┼─── Real-time Stream
│  │  Est: 1-2hrs │   │     from Firestore
│  └──────────────┘   │
│                     │
│  ┌──────────────┐   │
│  │ Office Bin   │   │
│  │  [30%] OK    │   │
│  │  Est: 3 days │   │
│  └──────────────┘   │
│                     │
│  ┌──────────────┐   │
│  │ Garage Bin   │   │
│  │  [0%] EMPTY  │   │
│  │  Est: 7+ days│   │
│  └──────────────┘   │
│                     │
│  ┌──────────────┐   │
│  │ Last Emptied │   │
│  │ Kitchen Bin  │   │
│  │ 1 day ago    │   │
│  └──────────────┘   │
└─────────────────────┘
```

## 6. Firebase Data Structure

```
Firebase Project: SmartBin
│
├── Firestore Database
│   │
│   ├── Collection: bins
│   │   │
│   │   ├── Document: auto-id-1
│   │   │   ├── name: "Kitchen Bin"
│   │   │   ├── fillLevel: 95
│   │   │   ├── status: "FULL"
│   │   │   ├── estimatedFullTime: "1-2 hours"
│   │   │   ├── lastEmptied: Timestamp
│   │   │   └── lastUpdated: Timestamp
│   │   │
│   │   ├── Document: auto-id-2
│   │   │   ├── name: "Office Bin"
│   │   │   └── ...
│   │   │
│   │   └── Document: auto-id-3
│   │       ├── name: "Garage Bin"
│   │       └── ...
│   │
│   └── Collection: deviceTokens
│       └── Document: currentDevice
│           ├── token: "FCM_TOKEN"
│           └── updatedAt: Timestamp
│
├── Cloud Messaging (FCM)
│   ├── Device Tokens
│   ├── Notification Campaigns
│   └── Analytics
│
└── Authentication (Optional)
    ├── Email/Password
    └── Anonymous
```

## 7. Status Color Coding

```
Fill Level         Status       Color    LED Behavior
─────────────────────────────────────────────────────
0% - 39%          EMPTY        🔵 Blue   Solid On
40% - 79%         OK           🟢 Green  Slow Blink
80% - 100%        FULL         🔴 Red    Fast Blink
```

## 8. Timeline & Milestones

```
Week 1: Planning & Research
├─ Define requirements
├─ Choose technology stack
└─ Design system architecture

Week 2: Backend Setup
├─ Create Firebase project
├─ Setup Firestore database
└─ Configure security rules

Week 3: Hardware Development
├─ Assemble ESP32 circuit
├─ Test ultrasonic sensor
└─ Write Arduino code

Week 4: Mobile App Development
├─ Create Flutter project
├─ Design UI screens
├─ Implement Firebase integration
└─ Add real-time updates

Week 5: Integration & Testing
├─ Connect ESP32 to Firebase
├─ Test end-to-end system
├─ Fix bugs and optimize
└─ Add notifications

Week 6: Documentation & Presentation
├─ Write documentation
├─ Create demo video
├─ Prepare presentation
└─ Final testing
```

## 9. Technology Stack

```
┌─────────────────────────────────────────────────┐
│              Technology Stack                    │
├─────────────────────────────────────────────────┤
│                                                  │
│  Frontend (Mobile)                               │
│  ├─ Flutter 3.9.2+                              │
│  ├─ Dart                                        │
│  └─ Material Design                             │
│                                                  │
│  Backend (Cloud)                                 │
│  ├─ Firebase Firestore (Database)              │
│  ├─ Firebase Cloud Messaging (Notifications)   │
│  └─ Firebase Authentication (Optional)          │
│                                                  │
│  Hardware (IoT)                                  │
│  ├─ ESP32 Microcontroller                      │
│  ├─ HC-SR04 Ultrasonic Sensor                  │
│  ├─ LED Indicator                               │
│  └─ Arduino IDE                                 │
│                                                  │
│  Communication                                   │
│  ├─ WiFi (802.11 b/g/n)                        │
│  ├─ HTTP/HTTPS                                  │
│  └─ WebSocket (Real-time stream)               │
│                                                  │
│  Development Tools                               │
│  ├─ VS Code                                     │
│  ├─ Arduino IDE                                 │
│  ├─ Firebase Console                            │
│  └─ Git/GitHub                                  │
│                                                  │
└─────────────────────────────────────────────────┘
```

## 10. Use Case Diagram

```
                    SmartBin System Use Cases

┌────────────────────────────────────────────────────────────┐
│                                                            │
│   ┌─────────┐                                             │
│   │  User   │                                             │
│   └────┬────┘                                             │
│        │                                                   │
│        ├──────────▶ View Bin Status                       │
│        │                                                   │
│        ├──────────▶ Receive Notifications                 │
│        │                                                   │
│        ├──────────▶ Check Fill Level                      │
│        │                                                   │
│        ├──────────▶ View Estimated Full Time              │
│        │                                                   │
│        └──────────▶ Mark Bin as Emptied                   │
│                                                            │
│                                                            │
│   ┌──────────┐                                            │
│   │  ESP32   │                                            │
│   └────┬─────┘                                            │
│        │                                                   │
│        ├──────────▶ Measure Distance                      │
│        │                                                   │
│        ├──────────▶ Calculate Fill Level                  │
│        │                                                   │
│        ├──────────▶ Send Data to Firebase                 │
│        │                                                   │
│        └──────────▶ Control LED Status                    │
│                                                            │
│                                                            │
│   ┌──────────┐                                            │
│   │ Firebase │                                            │
│   └────┬─────┘                                            │
│        │                                                   │
│        ├──────────▶ Store Bin Data                        │
│        │                                                   │
│        ├──────────▶ Stream Real-time Updates              │
│        │                                                   │
│        └──────────▶ Send Push Notifications               │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## For Your Presentation

Use these diagrams in your PowerPoint/presentation:
1. System Architecture (Overview)
2. Data Flow (How it works)
3. Hardware Wiring (Technical detail)
4. App Screen Flow (User experience)
5. Firebase Structure (Database design)
6. Technology Stack (Implementation)

## Creating Visual Diagrams

You can create professional diagrams using:
- **Draw.io** (free, web-based)
- **Lucidchart** (free tier available)
- **Microsoft Visio** (if available)
- **PowerPoint** (built-in shapes)
- **Figma** (for UI mockups)

Simply copy the ASCII diagrams above and recreate them visually!

---

**These diagrams will help explain your project clearly!** 📊
