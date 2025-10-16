import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/bin_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Collection reference
  CollectionReference get binsCollection => _firestore.collection('bins');

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
            
            // Save token to Firestore
            await _firestore.collection('deviceTokens').doc('currentDevice').set({
              'token': token,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            print('✅ Token saved to Firestore');
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

  // Get all bins as a stream (real-time updates)
  Stream<List<BinModel>> getBinsStream() {
    return binsCollection
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BinModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get a single bin by ID
  Future<BinModel?> getBinById(String id) async {
    try {
      DocumentSnapshot doc = await binsCollection.doc(id).get();
      if (doc.exists) {
        return BinModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting bin: $e');
      return null;
    }
  }

  // Add a new bin (for testing or manual addition)
  Future<String?> addBin(BinModel bin) async {
    try {
      DocumentReference docRef = await binsCollection.add(bin.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding bin: $e');
      return null;
    }
  }

  // Update bin data (typically called by ESP32)
  Future<void> updateBinFillLevel(String binId, int fillLevel) async {
    try {
      await binsCollection.doc(binId).update({
        'fillLevel': fillLevel,
        'status': BinModel.getStatus(fillLevel),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating bin: $e');
    }
  }

  // Mark bin as emptied
  Future<void> markBinAsEmptied(String binId) async {
    try {
      await binsCollection.doc(binId).update({
        'fillLevel': 0,
        'status': 'EMPTY',
        'lastEmptied': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'estimatedFullTime': '7+ days',
      });
    } catch (e) {
      print('Error marking bin as emptied: $e');
    }
  }

  // Delete a bin
  Future<void> deleteBin(String binId) async {
    try {
      await binsCollection.doc(binId).delete();
    } catch (e) {
      print('Error deleting bin: $e');
    }
  }

  // Create initial bins for testing
  Future<void> createInitialBins() async {
    try {
      // Check if bins already exist
      QuerySnapshot snapshot = await binsCollection.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        print('Bins already exist');
        return;
      }

      // Create sample bins
      List<Map<String, dynamic>> initialBins = [
        {
          'name': 'Kitchen Bin',
          'fillLevel': 95,
          'status': 'FULL',
          'estimatedFullTime': '1-2 hours',
          'lastEmptied': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
          'lastUpdated': Timestamp.now(),
        },
        {
          'name': 'Office Bin',
          'fillLevel': 30,
          'status': 'OK',
          'estimatedFullTime': '3 days',
          'lastEmptied': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
          'lastUpdated': Timestamp.now(),
        },
        {
          'name': 'Garage Bin',
          'fillLevel': 0,
          'status': 'EMPTY',
          'estimatedFullTime': '7+ days',
          'lastEmptied': Timestamp.now(),
          'lastUpdated': Timestamp.now(),
        },
      ];

      for (var bin in initialBins) {
        await binsCollection.add(bin);
      }
      print('Initial bins created successfully');
    } catch (e) {
      print('Error creating initial bins: $e');
    }
  }
}
