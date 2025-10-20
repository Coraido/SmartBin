import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:smart_bin_app/models/bin_data.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Initialize Firebase Messaging
  Future<void> initializeNotifications() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permission');
        
        // Get FCM token
        try {
          String? token = await _messaging.getToken();
          if (token != null) {
            print('✅ FCM Token: $token');
            
            // Save token to Realtime Database
            await _database.child('deviceTokens/currentDevice').set({
              'token': token,
              'updatedAt': ServerValue.timestamp,
            });
            print('✅ Token saved to Database');
          } else {
            print('⚠️ FCM Token is null - service worker may not be registered yet');
          }
        } catch (tokenError) {
          print('⚠️ Error getting FCM token: $tokenError');
          print('This is normal on first run. Service worker needs to be registered.');
          print('Refresh the page to complete FCM setup.');
        }
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('❌ User denied notification permission');
      } else {
        print('⚠️ Notification permission not determined');
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📬 Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('🔔 Message also contained a notification: ${message.notification}');
        }
      });
    } catch (e) {
      print('⚠️ Error initializing notifications: $e');
      print('This is expected on web - FCM requires service worker setup.');
      print('The service worker file has been created. Please refresh the page.');
    }
  }

  // Get bin data stream
  Stream<BinData?> getBinDataStream(String binId) {
    return _database.child('bins/$binId').onValue.map((event) {
      if (event.snapshot.value != null) {
        return BinData.fromSnapshot(event.snapshot);
      }
      return null;
    });
  }

  // Get all bins stream
  Stream<List<BinData>> getAllBinsStream() {
    return _database.child('bins').onValue.map((event) {
      List<BinData> bins = [];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final snapshot = event.snapshot.child(key);
          bins.add(BinData.fromSnapshot(snapshot));
        });
      }
      return bins;
    });
  }

  // Update bin data (for testing purposes)
  Future<void> updateBinData(
    String binId, {
    String? name,
    int? fillLevel,
    String? status,
    String? estimatedFullIn,
  }) async {
    Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (fillLevel != null) updates['fill_level'] = fillLevel;
    if (status != null) updates['status'] = status;
    if (estimatedFullIn != null) updates['estimated_full_in'] = estimatedFullIn;
    updates['last_updated'] = ServerValue.timestamp;

    await _database.child('bins/$binId').update(updates);
  }

  // Mark bin as emptied
  Future<void> markBinAsEmptied(String binId) async {
    try {
      await _database.child('bins/$binId').update({
        'fill_level': 0,
        'status': 'EMPTY',
        'estimated_full_in': '7+ days',
        'last_updated': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error marking bin as emptied: $e');
    }
  }

  // Delete a bin
  Future<void> deleteBin(String binId) async {
    try {
      await _database.child('bins/$binId').remove();
    } catch (e) {
      print('Error deleting bin: $e');
    }
  }

  // Check if bin needs notification based on settings
  bool shouldNotify(BinData binData, int alertThreshold) {
    return binData.fillLevel >= alertThreshold;
  }
  
  // Send notification for bin alert
  Future<void> sendBinAlert(BinData binData) async {
    try {
      // Save notification to database for history
      await _database.child('notifications').push().set({
        'binId': binData.id,
        'binName': binData.name,
        'fillLevel': binData.fillLevel,
        'message': '${binData.name} is ${binData.fillLevel}% full!',
        'timestamp': ServerValue.timestamp,
        'read': false,
      });
      print('📬 Notification saved for ${binData.name}');
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  // Create initial bin for testing
  Future<void> createInitialBin() async {
    try {
      await _database.child('bins/kitchen_bin').set({
        'name': 'Kitchen Bin',
        'fill_level': 0,
        'status': 'EMPTY',
        'estimated_full_in': '7+ days',
        'last_updated': ServerValue.timestamp,
      });
      print('Initial bin created successfully');
    } catch (e) {
      print('Error creating initial bin: $e');
    }
  }
}
