// ============================================================
//  Notification Service
//  Handles Firebase Cloud Messaging (FCM) push notifications
//  and local notifications for both Android and iOS.
// ============================================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize both local notifications and FCM.
  Future<void> init() async {
    // ── 1. Local notification setup ─────────────────────────
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'chatizy_messages',
            'Messages',
            description: 'Chatizy message notifications',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
        );

    // ── 2. FCM permission request ───────────────────────────
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print('[FCM] Permission status: ${settings.authorizationStatus}');

    // ── 3. Get FCM token ────────────────────────────────────
    _fcmToken = await _fcm.getToken();
    print('[FCM] Token: $_fcmToken');

    // Upload token to server
    if (_fcmToken != null) {
      await _uploadFcmToken(_fcmToken!);
    }

    // Listen for token refreshes
    _fcm.onTokenRefresh.listen((newToken) async {
      print('[FCM] Token refreshed: $newToken');
      _fcmToken = newToken;
      await _uploadFcmToken(newToken);
    });

    // ── 4. Foreground message handler ───────────────────────
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // ── 5. Message opened app handler ───────────────────────
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Upload FCM token to Supabase devices table.
  Future<void> _uploadFcmToken(String token) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('chatizy_device_id');
      if (deviceId != null) {
        await client
            .from('devices')
            .update({'push_token': token})
            .eq('id', deviceId);
        print('[FCM] Token uploaded for current device $deviceId');
      } else {
        print('[FCM] Device not registered yet, token upload deferred');
      }
    } catch (e) {
      print('[FCM] Failed to upload token: $e');
    }
  }

  /// Upload FCM token for a specific device ID.
  Future<void> uploadTokenForDevice(String deviceId) async {
    if (_fcmToken == null) {
      _fcmToken = await _fcm.getToken();
    }
    if (_fcmToken == null) return;

    try {
      final client = Supabase.instance.client;
      await client
          .from('devices')
          .update({'push_token': _fcmToken})
          .eq('id', deviceId);
      print('[FCM] Token uploaded for device $deviceId');
    } catch (e) {
      print('[FCM] Failed to upload token for device: $e');
    }
  }

  /// Handle foreground FCM message — show local notification.
  void _handleForegroundMessage(RemoteMessage message) {
    print('[FCM] Foreground message: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    // Use notification payload if available, else use data
    final title = notification?.title ?? data['title'] ?? 'Chatizy';
    final body = notification?.body ?? data['body'] ?? 'New message';
    final conversationId = data['conversation_id'];

    showNotification(
      id: message.hashCode,
      title: title,
      body: body,
      payload: conversationId,
    );
  }

  /// Handle notification tap when app is in background.
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('[FCM] Message opened app: ${message.data}');
    // Navigation to specific conversation can be handled here
    // via a global navigator key or route observer
  }

  /// Handle notification tap from local notification.
  void _onNotificationTapped(NotificationResponse response) {
    print('[Notification] Tapped: ${response.payload}');
    // Navigate to conversation if payload contains conversation_id
  }

  /// Show a local notification (used for foreground FCM + background fetch).
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chatizy_messages',
      'Messages',
      channelDescription: 'Chatizy message notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: payload,
    );
  }
}

/// Top-level background message handler for FCM.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[FCM] Background message: ${message.messageId}');
  // Firebase will automatically show the notification if
  // the message contains a 'notification' payload.
  // No additional handling needed for basic push display.
}
