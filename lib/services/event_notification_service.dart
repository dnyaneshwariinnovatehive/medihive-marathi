import '../providers/notification_provider.dart';
import 'local_notification_service.dart';

class EventNotificationService {
  static Future<void> notifyOpdRegistered({
    required String patientName,
    required String type,
  }) async {
    final title = 'New OPD Registration';
    final body = '$patientName registered for $type';

    await NotificationProvider.addNotificationSilently(title, body);

    await LocalNotificationService().showNotification(
      id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
      title: title,
      body: body,
    );
  }

  static Future<void> notifyAppointmentReminder({
    required String patientName,
    required String time,
  }) async {
    final title = 'Appointment Reminder';
    final body = 'You have an appointment with $patientName at $time';

    await NotificationProvider.addNotificationSilently(title, body);

    await LocalNotificationService().showNotification(
      id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
      title: title,
      body: body,
    );
  }

  static Future<void> notifyBackupComplete({
    required bool success,
    String? details,
  }) async {
    final title = success ? 'Backup Complete' : 'Backup Failed';
    final body = details ?? (success ? 'Data synced successfully' : 'Backup encountered an error');

    await NotificationProvider.addNotificationSilently(title, body);

    await LocalNotificationService().showNotification(
      id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
      title: title,
      body: body,
    );
  }

  static Future<void> notifySyncComplete({
    required int recordCount,
  }) async {
    final title = 'Sync Complete';
    final body = '$recordCount records synchronized';

    await NotificationProvider.addNotificationSilently(title, body);
  }

  static Future<void> notifyPatientUpdate({
    required String patientName,
    required String action,
  }) async {
    final title = 'Patient $action';
    final body = '$patientName was $action';

    await NotificationProvider.addNotificationSilently(title, body);
  }
}
