import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin sharedNotificationPlugin =
    FlutterLocalNotificationsPlugin();

bool _pluginInitialized = false;

Future<void> initializePluginOnce(
  InitializationSettings settings, {
  void Function(NotificationResponse)? onDidReceiveNotificationResponse,
  void Function(NotificationResponse)?
      onDidReceiveBackgroundNotificationResponse,
}) async {
  if (_pluginInitialized) return;
  await sharedNotificationPlugin.initialize(
    settings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    onDidReceiveBackgroundNotificationResponse:
        onDidReceiveBackgroundNotificationResponse,
  );
  _pluginInitialized = true;
  debugPrint('sharedNotificationPlugin initialized');
}
