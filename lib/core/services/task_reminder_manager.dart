import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_planner_app/features/tasks/data/task_model.dart';
import 'notification_service.dart';

class TaskReminderManager {
  static final TaskReminderManager _instance =
      TaskReminderManager._internal();

  factory TaskReminderManager() {
    return _instance;
  }

  TaskReminderManager._internal();

  final NotificationService _notificationService = NotificationService();

  // ✅ 1️⃣ ตั้ง Reminder สำหรับแต่ละ Task
  Future<void> scheduleTaskReminder(TaskModel task) async {
    final dueDate = task.dueDate;
    if (dueDate == null) return;

    // ✅ Reminder 15 นาทีก่อน
    final reminderTime15 = dueDate.subtract(const Duration(minutes: 15));
    if (reminderTime15.isAfter(DateTime.now())) {
      await _notificationService.scheduleReminder(
        id: task.id.hashCode,
        title: '⏰ Reminder: ${task.title}',
        body: 'Due in 15 minutes',
        scheduledTime: reminderTime15,
      );
    }

    // ✅ Reminder 1 ชั่วโมงก่อน
    final reminderTime60 = dueDate.subtract(const Duration(hours: 1));
    if (reminderTime60.isAfter(DateTime.now())) {
      await _notificationService.scheduleReminder(
        id: task.id.hashCode + 1,
        title: '⏰ Reminder: ${task.title}',
        body: 'Due in 1 hour',
        scheduledTime: reminderTime60,
      );
    }

    // ✅ Reminder วันก่อนหน้า เวลา 9:00 AM
    final tomorrowReminder = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day - 1,
      9,
      0,
    );
    if (tomorrowReminder.isAfter(DateTime.now())) {
      await _notificationService.scheduleReminder(
        id: task.id.hashCode + 2,
        title: '📌 Tomorrow Task: ${task.title}',
        body: 'Don\'t forget this task tomorrow!',
        scheduledTime: tomorrowReminder,
      );
    }
  }

  // ✅ 2️⃣ แจ้งเตือนงานที่ใกล้กำหนดวันนี้
  Future<void> checkAndNotifyUpcomingTasks(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .where('dueDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('dueDate', isLessThan: Timestamp.fromDate(tomorrow))
          .where('status', isNotEqualTo: 'completed')
          .get();

      if (snapshot.docs.isNotEmpty) {
        await _notificationService.notifyUpcomingTasksToday(
          taskCount: snapshot.docs.length,
        );
      }
    } catch (e) {
      print('Error checking upcoming tasks: $e');
    }
  }

  // ✅ ยกเลิก Reminder
  Future<void> cancelTaskReminder(String taskId) async {
    await _notificationService.cancelNotification(taskId.hashCode);
    await _notificationService.cancelNotification(taskId.hashCode + 1);
    await _notificationService.cancelNotification(taskId.hashCode + 2);
  }
}