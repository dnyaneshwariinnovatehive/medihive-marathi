import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'shared_notification_plugin.dart';

int _positiveId(String id) => id.hashCode & 0x7FFFFFFF;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await initializePluginOnce(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final android = sharedNotificationPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
    }

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint(
        'NotificationService: tapped notification id=${response.id} payload=${response.payload}');
  }

  Future<void> _requestExactAlarm() async {
    final android = sharedNotificationPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleAppointment({
    required String id,
    required String patientName,
    required DateTime appointmentTime,
  }) async {
    if (!_initialized) await init();

    final remindAt = appointmentTime.subtract(const Duration(minutes: 10));
    final now = DateTime.now();
    if (remindAt.isBefore(now)) {
      debugPrint('NotificationService: reminder time already past for $id');
      return;
    }

    await _requestExactAlarm();

    final diff = remindAt.difference(now);
    final tzNow = tz.TZDateTime.now(tz.UTC);
    final tzRemindAt = tzNow.add(diff);

    const androidDetails = AndroidNotificationDetails(
      'appointment_reminder',
      'Appointment Reminders',
      channelDescription: 'Reminders for upcoming appointments',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await sharedNotificationPlugin.zonedSchedule(
        _positiveId(id),
        'Upcoming Appointment',
        'You have an appointment with $patientName in 10 minutes.',
        tzRemindAt,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint(
          'NotificationService: scheduled for $id at ${appointmentTime.toIso8601String()}');
    } catch (e) {
      debugPrint(
          'NotificationService: exact schedule failed for $id: $e, falling back to inexact');
      await sharedNotificationPlugin.zonedSchedule(
        _positiveId(id),
        'Upcoming Appointment',
        'You have an appointment with $patientName in 10 minutes.',
        tzRemindAt,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelAppointment(String id) async {
    await sharedNotificationPlugin.cancel(_positiveId(id));
  }

  Future<void> cancelAll() async {
    await sharedNotificationPlugin.cancelAll();
  }
}
