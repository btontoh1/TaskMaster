import 'package:flutter/material.dart';

enum Priority { low, medium, high }

extension PriorityX on Priority {
  String get label => switch (this) {
        Priority.low => 'Low',
        Priority.medium => 'Medium',
        Priority.high => 'High',
      };

  Color get color => switch (this) {
        Priority.low => Colors.green,
        Priority.medium => Colors.orange,
        Priority.high => Colors.red,
      };
}

extension DueDateLabel on DateTime {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get shortLabel => '${_months[month - 1]} $day';
  String get longLabel => '${_months[month - 1]} $day, $year';
}

extension TimeOfDayLabel on TimeOfDay {
  String get label {
    final hour12 = hourOfPeriod == 0 ? 12 : hourOfPeriod;
    final minuteStr = minute.toString().padLeft(2, '0');
    final period = this.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minuteStr $period';
  }
}

class Todo {
  Todo({
    required this.title,
    this.notes = '',
    this.done = false,
    this.dueDate,
    this.dueTime,
    this.priority = Priority.medium,
    this.category = '',
  });

  String title;
  String notes;
  bool done;
  DateTime? dueDate;
  TimeOfDay? dueTime;
  Priority priority;
  String category;

  String get dueLabel {
    if (dueDate == null) return '';
    if (dueTime == null) return dueDate!.shortLabel;
    return '${dueDate!.shortLabel}, ${dueTime!.label}';
  }

  String get dueLongLabel {
    if (dueDate == null) return '';
    if (dueTime == null) return dueDate!.longLabel;
    return '${dueDate!.longLabel} at ${dueTime!.label}';
  }

  bool get isOverdue {
    if (dueDate == null || done) return false;
    final now = DateTime.now();
    if (dueTime != null) {
      final due = DateTime(
        dueDate!.year,
        dueDate!.month,
        dueDate!.day,
        dueTime!.hour,
        dueTime!.minute,
      );
      return due.isBefore(now);
    }
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.isBefore(today);
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'notes': notes,
        'done': done,
        'dueDate': dueDate?.toIso8601String(),
        'dueTimeMinutes':
            dueTime == null ? null : dueTime!.hour * 60 + dueTime!.minute,
        'priority': priority.name,
        'category': category,
      };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        title: json['title'] as String,
        notes: json['notes'] as String? ?? '',
        done: json['done'] as bool? ?? false,
        dueDate: json['dueDate'] == null
            ? null
            : DateTime.parse(json['dueDate'] as String),
        dueTime: json['dueTimeMinutes'] == null
            ? null
            : TimeOfDay(
                hour: (json['dueTimeMinutes'] as int) ~/ 60,
                minute: (json['dueTimeMinutes'] as int) % 60,
              ),
        priority: Priority.values.byName(
          json['priority'] as String? ?? Priority.medium.name,
        ),
        category: json['category'] as String? ?? '',
      );
}
