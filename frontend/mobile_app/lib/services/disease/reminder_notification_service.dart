import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// A locally persisted reminder record.
///
/// [isRead] controls the red badge shown on the DiseaseView notification bell.
class ReminderRecord {
  final int id;
  final String diseaseName;
  final DateTime followUpDate;
  final String? predictionId;
  final bool isRead;

  ReminderRecord({
    required this.id,
    required this.diseaseName,
    required this.followUpDate,
    this.predictionId,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'diseaseName': diseaseName,
    'followUpDate': followUpDate.toIso8601String(),
    'predictionId': predictionId,
    'isRead': isRead,
  };

  factory ReminderRecord.fromJson(Map<String, dynamic> json) {
    return ReminderRecord(
      id: json['id'] as int,
      diseaseName: json['diseaseName'] as String,
      followUpDate: DateTime.parse(json['followUpDate'] as String),
      predictionId: json['predictionId'] as String?,
      // Backward compatible with reminders saved before isRead existed.
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  ReminderRecord copyWith({
    int? id,
    String? diseaseName,
    DateTime? followUpDate,
    String? predictionId,
    bool? isRead,
  }) {
    return ReminderRecord(
      id: id ?? this.id,
      diseaseName: diseaseName ?? this.diseaseName,
      followUpDate: followUpDate ?? this.followUpDate,
      predictionId: predictionId ?? this.predictionId,
      isRead: isRead ?? this.isRead,
    );
  }
}

class ReminderNotificationService {
  ReminderNotificationService._();

  static final ReminderNotificationService instance =
      ReminderNotificationService._();

  static const String _prefsKey = 'scheduled_reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    // This application is intended for Sri Lanka users.
    // Keeping an explicit timezone prevents reminders from being scheduled as UTC.
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Colombo'));
    } catch (_) {
      // If the timezone database lookup ever fails, tz.local remains available.
    }

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

  /// Schedule a phone notification and save it to the in-app notification list.
  /// A newly created reminder is always unread, so the DiseaseView bell shows
  /// a red badge.
  Future<int> scheduleFollowUpReminder({
    required String diseaseName,
    required DateTime followUpDate,
    String? predictionId,
  }) async {
    await init();

    final int id = predictionId != null
        ? predictionId.hashCode & 0x7fffffff
        : DateTime.now().microsecondsSinceEpoch.remainder(2147483647);

    final scheduledDate = tz.TZDateTime.from(followUpDate, tz.local);

    if (!scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      throw ArgumentError('Follow-up reminder date must be in the future.');
    }

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
      'Treatment Follow-up Reminder 🍎',
      'Follow-up for $diseaseName — check if the treatment worked.',
      scheduledDate,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    await _saveRecord(
      ReminderRecord(
        id: id,
        diseaseName: diseaseName,
        followUpDate: followUpDate,
        predictionId: predictionId,
        isRead: false,
      ),
    );

    return id;
  }

  /// Delete both the scheduled phone notification and the locally stored item.
  Future<void> cancelReminder(int id) async {
    await init();
    await _plugin.cancel(id);
    await _removeRecord(id);
  }

  /// Returns every locally saved reminder.
  ///
  /// IMPORTANT: expired reminders are NOT automatically removed. This allows
  /// the notification popup to work like a small notification/history center.
  /// The user can delete a reminder manually using the trash icon.
  Future<List<ReminderRecord>> getAllReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? <String>[];

    final reminders = <ReminderRecord>[];

    for (final item in raw) {
      try {
        reminders.add(
          ReminderRecord.fromJson(jsonDecode(item) as Map<String, dynamic>),
        );
      } catch (_) {
        // Ignore an invalid/corrupted local item instead of crashing the UI.
      }
    }

    // Newest follow-up date first in the popup.
    reminders.sort((a, b) => b.followUpDate.compareTo(a.followUpDate));

    return reminders;
  }

  /// Number displayed in the red badge on the DiseaseView bell.
  Future<int> getUnreadCount() async {
    final reminders = await getAllReminders();
    return reminders.where((r) => !r.isRead).length;
  }

  /// Called when the user opens the DiseaseView notification popup.
  /// The reminders stay stored, but the red badge is cleared.
  Future<void> markAllAsRead() async {
    final reminders = await getAllReminders();

    if (reminders.isEmpty) return;

    final updated = reminders
        .map((r) => r.isRead ? r : r.copyWith(isRead: true))
        .toList();

    await _writeAll(updated);
  }

  /// Optional helper if you later want to mark only one item as read.
  Future<void> markAsRead(int id) async {
    final reminders = await getAllReminders();

    final updated = reminders
        .map((r) => r.id == id ? r.copyWith(isRead: true) : r)
        .toList();

    await _writeAll(updated);
  }

  Future<void> _saveRecord(ReminderRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? <String>[];

    final all = <ReminderRecord>[];

    for (final item in raw) {
      try {
        final reminder = ReminderRecord.fromJson(
          jsonDecode(item) as Map<String, dynamic>,
        );

        if (reminder.id != record.id) {
          all.add(reminder);
        }
      } catch (_) {
        // Skip invalid old records.
      }
    }

    all.add(record);
    await _writeAll(all);
  }

  Future<void> _removeRecord(int id) async {
    final reminders = await getAllReminders();
    final updated = reminders.where((r) => r.id != id).toList();
    await _writeAll(updated);
  }

  Future<void> _writeAll(List<ReminderRecord> records) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _prefsKey,
      records.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }
}
