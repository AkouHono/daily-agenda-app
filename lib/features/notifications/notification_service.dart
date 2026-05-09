import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../../models/task.dart';
import '../../core/preferences_store.dart';
import '../../core/reminder_store.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    const androidChannel = AndroidNotificationChannel(
      'task_reminders',
      'Task reminders',
      description: 'Scheduled nudges before tasks start',
      importance: Importance.high,
    );
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(androidChannel);
  }

  static int _notificationId(String taskId) => taskId.hashCode & 0x7fffffff;

  static Future<void> cancelForTask(String taskId) async {
    await _plugin.cancel(_notificationId(taskId));
  }

  /// Schedules one reminder before [task.startTime], respecting per-task and app defaults and DnD.
  static Future<void> syncTaskReminder(Task task, {required String categoryName}) async {
    await cancelForTask(task.id);
    if (task.isCompleted) return;

    final lead = ReminderStore.effectiveMinutes(task.id, PreferencesStore.defaultReminderMinutes);
    if (lead <= 0) return;

    final fireLocal = task.startTime.subtract(Duration(minutes: lead));
    if (!fireLocal.isAfter(DateTime.now())) return;
    if (PreferencesStore.isWithinQuietHours(fireLocal)) return;

    final scheduled = tz.TZDateTime.from(fireLocal, tz.local);
    final androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task reminders',
      channelDescription: 'Scheduled nudges before tasks start',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Upcoming task',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      _notificationId(task.id),
      'Starting soon: ${task.title}',
      '$categoryName · in $lead min',
      scheduled,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
