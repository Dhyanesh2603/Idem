import '../../../database/app_database.dart';
import 'task_priority.dart';
import 'recurring_rule.dart';

/// Pure domain representation of a Task.
/// Completely decoupled from SQL and Drift entities.
class TaskModel {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime? completedAt;
  final TaskPriority priority;
  final DateTime? deadline;
  final String? categoryId;
  final double orderIndex;
  final bool isFocus;
  final RecurringRule recurringRule;
  final String? parentTaskId;
  final int estimatedMinutes;
  final int timeSpentMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int serverVersion;
  final bool isDeleted;
  final String syncStatus;

  const TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.completedAt,
    this.priority = TaskPriority.none,
    this.deadline,
    this.categoryId,
    this.orderIndex = 0.0,
    this.isFocus = false,
    this.recurringRule = RecurringRule.none,
    this.parentTaskId,
    this.estimatedMinutes = 0,
    this.timeSpentMinutes = 0,
    required this.createdAt,
    required this.updatedAt,
    this.serverVersion = 1,
    this.isDeleted = false,
    this.syncStatus = 'pending',
  });

  /// True if task has an overdue deadline and is not completed
  bool get isOverdue {
    if (isCompleted || deadline == null) return false;
    return deadline!.isBefore(DateTime.now());
  }

  /// True if scheduled for today
  bool get isScheduledToday {
    if (deadline == null) return false;
    final now = DateTime.now();
    return deadline!.year == now.year &&
        deadline!.month == now.month &&
        deadline!.day == now.day;
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    TaskPriority? priority,
    DateTime? deadline,
    bool clearDeadline = false,
    String? categoryId,
    bool clearCategoryId = false,
    double? orderIndex,
    bool? isFocus,
    RecurringRule? recurringRule,
    String? parentTaskId,
    int? estimatedMinutes,
    int? timeSpentMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? serverVersion,
    bool? isDeleted,
    String? syncStatus,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      priority: priority ?? this.priority,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      orderIndex: orderIndex ?? this.orderIndex,
      isFocus: isFocus ?? this.isFocus,
      recurringRule: recurringRule ?? this.recurringRule,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverVersion: serverVersion ?? this.serverVersion,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  /// Maps Drift TaskEntry to TaskModel domain entity
  factory TaskModel.fromEntry(TaskEntry entry) {
    return TaskModel(
      id: entry.id,
      title: entry.title,
      description: entry.description,
      isCompleted: entry.isCompleted,
      completedAt: entry.completedAt,
      priority: TaskPriority.fromString(entry.priority),
      deadline: entry.deadline,
      categoryId: entry.categoryId,
      orderIndex: entry.orderIndex,
      isFocus: entry.isFocus,
      recurringRule: RecurringRule.fromString(entry.recurringRule),
      parentTaskId: entry.parentTaskId,
      estimatedMinutes: entry.estimatedMinutes,
      timeSpentMinutes: entry.timeSpentMinutes,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      serverVersion: entry.serverVersion,
      isDeleted: entry.isDeleted,
      syncStatus: entry.syncStatus,
    );
  }

  /// Serializes to JSON Map for Sync Queue and API operations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'priority': priority.name,
      'deadline': deadline?.toIso8601String(),
      'category_id': categoryId,
      'order_index': orderIndex,
      'is_focus': isFocus,
      'recurring_rule': recurringRule.name,
      'parent_task_id': parentTaskId,
      'estimated_minutes': estimatedMinutes,
      'time_spent_minutes': timeSpentMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'server_version': serverVersion,
      'is_deleted': isDeleted,
      'sync_status': syncStatus,
    };
  }

  /// Deserializes from JSON Map
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      priority: TaskPriority.fromString(json['priority'] as String?),
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String)
          : null,
      categoryId: json['category_id'] as String?,
      orderIndex: (json['order_index'] as num?)?.toDouble() ?? 0.0,
      isFocus: json['is_focus'] as bool? ?? false,
      recurringRule: RecurringRule.fromString(json['recurring_rule'] as String?),
      parentTaskId: json['parent_task_id'] as String?,
      estimatedMinutes: json['estimated_minutes'] as int? ?? 0,
      timeSpentMinutes: json['time_spent_minutes'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      serverVersion: json['server_version'] as int? ?? 1,
      isDeleted: json['is_deleted'] as bool? ?? false,
      syncStatus: json['sync_status'] as String? ?? 'synced',
    );
  }
}
