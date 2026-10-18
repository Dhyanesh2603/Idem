import 'task_priority.dart';

/// Filter state criteria for querying tasks.
class TaskFilter {
  final String searchQuery;
  final TaskPriority? priority;
  final String? categoryId;
  final bool? isCompleted;
  final bool? isFocus;
  final bool? isScheduled;
  final bool? isInbox;
  final DateTime? date;

  const TaskFilter({
    this.searchQuery = '',
    this.priority,
    this.categoryId,
    this.isCompleted,
    this.isFocus,
    this.isScheduled,
    this.isInbox,
    this.date,
  });

  TaskFilter copyWith({
    String? searchQuery,
    TaskPriority? priority,
    String? categoryId,
    bool? isCompleted,
    bool? isFocus,
    bool? isScheduled,
    bool? isInbox,
    DateTime? date,
  }) {
    return TaskFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      isCompleted: isCompleted ?? this.isCompleted,
      isFocus: isFocus ?? this.isFocus,
      isScheduled: isScheduled ?? this.isScheduled,
      isInbox: isInbox ?? this.isInbox,
      date: date ?? this.date,
    );
  }

  static const TaskFilter empty = TaskFilter();
}
