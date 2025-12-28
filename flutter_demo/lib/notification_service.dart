import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Modified to accept a systemId
  Future<void> initialize(String systemId) async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _fcm.getToken();

      if (token != null) {
        // Save to the specific system document
        await _saveTokenToFirestore(systemId, token);
      }
    }

    // Handle token refreshes for the active system
    _fcm.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(systemId, newToken);
    });
  }

  Future<void> _saveTokenToFirestore(String systemId, String token) async {
    // Correctly normalizes "System 1" -> "system_1" or "System 2" -> "system_2"
    final String docId = systemId.toLowerCase().replaceAll(' ', '_');

    await _db.collection('data_thresholds').doc(docId).set({
      'fcmToken': token,
    }, SetOptions(merge: true));

    print("FCM Token synced for $systemId");
  }
}
