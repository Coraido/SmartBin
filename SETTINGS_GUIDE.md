# SmartBin Functional Settings Guide

## Overview
The SmartBin app now has a fully functional settings system with persistent storage. All settings are automatically saved and will be remembered when you restart the app.

---

## Settings Features

### 📱 **Notifications**
Control how and when you receive alerts from your smart bins.

#### **Enable Notifications**
- **Function**: Master switch for all notification features
- **Default**: ON
- **How it works**: When enabled, allows the app to send push notifications to your device
- **Note**: Turning this OFF disables all notification-related features below

#### **Full Bin Alerts** 
- **Function**: Get notified when bins reach the alert threshold
- **Default**: ON
- **How it works**: 
  - Monitors bin fill levels in real-time
  - Sends notification when fill level reaches your set threshold (default 80%)
  - Only triggers once until the bin is emptied
  - Requires "Enable Notifications" to be ON

#### **Daily Summary**
- **Function**: Receive daily reports about all your bins
- **Default**: OFF
- **How it works**: 
  - Sends a summary notification once per day
  - Includes status of all bins (fill levels, estimated times)
  - Useful for planning waste collection schedules
  - Requires "Enable Notifications" to be ON

#### **Sound**
- **Function**: Play sound with notifications
- **Default**: ON
- **How it works**: 
  - Adds audio alert to notifications
  - Helps ensure you don't miss important alerts
  - Can be turned off for silent notifications
  - Requires "Enable Notifications" to be ON

---

### 🔔 **Alert Settings**

#### **Alert Threshold Slider**
- **Function**: Set the fill level percentage that triggers alerts
- **Range**: 50% - 95%
- **Default**: 80%
- **How it works**:
  - Bins will send alerts when they reach this percentage
  - Lower values = earlier warnings (e.g., 60% warns sooner)
  - Higher values = later warnings (e.g., 90% warns when nearly full)
  - Adjusts in 5% increments
  - Changes apply immediately to all bins

**Example Scenarios:**
- **60%**: Get early warnings for bins that fill quickly
- **80%**: Standard - good balance for most households
- **95%**: Only notify when bin is almost completely full

---

### 🎨 **App Settings**

#### **Dark Mode**
- **Function**: Toggle between light and dark theme
- **Default**: Light mode
- **How it works**:
  - Instantly switches app appearance
  - Light mode: Clean white background, easy daytime viewing
  - Dark mode: Dark background, easier on eyes at night, saves battery
  - Preference is saved and persists across app restarts
  - Applies to all screens in the app

---

### 💾 **Data Management**

#### **Export Data**
- **Function**: Download your bin monitoring data
- **How it works**: 
  - Creates a file with all your bin history
  - Useful for tracking waste patterns over time
  - Can be opened in spreadsheet applications

#### **Clear History**
- **Function**: Remove old bin records
- **Warning**: This action cannot be undone
- **How it works**: 
  - Shows confirmation dialog before deleting
  - Only removes historical data, not current bin status
  - Frees up storage space

---

### ℹ️ **About**

#### **Help & Support**
- Get assistance with SmartBin features

#### **Privacy Policy**
- View how your data is handled

#### **About SmartBin**
- Version information and credits
- Current Version: 1.0.0

---

## How Settings Work Behind the Scenes

### Persistent Storage
- All settings are saved using `SharedPreferences`
- Changes are immediately written to device storage
- Settings survive app restarts and device reboots
- No internet connection needed to save settings

### Real-Time Updates
- Settings changes are applied instantly
- No need to restart the app
- Theme changes animate smoothly
- Notification preferences sync with Firebase

### Alert Monitoring System
The app continuously monitors your bins and:
1. Checks fill levels every time data updates from Firebase
2. Compares fill level against your alert threshold setting
3. Sends notification if:
   - Notifications are enabled
   - Full bin alerts are enabled
   - Fill level ≥ alert threshold
   - Bin hasn't already triggered an alert
4. Resets alert status when bin is emptied (fill level drops below threshold)

---

## Settings Integration with Hardware

### ESP32 Arduino Integration
The alert threshold setting directly affects the Arduino system:

```cpp
// Arduino checks Firebase for user's alert threshold
int alertThreshold = 80; // Gets this from your app settings

void checkBinStatus() {
  if (currentFillLevel >= alertThreshold) {
    // Trigger buzzer alert
    soundBuzzer();
    // Update Firebase to notify app
    updateFirebase();
  }
}
```

### Notification Flow
1. **Bin fills up** → ESP32 measures distance
2. **Fill level calculated** → Synced to Firebase Realtime Database
3. **App monitors Firebase** → Detects fill level change
4. **Settings checked** → Is fill level ≥ alert threshold?
5. **Alert sent** → Notification pushed to device (if enabled)
6. **Buzzer sounds** → ESP32 beeps (if hardware connected)

---

## Tips for Optimal Use

### Recommended Settings for Different Scenarios

#### **Busy Household**
```
✅ Enable Notifications: ON
✅ Full Bin Alerts: ON
✅ Daily Summary: ON
✅ Sound: ON
⚙️ Alert Threshold: 70%
```
Early warnings help prevent overflow in high-traffic areas.

#### **Office Environment**
```
✅ Enable Notifications: ON
✅ Full Bin Alerts: ON
✅ Daily Summary: OFF
✅ Sound: OFF
⚙️ Alert Threshold: 85%
```
Silent alerts during work hours, notifies when nearly full.

#### **Low-Use Area**
```
✅ Enable Notifications: ON
✅ Full Bin Alerts: ON
✅ Daily Summary: ON
✅ Sound: OFF
⚙️ Alert Threshold: 90%
```
Get daily summaries to track slow-filling bins.

#### **Testing/Development**
```
✅ Enable Notifications: ON
✅ Full Bin Alerts: ON
✅ Daily Summary: OFF
✅ Sound: ON
⚙️ Alert Threshold: 50%
```
Lower threshold helps test notification system quickly.

---

## Troubleshooting

### Notifications Not Working?
1. Check "Enable Notifications" is ON in settings
2. Check "Full Bin Alerts" is ON
3. Verify browser/device notification permissions
4. Check Firebase connection in console
5. Ensure bin fill level ≥ alert threshold

### Dark Mode Not Saving?
1. Settings save automatically - no action needed
2. If resets on restart, check device storage permissions
3. Try toggling theme again

### Alert Threshold Not Working?
1. Check if notifications are enabled
2. Verify bin fill level reaches the threshold
3. Alert only triggers once per fill cycle
4. Empty bin to reset alert status

### Settings Reset to Default?
1. May occur if SharedPreferences cache is cleared
2. Device storage might be full
3. Simply re-configure your preferences

---

## Technical Details

### Settings Service API
```dart
// Access settings anywhere in the app
final settings = SettingsService();

// Check if should alert
bool shouldAlert = settings.shouldAlert(binFillLevel);

// Get current values
bool notificationsOn = settings.notificationsEnabled;
int threshold = settings.alertThreshold;
ThemeMode theme = settings.themeMode;

// Update settings
await settings.setNotificationsEnabled(true);
await settings.setAlertThreshold(75);
await settings.toggleTheme();
```

### Storage Keys
Settings are stored with these keys:
- `notifications_enabled`
- `full_bin_alerts`
- `daily_summary`
- `sound_enabled`
- `alert_threshold`
- `theme_mode`

---

## Removed Features (As Requested)

The following sections have been removed from the settings screen:

❌ **User Account** - Profile management section removed  
❌ **Logout Button** - Authentication not implemented  
❌ **Language** - App currently supports English only  
❌ **Units** - Metric system used consistently  

---

## Future Enhancements (Potential)

- [ ] Multiple language support
- [ ] Custom notification sounds
- [ ] Scheduled quiet hours
- [ ] Per-bin notification preferences
- [ ] Data export formats (CSV, JSON, PDF)
- [ ] Cloud backup of settings
- [ ] Notification history viewer
- [ ] Alert frequency limiting

---

## Support

If you encounter issues with settings:
1. Check this guide for solutions
2. Verify Firebase connection
3. Check browser console for errors
4. Test with default settings first
5. Ensure app has necessary permissions

---

**Last Updated**: October 20, 2025  
**App Version**: 1.0.0  
**Settings Service Version**: 1.0.0

---

*SmartBin - Making waste management smarter, one bin at a time.* 🗑️✨
