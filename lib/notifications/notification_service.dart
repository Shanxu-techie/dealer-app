import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (kDebugMode) {
    debugPrint('Background FCM message received: ${message.messageId}');
  }
}

class NotificationService {
  NotificationService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await _logToken();
    _listenForTokenRefresh();
    _listenForForegroundMessages();
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      debugPrint('Notification permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> _logToken() async {
    final token = await _messaging.getToken();

    if (kDebugMode) {
      debugPrint('FCM token available: ${token != null}');
    }
  }

  void _listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) {
      if (kDebugMode) {
        debugPrint('FCM token refreshed');
      }
    });
  }

  void _listenForForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('Foreground FCM message received: ${message.messageId}');
        debugPrint('FCM data: ${message.data}');
        debugPrint('FCM notification: ${message.notification}');
      }
    });
  }
}
