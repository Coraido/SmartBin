# 🔑 How to Get Your Web API Key

## The Problem
You see: **"No Web API Key for this project"**

This means you haven't added a **Web App** to your Firebase project yet!

---

## ✅ Solution: Add a Web App

Follow these steps **exactly**:

### Step 1: Go to Project Settings
1. Open Firebase Console: https://console.firebase.google.com
2. Select **SmartBin** project
3. Click the **⚙️ gear icon** → **Project Settings**
4. Make sure you're on the **"General"** tab

---

### Step 2: Add Web App
1. **Scroll down** to the section titled **"Your apps"**
2. You should see: "No Web API Key for this project"
3. Look for the **web icon** `</>` or a button that says **"Add app"**
4. **Click the Web icon** `</>`

---

### Step 3: Register the App
A dialog will pop up asking for details:

1. **App nickname:** Type `SmartBin Web`
2. **Firebase Hosting:** ❌ **Leave this UNCHECKED** (not needed)
3. Click the blue **"Register app"** button

---

### Step 4: Get Your API Key
After clicking "Register app", you'll see a code snippet:

```javascript
// Add Firebase to your web app
const firebaseConfig = {
  apiKey: "AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxxxx",        ← COPY THIS!
  authDomain: "smartbin-c8ef7.firebaseapp.com",
  projectId: "smartbin-c8ef7",
  storageBucket: "smartbin-c8ef7.appspot.com",
  messagingSenderId: "4310803131389",
  appId: "1:4310803131389:web:xxxxxxxxxxxxxxxxxx"
};
```

**Copy the `apiKey` value!**

Example: `AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxxxx`

---

### Step 5: Save Your Credentials
1. Click **"Continue to console"** 
2. Now go back to Project Settings → General tab
3. You should now see your **Web API Key** displayed!
4. Save it in your notes

---

## 📋 Your Complete Credentials

After adding the web app, you'll have:

```txt
FIREBASE CREDENTIALS
====================

✅ Project ID: smartbin-c8ef7
✅ Project Number: 4310803131389
✅ Web API Key: AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxx  ← You just got this!

For ESP32:
---------
Database URL: https://smartbin-c8ef7.firebaseio.com
Or Firestore URL: https://firestore.googleapis.com/v1/projects/smartbin-c8ef7/databases/(default)/documents
```

---

## 🎯 What to Do Next

**Once you have the API Key:**

1. ✅ Save it in a safe place
2. ✅ You'll use it for ESP32 later
3. ✅ Continue with Step 4: Create bins
4. ✅ Open your app: http://localhost:8081

---

## 🔍 Where to Find API Key Later

If you need to find it again:

1. Firebase Console → Project Settings
2. General tab
3. Scroll to "Your apps"
4. Click on "SmartBin Web" (your web app)
5. You'll see the config snippet with the API key

Or:

1. Look in your Flutter project
2. File: `lib/firebase_options.dart`
3. Search for `apiKey`
4. It's already there! Flutter CLI added it automatically

---

## 🆘 Troubleshooting

### "I don't see the </> icon"
- Make sure you're in Project Settings → General tab
- Scroll down to "Your apps" section
- Look for buttons with platform icons (Web, iOS, Android)
- The web icon looks like: `</>`

### "I already clicked Register but didn't save the key"
- Go to Project Settings → General
- Under "Your apps", click on "SmartBin Web"
- You'll see the config snippet again
- Copy the apiKey from there

### "Can I use my app without the API key?"
- Your Flutter app will work fine (it has the key in firebase_options.dart)
- But you **NEED** the API key for ESP32 hardware setup
- So make sure to save it!

---

## ✅ Success Checklist

- [ ] Added web app to Firebase project
- [ ] App nickname: "SmartBin Web"
- [ ] Got the Firebase config snippet
- [ ] Copied the API Key (starts with AIzaSy...)
- [ ] Saved credentials for ESP32
- [ ] Web API Key now shows in Project Settings

**All done? Continue to Step 4 to create your bins!** 🎉
