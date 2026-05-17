import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles FCM push notifications for mobile platforms.
/// - Requests permission
/// - Saves FCM token to Firestore
/// - Shows local notifications when app is in foreground
/// - Handles background message taps
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize(String userId) async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    // Request permission (iOS shows a dialog, Android 13+ shows a dialog)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications for foreground display
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'likealocal_default',
        'LikeALocal Notifications',
        description: 'Notifications for messages, ratings, and updates',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // Get and save FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(userId, token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _saveToken(userId, newToken);
    });

    // Foreground messages — show as local notification
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // Background message tap — handle navigation
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('PushNotificationService: saved FCM token for $userId');
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'LikeALocal',
      notification.body ?? '',
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'likealocal_default',
          'LikeALocal Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    // Data payload can contain navigation info
    debugPrint('PushNotificationService: tapped notification — ${message.data}');
    // Navigation can be handled via a global key or event bus
  }

  /// Unregister token on sign-out
  Future<void> clearToken(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'fcmToken': FieldValue.delete(),
    });
    _initialized = false;
  }
}
