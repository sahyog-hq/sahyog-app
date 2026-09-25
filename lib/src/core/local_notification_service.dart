import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles local push notifications for BLE mesh SOS alerts
/// when the app is backgrounded or the screen is locked.
class LocalNotificationService {
  static final LocalNotificationService instance = LocalNotificationService._();
  LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Call once at app startup (e.g., in main.dart or auth_gate.dart)
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Tapping the notification — the app will open to the current screen.
        debugPrint('[LocalNotification] Tapped notification: ${response.payload}');
      },
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // Explicitly create High Importance Notification Channel for Android 8.0+
    const channel = AndroidNotificationChannel(
      'sahyog_mesh_sos_v4', // New channel ID to override cached system channel settings
      'Mesh SOS Alerts', // Channel Name
      description: 'High-priority emergency notifications for BLE mesh SOS alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.requestNotificationsPermission();

    // Request permissions on iOS
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
    debugPrint('[LocalNotification] Initialized successfully');
  }

  /// Show a high-priority SOS notification from BLE mesh
  Future<void> showMeshSosNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      debugPrint('[LocalNotification] Not initialized, trying to initialize now...');
      await initialize();
    }

    final androidDetails = AndroidNotificationDetails(
      'sahyog_mesh_sos_v4', // Channel ID matching created channel
      'Mesh SOS Alerts', // Channel Name
      channelDescription: 'High-priority notifications for BLE mesh SOS alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      ticker: 'SOS Alert Nearby',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use 32-bit integer ID for native Android compatibility
    final notificationId = (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 2147483647;

    await _plugin.show(
      notificationId,
      title,
      body,
      details,
      payload: payload,
    );
  }
}
