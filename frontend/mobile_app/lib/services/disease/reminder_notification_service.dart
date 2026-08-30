import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class ReminderNotificationService {
  ReminderNotificationService._();
  static final ReminderNotificationService instance =
      ReminderNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(tz.local.name));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    _initialized = true;
  }

  /// Schedules a follow-up reminder notification for [followUpDate].
  /// Returns the notification id used, so it can be cancelled later
  /// if the user changes/removes the reminder.
  Future<int> scheduleFollowUpReminder({
    required String diseaseName,
    required DateTime followUpDate,
    String? predictionId,
  }) async {
    await init();

    final id = predictionId != null
        ? predictionId.hashCode & 0x7fffffff
        : DateTime.now().millisecondsSinceEpoch.remainder(100000);

    final scheduledDate = tz.TZDateTime.from(followUpDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'followup_reminders',
      'Follow-up Reminders',
      channelDescription: 'Reminders to re-check treated pomegranate fruit',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      id,
      'Time to re-check your fruit 🍎',
      'Follow-up for $diseaseName — check if the treatment worked.',
      scheduledDate,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    return id;
  }

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }
}
