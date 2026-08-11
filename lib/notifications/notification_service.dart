import 'package:dealer_app/notifications/device_token_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (kDebugMode) {
    debugPrint('Background FCM message received: ${message.messageId}');
  }
}

class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    DeviceTokenService? deviceTokenService,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin(),
       _deviceTokenService = deviceTokenService ?? DeviceTokenService();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final DeviceTokenService _deviceTokenService;

  static const AndroidNotificationChannel _notificationChannel =
      AndroidNotificationChannel(
        'price_updates',
        'Price Updates',
        description: 'Notifications about fuel price updates.',
        importance: Importance.high,
      );

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initializeLocalNotifications();
    await _requestPermission();

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

  Future<void> registerCurrentToken() async {
    final token = await _messaging.getToken();

    if (kDebugMode) {
      debugPrint('FCM token available: ${token != null}');
    }

    if (token == null) {
      return;
    }

    try {
      await _deviceTokenService.registerToken(token);

      if (kDebugMode) {
        debugPrint('FCM token registered successfully');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('FCM token registration failed: $e');
        debugPrintStack(stackTrace: st);
      }
    }
  }

  void _listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) async {
      if (kDebugMode) {
        debugPrint('FCM token refreshed');
      }

      try {
        await _deviceTokenService.registerToken(token);

        if (kDebugMode) {
          debugPrint('Refreshed FCM token registered successfully');
        }
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('Refreshed FCM token registration failed: $e');
          debugPrintStack(stackTrace: st);
        }
      }
    });
  }

  Future<void> removeCurrentToken() async {
    final token = await _messaging.getToken();

    if (token == null) {
      return;
    }

    try {
      final removed = await _deviceTokenService.removeToken(token);

      if (kDebugMode) {
        debugPrint('FCM token removal result: $removed');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('FCM token removal failed: $e');
        debugPrintStack(stackTrace: st);
      }
    }
  }

  void _listenForForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (kDebugMode) {
        debugPrint('Foreground FCM message received: ${message.messageId}');
        debugPrint('FCM data: ${message.data}');
        debugPrint('FCM notification: ${message.notification}');
      }

      final notification = message.notification;

      if (notification == null) {
        return;
      }

      await _showLocalNotification(notification);
    });
  }

  Future<void> _showLocalNotification(RemoteNotification notification) async {
    final androidNotification = notification.android;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title ?? 'PGL Dealer App',
      body: notification.body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _notificationChannel.id,
          _notificationChannel.name,
          channelDescription: _notificationChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: androidNotification?.smallIcon ?? '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(settings: settings);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_notificationChannel);
  }
}
