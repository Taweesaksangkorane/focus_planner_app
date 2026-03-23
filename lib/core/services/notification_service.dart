import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/notifications/data/notification_model.dart';
import '../../features/notifications/data/notification_repository.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  late NotificationRepository _repository;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  void initialize(NotificationRepository repository) {
    _repository = repository;
  }

  // ✅ Reminder Notification (10 นาทีก่อน)
  Future<void> notifyReminder10MinBefore({
    required String taskTitle,
    required String taskId,
    required DateTime reminderTime,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.taskReminderSet,
        title: '📌 Task Reminder - 10 Minutes Before',
        message: '"$taskTitle" will start in 10 minutes! Get ready! 🎯',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'taskId': taskId,
          'reminderTime': reminderTime.toIso8601String(),
        },
      );

      await _repository.addNotification(notification);
    } catch (e) {
      print('Error notifying reminder 10 min before: $e');
    }
  }

  // ✅ Scheduled Reminder (ตามเวลาที่ตั้ง)
  Future<void> notifyScheduledReminder({
    required String taskTitle,
    required String taskId,
    required DateTime scheduledTime,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final timeStr = '${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}';

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.taskReminderSet,
        title: '📌 Task Reminder - $timeStr',
        message: 'Time to start "$taskTitle"! Let\'s focus! 💪',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'taskId': taskId,
          'scheduledTime': scheduledTime.toIso8601String(),
        },
      );

      await _repository.addNotification(notification);
    } catch (e) {
      print('Error notifying scheduled reminder: $e');
    }
  }

  // ✅ Focus Complete
  Future<void> notifyFocusComplete({
    required String taskTitle,
    required int sessionCount,
    required int totalSessions,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.focusComplete,
        title: '✅ Focus Session Complete!',
        message: 'Session $sessionCount/$totalSessions completed. Great work! 💪',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'sessionCount': sessionCount,
          'totalSessions': totalSessions,
        },
      );

      await _repository.addNotification(notification);
    } catch (e) {
      print('Error notifying focus complete: $e');
    }
  }

  // ✅ Break Complete
  Future<void> notifyBreakComplete({
    required int breakMinutes,
    required int sessionCount,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.breakComplete,
        title: '☕ Break Time Over!',
        message: 'You had a $breakMinutes minute break. Ready for session ${sessionCount + 1}? 🚀',
        createdAt: DateTime.now(),
        data: {
          'breakMinutes': breakMinutes,
          'sessionCount': sessionCount,
        },
      );

      await _repository.addNotification(notification);
    } catch (e) {
      print('Error notifying break complete: $e');
    }
  }

  // ✅ Task Due Soon
  Future<void> notifyTaskDueSoon({
    required String taskTitle,
    required DateTime dueDate,
    required int hoursUntilDue,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.taskDueSoon,
        title: '⏰ Task Due Soon!',
        message: '$taskTitle is due in $hoursUntilDue hours. Start focusing now!',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'dueDate': dueDate.toIso8601String(),
          'hoursUntilDue': hoursUntilDue,
        },
      );

      await _repository.addNotification(notification);
    } catch (e) {
      print('Error notifying task due soon: $e');
    }
  }

  // ✅ Motivational
  Future<void> notifyMotivational({
    String? customMessage,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final messages = [
        'You\'re doing amazing! Keep up the great work! 💪',
        'Every session brings you closer to your goals! 🎯',
        'Focus is a superpower - use it wisely! ⚡',
        'You\'ve got this! Push through! 🔥',
        'Consistency is key to success! 🔑',
        'Your future self will thank you! 🙏',
        'Small steps lead to big achievements! 🚀',
        'You\'re building great habits! 🏆',
      ];

      final message = customMessage ?? messages[DateTime.now().millisecond % messages.length];

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.motivational,
        title: '💪 Stay Motivated!',
        message: message,
        createdAt: DateTime.now(),
      );

      await _repository.addNotification(notification);
    } catch (e) {
      print('Error notifying motivational: $e');
    }
  }

  // ✅ Achievement
  Future<void> notifyAchievement({
    required String achievementTitle,
    required String description,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.achievement,
        title: '🏆 Achievement Unlocked!',
        message: '$achievementTitle\n$description',
        createdAt: DateTime.now(),
        data: {
          'achievementTitle': achievementTitle,
        },
      );

      await _repository.addNotification(notification);
    } catch (e) {
      print('Error notifying achievement: $e');
    }
  }

  // ✅ Settings Changed
  Future<void> notifySettingChanged({
    required String settingName,
    required String oldValue,
    required String newValue,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.settingChanged,
        title: '⚙️ Settings Updated',
        message: '$settingName changed from $oldValue to $newValue',
        createdAt: DateTime.now(),
        data: {
          'settingName': settingName,
          'oldValue': oldValue,
          'newValue': newValue,
        },
      );

      await _repository.addNotification(notification);
    } catch (e) {
      print('Error notifying setting changed: $e');
    }
  }

  // ✅ Task Completed
  Future<void> notifyTaskCompleted({
    required String taskTitle,
    required int totalFocusTime,
    required int sessionsCompleted,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.achievement,
        title: '🎉 Task Completed!',
        message: 'You completed "$taskTitle" in $sessionsCompleted sessions ($totalFocusTime minutes of focus)!',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'totalFocusTime': totalFocusTime,
          'sessionsCompleted': sessionsCompleted,
        },
      );

      await _repository.addNotification(notification);
    } catch (e) {
      print('Error notifying task completed: $e');
    }
  }

  // ✅ High Priority Task
  Future<void> notifyHighPriorityTask({
    required String taskTitle,
    required DateTime dueDate,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.motivational,
        title: '🔴 High Priority Task!',
        message: '"$taskTitle" is a high priority task and will end soon! ⚡',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'dueDate': dueDate.toIso8601String(),
        },
      );

      await _repository.addNotification(notification);
    } catch (e) {
      print('Error notifying high priority task: $e');
    }
  }


  // ✅ Task Due in 5 Days
  Future<void> notifyTaskDue5Days({
    required String taskTitle,
    required String taskDescription,
    required DateTime dueDate,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.taskDue5Days,
        title: '📌 $taskTitle',
        message: '$taskDescription\nเหลือเวลาอีก 5 วัน ⏳',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'dueDate': dueDate.toIso8601String(),
          'daysUntilDue': 5,
        },
      );

      await _repository.addNotification(notification);
    } catch (e) {
      print('Error notifying task due 5 days: $e');
    }
  }

  // ✅ Task Due in 3 Days
  Future<void> notifyTaskDue3Days({
    required String taskTitle,
    required String taskDescription,
    required DateTime dueDate,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.taskDue3Days,
        title: '⚠️ $taskTitle',
        message: '$taskDescription\nเหลือเวลาอีก 3 วัน ⏳',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'dueDate': dueDate.toIso8601String(),
          'daysUntilDue': 3,
        },
      );

      await _repository.addNotification(notification);
    } catch (e) {
      print('Error notifying task due 3 days: $e');
    }
  }

  // ✅ Task Due in 1 Day
  Future<void> notifyTaskDue1Day({
    required String taskTitle,
    required String taskDescription,
    required DateTime dueDate,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: NotificationType.taskDue1Day,
        title: '🚨 $taskTitle',
        message: '$taskDescription\nเหลือเวลาอีก 1 วัน ⏰',
        createdAt: DateTime.now(),
        data: {
          'taskTitle': taskTitle,
          'dueDate': dueDate.toIso8601String(),
          'daysUntilDue': 1,
        },
      );

      await _repository.addNotification(notification);
    } catch (e) {
      print('Error notifying task due 1 day: $e');
    }
  }

    // ✅ Focus Time Started - แจ้งเตือนเมื่อถึงเวลาเริ่มโฟกัส
    Future<void> notifyFocusTimeStarted({
      required String taskTitle,
      required int focusMinutes,
    }) async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final notification = NotificationModel(
          id: const Uuid().v4(),
          userId: user.uid,
          type: NotificationType.taskReminderSet,
          title: '🎯 Time to Focus!',
          message: 'Ready to start? "$taskTitle" is waiting for your $focusMinutes minute focus session! 💪',
          createdAt: DateTime.now(),
          data: {
            'taskTitle': taskTitle,
            'focusMinutes': focusMinutes,
          },
        );

        await _repository.addNotification(notification);
      } catch (e) {
        print('Error notifying focus time started: $e');
      }
    }

    Future<void> notifyTaskOverdue({
    required String taskTitle,
    required DateTime dueDate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      type: NotificationType.taskDueSoon,
      title: '⚠️ Task Overdue',
      message: '$taskTitle is overdue!',
      createdAt: DateTime.now(),
    );

    await NotificationRepositoryImpl(userId: user.uid)
        .addNotification(notification);
  }
}