import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  Future<void> initialize() async {
    await _requestPermission();
    await _logToken();
    _listenForTokenRefresh();
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      debugPrint(
        'Notification permission: ${settings.authorizationStatus}',
      );
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
}