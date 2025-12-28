import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'main.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Instance for foreground alerts
  static final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  // --- 1. Initialization for Token & Permissions ---
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

    // Handle background/terminated notification clicks
    _setupInteractedMessages();
  }

  Future<void> _saveTokenToFirestore(String systemId, String token) async {
    // Correctly normalizes "System 1" -> "system_1" or "System 2" -> "system_2"
    final String docId = systemId.toLowerCase().replaceAll(' ', '_');

    await _db.collection('data_thresholds').doc(docId).set({
      'fcmToken': token,
    }, SetOptions(merge: true));

    print("FCM Token synced for $systemId");
  }

  // --- 2. Initialization for Foreground Notifications & Click Handling ---
  Future<void> initForegroundNotifications() async {
    // 1. Setup Android Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Algae Alerts',
      importance: Importance.max,
    );

    await _localPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    // Initializing with a callback for notification clicks
    await _localPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // This handles clicks when the app is IN FOREGROUND
        _navigateToControl();
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message, channel);
      }
    });
  }

  // --- 3. Handle Clicks when App is Background/Terminated ---
  Future<void> _setupInteractedMessages() async {
    // Get message that opened the app from a terminated state
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _navigateToControl();
    }

    // Listen for messages that open the app from background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigateToControl();
    });
  }

  // Global Navigation Logic
  void _navigateToControl() {
    // This uses the navigatorKey from main.dart to move the UI
    // even if we don't have a 'BuildContext' here.
    navigatorKey.currentState?.pushNamed('/control');
  }

  void _showLocalNotification(
      RemoteMessage message, AndroidNotificationChannel channel) {
    _localPlugin.show(
      message.notification.hashCode,
      message.notification!.title,
      message.notification!.body,
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
