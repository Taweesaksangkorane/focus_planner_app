import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum Priority {
  low,
  medium,
  high,
  none;

  String get label {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.none:
        return 'None';
    }
  }

  Color get color {
    switch (this) {
      case Priority.low:
        return const Color(0xFF4CAF50);
      case Priority.medium:
        return const Color(0xFFFFB74D);
      case Priority.high:
        return const Color(0xFFEF5350);
      case Priority.none:
        return const Color(0xFF90A4AE);
    }
  }

  static Priority fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return Priority.low;
      case 'medium':
        return Priority.medium;
      case 'high':
        return Priority.high;
      default:
        return Priority.none;
    }
  }
}

// ✅ Reminder Model
class ReminderModel {
  final String id;
  final TimeOfDay time;
  final bool isEnabled;

  ReminderModel({
    required this.id,
    required this.time,
    this.isEnabled = true,
  });

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'isEnabled': isEnabled,
    };
  }

  // Convert from Map
  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] ?? '',
      time: TimeOfDay(
        hour: map['hour'] ?? 9,
        minute: map['minute'] ?? 0,
      ),
      isEnabled: map['isEnabled'] ?? true,
    );
  }

  ReminderModel copyWith({
    String? id,
    TimeOfDay? time,
    bool? isEnabled,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  String toString() => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime? dueDate;
  final Priority priority;
  final bool isCompleted;
  final DateTime? completedAt;
  final int? focusTimeSpent;
  final List<ReminderModel> reminders;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.dueDate,
    this.priority = Priority.none,
    this.isCompleted = false,
    this.completedAt,
    this.focusTimeSpent,
    this.reminders = const [],
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? dueDate,
    Priority? priority,
    bool? isCompleted,
    DateTime? completedAt,
    int? focusTimeSpent,
    List<ReminderModel>? reminders,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      focusTimeSpent: focusTimeSpent ?? this.focusTimeSpent,
      reminders: reminders ?? this.reminders,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ✅ Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'priority': priority.label,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'focusTimeSpent': focusTimeSpent,
      'reminders': reminders.map((r) => r.toMap()).toList(),
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ✅ Convert from Firestore
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // ✅ Parse reminders
    List<ReminderModel> reminders = [];
    if (data['reminders'] != null) {
      reminders = List<ReminderModel>.from(
        (data['reminders'] as List).map(
          (r) => ReminderModel.fromMap(r as Map<String, dynamic>),
        ),
      );
    }

    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Work',
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      priority: Priority.fromString(data['priority']),
      isCompleted: data['isCompleted'] ?? false,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      focusTimeSpent: data['focusTimeSpent'],
      reminders: reminders,
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // ✅ ตรวจสอบว่าถึง Due Date แล้วหรือไม่
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  // ✅ ตรวจสอบว่า Due วันนี้หรือไม่
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  // ✅ ตรวจสอบว่า Due พรุ่งนี้หรือไม่
  bool get isDueTomorrow {
    if (dueDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dueDate!.year == tomorrow.year &&
        dueDate!.month == tomorrow.month &&
        dueDate!.day == tomorrow.day;
  }

  // ✅ ตรวจสอบว่าใกล้ Due Date หรือไม่ (7 วัน)
  bool get isUrgent {
    if (dueDate == null || isCompleted) return false;
    final difference = dueDate!.difference(DateTime.now()).inDays;
    return difference >= 0 && difference <= 7;
  }

  // ✅ ได้ทุกสิ่งที่เหลือจน Due Date
  Duration get timeUntilDue {
    if (dueDate == null) return Duration.zero;
    return dueDate!.difference(DateTime.now());
  }

  // ✅ Format time until due
  String get formattedTimeUntilDue {
    if (dueDate == null) return 'No due date';
    if (isCompleted) return 'Completed';
    
    final duration = timeUntilDue;
    if (duration.isNegative) return 'Overdue';
    
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} left';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} left';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''} left';
    }
  }

  // ✅ Add Reminder
  TaskModel addReminder(ReminderModel reminder) {
    final updatedReminders = [...reminders, reminder];
    return copyWith(reminders: updatedReminders);
  }

  // ✅ Remove Reminder
  TaskModel removeReminder(String reminderId) {
    final updatedReminders = reminders
        .where((reminder) => reminder.id != reminderId)
        .toList();
    return copyWith(reminders: updatedReminders);
  }

  // ✅ Update Reminder
  TaskModel updateReminder(ReminderModel reminder) {
    final updatedReminders = reminders.map((r) {
      return r.id == reminder.id ? reminder : r;
    }).toList();
    return copyWith(reminders: updatedReminders);
  }

  // ✅ Toggle Reminder
  TaskModel toggleReminder(String reminderId) {
    final updatedReminders = reminders.map((r) {
      if (r.id == reminderId) {
        return r.copyWith(isEnabled: !r.isEnabled);
      }
      return r;
    }).toList();
    return copyWith(reminders: updatedReminders);
  }

  // ✅ Get enabled reminders
  List<ReminderModel> get enabledReminders {
    return reminders.where((r) => r.isEnabled).toList();
  }

  // ✅ Has reminders
  bool get hasReminders => reminders.isNotEmpty;

  // ✅ Get progress percentage (focus time)
  double get progressPercentage {
    if (focusTimeSpent == null) return 0.0;
    // Assuming 25 minutes (Pomodoro) is 100%
    return (focusTimeSpent! / 25).clamp(0.0, 1.0);
  }

  // ✅ Get status text
  String get statusText {
    if (isCompleted) return 'Completed ✓';
    if (isOverdue) return 'Overdue ⚠️';
    if (isDueToday) return 'Due Today 📌';
    if (isDueTomorrow) return 'Due Tomorrow 📅';
    if (isUrgent) return 'Urgent 🔥';
    return 'Pending';
  }

  // ✅ Validate task
  bool get isValid {
    return title.isNotEmpty && 
           description.isNotEmpty && 
           category.isNotEmpty;
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, priority: ${priority.label}, '
        'isCompleted: $isCompleted, reminders: ${reminders.length})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          priority == other.priority;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ priority.hashCode;
}