import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Instance for foreground alerts
  static final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  // --- 1. Initialization for Token & Permissions ---
  Future<void> initialize(String systemId) async {
    // Pop up on phone asking permission from user to send notifications
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true, // banners
      badge: true, // little red number on the app icon
      sound: true,
    );

    // User clicks "Allow"
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Built in function to obtain token for the specific phone
      String? token = await _fcm.getToken();
      if (token != null) {
        // Save to the specific system document
        await _saveTokenToFirestore(systemId, token);
      }
    }
  }

  Future<void> _saveTokenToFirestore(String systemId, String token) async {
    // Correctly normalizes "System 1" -> "system_1" or "System 2" -> "system_2"
    final String docId = systemId.toLowerCase().replaceAll(' ', '_');

    await _db.collection('data_thresholds').doc(docId).set({
      'fcmToken': token,
    }, SetOptions(merge: true));

    print("FCM Token synced for $systemId");
  }

  // Showing the notification banner when app is open
  Future<void> initForegroundNotifications() async {
    // 1. Create the high importance channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // Channel ID matched with Pi
      'Algae Alerts',
      importance: Importance.max, // Ensures it pops up and makes sound
    );

    // Check if the current device is an Android phone, access the underlying Android system code
    // If Android, register "channel" with Android System Settings
    await _localPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 2. Basic initialization (No click handlers)
    const InitializationSettings initSettings = InitializationSettings(
      // Takes app's main icon to show on notification banner
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    // Turns on plugin
    await _localPlugin.initialize(initSettings);

    // 3. Listen for FCM messages and trigger the local banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message, channel);
      }
    });
  }

  // Takes the data and physically draws the notification banner on the user's screen
  void _showLocalNotification(
      RemoteMessage message, AndroidNotificationChannel channel) {
    _localPlugin.show(
      message.notification.hashCode, // Notification unique ID
      message.notification!.title, // Sent from Pi
      message.notification!.body, // Sent from Pi
      // Notification details created earlier
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          importance: channel.importance,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
