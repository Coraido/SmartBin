# Firebase Setup Instructions for SmartBin

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Enter project name: **SmartBin**
4. Disable Google Analytics (optional for this project)
5. Click "Create Project"

## Step 2: Enable Firestore Database

1. In Firebase Console, click **"Firestore Database"** in left menu
2. Click **"Create database"**
3. Select **"Start in test mode"** (for development)
4. Choose your location (closest to you)
5. Click **"Enable"**

## Step 3: Set Security Rules (Test Mode)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all bins
    match /bins/{binId} {
      allow read, write: if true;
    }
    
    // Allow read/write access to device tokens
    match /deviceTokens/{tokenId} {
      allow read, write: if true;
    }
  }
}
```

**Note:** For production, you should implement proper authentication and security rules.

## Step 4: Create Sample Bins

### Option A: Manual Creation (Firebase Console)

1. Click **"Start collection"**
2. Collection ID: `bins`
3. Click **"Next"**
4. Create first bin:
   - **Document ID:** Auto-ID (or `kitchen_bin`)
   - Add fields:
     ```
     name: "Kitchen Bin" (string)
     fillLevel: 95 (number)
     status: "FULL" (string)
     estimatedFullTime: "1-2 hours" (string)
     lastEmptied: [Click timestamp, select current date] (timestamp)
     lastUpdated: [Click timestamp, select current date] (timestamp)
     ```
5. Click **"Save"**

6. Add more bins by clicking **"Add document"**:
   
   **Office Bin:**
   ```
   name: "Office Bin"
   fillLevel: 30
   status: "OK"
   estimatedFullTime: "3 days"
   lastEmptied: [2 days ago]
   lastUpdated: [Now]
   ```
   
   **Garage Bin:**
   ```
   name: "Garage Bin"
   fillLevel: 0
   status: "EMPTY"
   estimatedFullTime: "7+ days"
   lastEmptied: [Now]
   lastUpdated: [Now]
   ```

### Option B: Automatic Creation (Through App)

The app will automatically create sample bins when you first run it if no bins exist!

Just run the app and it will call `createInitialBins()` in `firebase_service.dart`.

## Step 5: Enable Cloud Messaging (for Notifications)

1. Click **"Cloud Messaging"** in left menu
2. Click **"Get Started"**
3. Follow the setup wizard
4. Download configuration files:
   - **Android:** `google-services.json` → Place in `android/app/`
   - **iOS:** `GoogleService-Info.plist` → Place in `ios/Runner/`

## Step 6: Get Your Firebase Configuration

### For Android App:

1. Click Settings (⚙️) → Project Settings
2. Under "Your apps", click Android icon
3. Register app with package name: `com.example.smart_bin_app`
4. Download `google-services.json`
5. Place file in: `android/app/google-services.json`

### For Web App:

1. Click Settings (⚙️) → Project Settings
2. Under "Your apps", click Web icon `</>`
3. Register app with name: "SmartBin Web"
4. Copy the configuration (already in `lib/firebase_options.dart`)

## Step 7: Get API Key & Database URL (for ESP32)

1. Click Settings (⚙️) → Project Settings
2. Copy **Web API Key** (something like: `AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`)
3. Note your **Project ID** (e.g., `smartbin-12345`)
4. Your Database URL is: `https://smartbin-12345.firebaseio.com`

Update these in your Arduino code:
```cpp
const char* firebaseHost = "https://YOUR-PROJECT-ID.firebaseio.com";
const char* firebaseAuth = "YOUR_WEB_API_KEY";
```

## Step 8: Test Firebase Connection

### From Flutter App:

1. Run the app: `flutter run -d chrome`
2. Open browser to http://localhost:8080
3. Click "Get Started"
4. You should see your bins!

### From ESP32:

1. Upload Arduino code to ESP32
2. Open Serial Monitor (115200 baud)
3. Watch for:
   ```
   WiFi connected!
   Distance: 25 cm | Fill Level: 15%
   Data sent! Response: 200
   ```

4. Check Firebase Console
5. Watch `fillLevel` update in real-time!

## Firestore Data Structure

```
smartbin-project (Your Project)
│
└── (firestore database)
    │
    ├── bins (collection)
    │   ├── [auto-generated-id-1] (document)
    │   │   ├── name: "Kitchen Bin"
    │   │   ├── fillLevel: 95
    │   │   ├── status: "FULL"
    │   │   ├── estimatedFullTime: "1-2 hours"
    │   │   ├── lastEmptied: Timestamp
    │   │   └── lastUpdated: Timestamp
    │   │
    │   ├── [auto-generated-id-2] (document)
    │   │   ├── name: "Office Bin"
    │   │   └── ...
    │   │
    │   └── [auto-generated-id-3] (document)
    │       ├── name: "Garage Bin"
    │       └── ...
    │
    └── deviceTokens (collection)
        └── currentDevice (document)
            ├── token: "FCM_TOKEN_STRING"
            └── updatedAt: Timestamp
```

## Security Rules for Production

When you're ready to deploy, update rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Require authentication
    match /bins/{binId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      request.auth.token.admin == true;
    }
    
    match /deviceTokens/{tokenId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Firebase Cloud Functions (Optional - Advanced)

To send automatic notifications when bins are full:

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.checkBinStatus = functions.firestore
  .document('bins/{binId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    
    // If bin just became full
    if (newData.fillLevel >= 80 && oldData.fillLevel < 80) {
      // Get device token
      const tokenDoc = await admin.firestore()
        .collection('deviceTokens')
        .doc('currentDevice')
        .get();
      
      const token = tokenDoc.data().token;
      
      // Send notification
      const message = {
        notification: {
          title: '🚨 Bin Full Alert!',
          body: `${newData.name} is ${newData.fillLevel}% full!`
        },
        token: token
      };
      
      await admin.messaging().send(message);
      console.log('Notification sent!');
    }
  });
```

Deploy:
```bash
firebase login
firebase init functions
firebase deploy --only functions
```

## Troubleshooting

### Error: "Permission denied"
**Solution:** Make sure Firestore rules allow access (test mode)

### Error: "Network request failed"
**Solution:** Check internet connection and Firebase URL

### Error: "Invalid API key"
**Solution:** Regenerate API key in Firebase Console → Settings

### Bins not showing in app
**Solution:** 
1. Check Firebase Console has bins collection
2. Verify collection name is exactly "bins" (lowercase)
3. Check documents have all required fields

### ESP32 can't send data
**Solution:**
1. Verify Firebase URL format: `https://PROJECT-ID.firebaseio.com`
2. Check API key is correct
3. Ensure WiFi is connected
4. Check bin ID matches Firestore document ID

## Useful Firebase Console Shortcuts

- **View data:** Firestore Database → Data tab
- **See usage:** Project Usage
- **Check logs:** Functions → Logs (if using Functions)
- **Test rules:** Firestore → Rules → Simulator

## Next Steps

1. ✅ Firebase project created
2. ✅ Firestore enabled with test rules
3. ✅ Sample bins created
4. ✅ Cloud Messaging configured
5. ✅ Configuration files downloaded
6. ✅ API keys noted for ESP32
7. ⏭️ Run Flutter app
8. ⏭️ Upload ESP32 code
9. ⏭️ Test complete system!

---

**Need Help?**
- Firebase Docs: https://firebase.google.com/docs/firestore
- Firebase Console: https://console.firebase.google.com
- Support: Check your project's README.md and QUICKSTART.md

**Your Firebase is ready for SmartBin! 🎉**
