import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class NotificationService {

  static final NotificationService _instance =
      NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {

    /// timezone setup
    tz_data.initializeTimeZones();
    final String timeZoneName =
        await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    /// Android 13 permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// 🔔 Schedule task reminder
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {

    try {

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),

        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Task Reminders',
            channelDescription: 'Notifications for task reminders',
            importance: Importance.high,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('notification_sound'),
          ),

          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),

        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,

        androidScheduleMode:
            AndroidScheduleMode.exactAllowWhileIdle,
      );

    } catch (e) {
      print("Schedule error: $e");
    }
  }

  /// 🔔 แจ้งเตือนว่าวันนี้มีงาน
  Future<void> notifyUpcomingTasksToday({
    required int taskCount,
  }) async {

    try {

      await _plugin.show(
        999,
        'Tasks Due Today',
        'You have $taskCount task${taskCount > 1 ? 's' : ''} due today!',

        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_channel',
            'Daily Task Reminder',
            channelDescription: 'Daily notification for tasks',
            importance: Importance.high,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('notification_sound'),
          ),

          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );

    } catch (e) {
      print("Notify error: $e");
    }
  }

  /// cancel notification
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// cancel all
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }
}