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

class Todo {
  Todo({
    required this.title,
    this.notes = '',
    this.done = false,
    this.dueDate,
    this.priority = Priority.medium,
    this.category = '',
  });

  String title;
  String notes;
  bool done;
  DateTime? dueDate;
  Priority priority;
  String category;

  bool get isOverdue {
    if (dueDate == null || done) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.isBefore(today);
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'notes': notes,
        'done': done,
        'dueDate': dueDate?.toIso8601String(),
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
        priority: Priority.values.byName(
          json['priority'] as String? ?? Priority.medium.name,
        ),
        category: json['category'] as String? ?? '',
      );
}
