import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        return;
      }
      _messaging = FirebaseMessaging.instance;

      // Request permission
      await _messaging?.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Local notifications setup
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _localNotifications.initialize(settings);

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          _showLocalNotification(
            id: notification.hashCode,
            title: notification.title ?? 'Budget Planner',
            body: notification.body ?? '',
          );
        }
      });
      _isInitialized = true;
    } catch (_) {
      // Graceful fallback if Firebase is not fully configured on local platform
    }
  }

  Future<String?> getFcmToken() async {
    try {
      if (!_isInitialized || _messaging == null) return null;
      return await _messaging?.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'budget_planner_channel',
      'Budget Planner Reminders',
      channelDescription: 'Nhắc nhở điểm danh chi tiêu hàng ngày',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await _localNotifications.show(id, title, body, details);
  }
}

