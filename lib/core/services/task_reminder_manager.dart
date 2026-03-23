import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/notifications/data/notification_model.dart';
import '../../features/notifications/data/notification_repository.dart';
import 'notification_service.dart';

class TaskReminderManager {
  static final TaskReminderManager _instance = TaskReminderManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late NotificationRepository _repository;

  factory TaskReminderManager() {
    return _instance;
  }

  TaskReminderManager._internal();

  void initialize(NotificationRepository repository) {
    _repository = repository;
  }

  Future<void> checkOverdueTasks(String userId) async {
  try {
    final now = DateTime.now();

    final snapshot = await _firestore
        .collection('users/$userId/tasks')
        .where('isCompleted', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      final task = doc.data();

      if (task['dueDate'] == null) continue;

      final dueDate = (task['dueDate'] as Timestamp).toDate();

      // ✅ ถ้า overdue
      if (now.isAfter(dueDate)) {
        final alreadyNotified = task['hasOverdueNotified'] ?? false;

        if (!alreadyNotified) {
          await NotificationService().notifyTaskOverdue(
            taskTitle: task['title'] ?? 'Task',
            dueDate: dueDate,
          );

          await _firestore
              .collection('users/$userId/tasks')
              .doc(doc.id)
              .update({'hasOverdueNotified': true});
        }
      }
    }
  } catch (e) {
    print('Error checking overdue tasks: $e');
  }
}

   // ✅ ตรวจสอบและแจ้งเตือน Task ที่ใกล้จะครบกำหนด
  Future<void> checkAndNotifyUpcomingTasks(String userId) async {
    try {
      final now = DateTime.now();
      final in7Days = now.add(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('users/$userId/tasks')
          .where('isCompleted', isEqualTo: false)
          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(in7Days))
          .get();

      for (var doc in snapshot.docs) {
        final task = doc.data();
        final dueDate = (task['dueDate'] as Timestamp).toDate();
        final daysUntilDue = dueDate.difference(now).inDays;

        // ✅ แจ้งเตือนเมื่อเหลือ 5 วัน
        if (daysUntilDue == 5) {
          final has5DayNotified = task['has5DayNotified'] ?? false;
          if (!has5DayNotified) {
            await NotificationService().notifyTaskDue5Days(
              taskTitle: task['title'] ?? 'Task',
              taskDescription: task['description'] ?? '',
              dueDate: dueDate,
            );

            await _firestore
                .collection('users/$userId/tasks')
                .doc(doc.id)
                .update({'has5DayNotified': true});
          }
        }

        // ✅ แจ้งเตือนเมื่อเหลือ 3 วัน
        if (daysUntilDue == 3) {
          final has3DayNotified = task['has3DayNotified'] ?? false;
          if (!has3DayNotified) {
            await NotificationService().notifyTaskDue3Days(
              taskTitle: task['title'] ?? 'Task',
              taskDescription: task['description'] ?? '',
              dueDate: dueDate,
            );

            await _firestore
                .collection('users/$userId/tasks')
                .doc(doc.id)
                .update({'has3DayNotified': true});
          }
        }

        // ✅ แจ้งเตือนเมื่อเหลือ 1 วัน
        if (daysUntilDue == 1) {
          final has1DayNotified = task['has1DayNotified'] ?? false;
          if (!has1DayNotified) {
            await NotificationService().notifyTaskDue1Day(
              taskTitle: task['title'] ?? 'Task',
              taskDescription: task['description'] ?? '',
              dueDate: dueDate,
            );

            await _firestore
                .collection('users/$userId/tasks')
                .doc(doc.id)
                .update({'has1DayNotified': true});
          }
        }

        // ✅ แจ้งเตือน 10 นาทีก่อน reminder time
        if (task['reminderTime'] != null) {
          final reminderTime = (task['reminderTime'] as Timestamp).toDate();
          final timeUntilReminder = reminderTime.difference(now).inMinutes;

          if (timeUntilReminder <= 10 && timeUntilReminder > 0) {
            final has10MinNotified = task['has10MinNotified'] ?? false;
            if (!has10MinNotified) {
              await NotificationService().notifyReminder10MinBefore(
                taskTitle: task['title'] ?? 'Task',
                taskId: doc.id,
                reminderTime: reminderTime,
              );

              await _firestore
                  .collection('users/$userId/tasks')
                  .doc(doc.id)
                  .update({'has10MinNotified': true});
            }
          }
        }

        // ✅ แจ้งเตือนตามเวลา reminder ที่ตั้งไว้
        if (task['reminderTime'] != null) {
          final reminderTime = (task['reminderTime'] as Timestamp).toDate();
          final hasReminderSent = task['hasReminderSent'] ?? false;

          if (now.isAfter(reminderTime) &&
              now.isBefore(reminderTime.add(const Duration(minutes: 2))) &&
              !hasReminderSent) {
            
            await NotificationService().notifyScheduledReminder(
              taskTitle: task['title'] ?? 'Task',
              taskId: doc.id,
              scheduledTime: reminderTime,
            );

            await _firestore
                .collection('users/$userId/tasks')
                .doc(doc.id)
                .update({'hasReminderSent': true});
          }
        }
      }
    } catch (e) {
      print('Error checking task reminders: $e');
    }
  }

  // ✅ ยกเลิกการแจ้งเตือนเมื่อ Task เสร็จ
  Future<void> cancelTaskReminder(String userId, String taskId) async {
    try {
      await _firestore
          .collection('users/$userId/tasks')
          .doc(taskId)
          .update({
            'has5DayNotified': false,
            'has3DayNotified': false,
            'has1DayNotified': false,
            'has10MinNotified': false,
            'hasReminderSent': false,
          });
    } catch (e) {
      print('Error canceling task reminder: $e');
    }
  }

  // ✅ ตั้งค่าการแจ้งเตือนอีกครั้งเมื่อเปลี่ยน Due Date
  Future<void> resetTaskReminder(String userId, String taskId) async {
    try {
      await _firestore
          .collection('users/$userId/tasks')
          .doc(taskId)
          .update({
            'has5DayNotified': false,
            'has3DayNotified': false,
            'has1DayNotified': false,
            'has10MinNotified': false,
            'hasReminderSent': false,
          });
    } catch (e) {
      print('Error resetting task reminder: $e');
    }
  }

    // ✅ ตรวจสอบเวลาเริ่มโฟกัส (ตามเวลา reminder)
  Future<void> checkFocusTimeReminders(String userId) async {
    try {
      final now = DateTime.now();

      final snapshot = await _firestore
          .collection('users/$userId/tasks')
          .where('isCompleted', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        final task = doc.data();
        
        // ✅ ถ้ามี reminderTimes
        if (task['reminderTimes'] != null && task['reminderTimes'].isNotEmpty) {
          final reminderTimes = (task['reminderTimes'] as List)
              .map((e) => DateTime.parse(e as String))
              .toList();

          for (var reminderTime in reminderTimes) {
            final timeDifference = reminderTime.difference(now).inMinutes;

            // ✅ แจ้งเตือนเมื่อถึงเวลา reminder (ความคลาดเคลื่อน 1 นาที)
            if (timeDifference >= 0 && timeDifference <= 1) {
              final hasFocusNotified = 
                  task['hasFocusStartNotified_${reminderTime.toIso8601String()}'] ?? false;

              if (!hasFocusNotified) {
                await NotificationService().notifyFocusTimeStarted(
                  taskTitle: task['title'] ?? 'Task',
                  focusMinutes: task['focusTime'] ?? 25,
                );

                // ✅ ทำเครื่องหมายว่าแจ้งเตือนแล้ว
                await _firestore
                    .collection('users/$userId/tasks')
                    .doc(doc.id)
                    .update({
                      'hasFocusStartNotified_${reminderTime.toIso8601String()}': true,
                    });
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error checking focus time reminders: $e');
    }
  }

  // ✅ ตรวจสอบทั้งหมด
  Future<void> checkAllReminders(String userId) async {
    try {
      await checkAndNotifyUpcomingTasks(userId);
      await checkOverdueTasks(userId);
      await checkFocusTimeReminders(userId);  // ✅ เพิ่ม
    } catch (e) {
      print('Error checking all reminders: $e');
    }
  }


}