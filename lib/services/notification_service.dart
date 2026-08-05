import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'supabase_service.dart';

/// Background message handler - MUST be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
  await NotificationService.showLocalNotification(message);
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'ecraftz_leads_channel',
    'New Lead Alerts',
    description: 'Notifications for new leads added to Ecraftz CRM',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> initialize() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _initLocalNotifications();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message: ${message.notification?.title}');
      showLocalNotification(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] App opened from notification: ${message.notification?.title}');
    });
  }

  static Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  static Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ecraftz_leads_channel',
      'New Lead Alerts',
      channelDescription: 'Notifications for new leads added to Ecraftz CRM',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  static Future<bool> requestPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );
    final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
    return granted;
  }

  static Future<void> registerTokenForUser({
    required String userId,
    required String role,
  }) async {
    try {
      await requestPermission();
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('[FCM] No token obtained from Firebase.');
        return;
      }
      debugPrint('[FCM] Token obtained: ${token.substring(0, 20)}...');
      await SupabaseService.client.from('device_tokens').upsert({
        'user_id': userId,
        'fcm_token': token,
        'role': role,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,platform');
      debugPrint('[FCM] Token successfully saved to Supabase for $userId ($role)');

      _messaging.onTokenRefresh.listen((newToken) async {
        await SupabaseService.client.from('device_tokens').upsert({
          'user_id': userId,
          'fcm_token': newToken,
          'role': role,
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'user_id,platform');
        debugPrint('[FCM] Token refreshed in Supabase');
      });
    } catch (e) {
      debugPrint('[FCM] Error registering token: $e');
    }
  }

  static Future<void> unregisterToken({required String userId}) async {
    try {
      await _messaging.deleteToken();
      await SupabaseService.client
          .from('device_tokens')
          .delete()
          .eq('user_id', userId);
      debugPrint('[FCM] Token removed for $userId');
    } catch (e) {
      debugPrint('[FCM] Error removing token: $e');
    }
  }
}
