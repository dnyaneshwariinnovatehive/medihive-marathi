import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'local_notification_service.dart';
import 'api_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  FirebaseMessaging? _messaging;
  String? _fcmToken;
  bool _initialized = false;

  String? get fcmToken => _fcmToken;

  Future<void> init() async {
    if (_initialized) return;

    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;

    await _requestPermission();
    await _getToken();
    _listenToTokenRefresh();
    _setupForegroundHandler();
    _setupBackgroundHandler();
    _setupTerminatedHandler();

    _initialized = true;
  }

  Future<void> _requestPermission() async {
    final messaging = _messaging;
    if (messaging == null) return;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _getToken() async {
    final messaging = _messaging;
    if (messaging == null) return;

    try {
      _fcmToken = await messaging.getToken();
      if (_fcmToken != null) {
        await ApiService.updateFcmToken(_fcmToken!);
      }
    } catch (_) {}
  }

  void _listenToTokenRefresh() {
    _messaging?.onTokenRefresh.listen((token) {
      _fcmToken = token;
      ApiService.updateFcmToken(token);
    });
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen(_handleMessage);
  }

  void _setupBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
  }

  void _setupTerminatedHandler() {
    FirebaseMessaging.instance.getInitialMessage().then(_handleTerminatedMessage);
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await LocalNotificationService().showNotification(
      id: message.hashCode,
      title: notification.title ?? '',
      body: notification.body ?? '',
      payload: message.data['route'],
    );
  }

  Future<void> _handleTerminatedMessage(RemoteMessage? message) async {
    if (message == null) return;
    final notification = message.notification;
    if (notification == null) return;

    await LocalNotificationService().showNotification(
      id: message.hashCode,
      title: notification.title ?? '',
      body: notification.body ?? '',
      payload: message.data['route'],
    );
  }
}

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final notification = message.notification;
  if (notification == null) return;

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  const androidDetails = AndroidNotificationDetails(
    'push_notifications',
    'Push Notifications',
    channelDescription: 'Push notifications from server',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );
  const iosDetails = DarwinNotificationDetails();
  const details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    notification.title ?? '',
    notification.body ?? '',
    details,
    payload: message.data['route'],
  );
}
