import '../../../database/app_database.dart';

/// Pure domain model for Task Dependency.
class TaskDependencyModel {
  final String id;
  final String blockerTaskId;
  final String blockedTaskId;
  final DateTime createdAt;
  final bool isDeleted;

  const TaskDependencyModel({
    required this.id,
    required this.blockerTaskId,
    required this.blockedTaskId,
    required this.createdAt,
    this.isDeleted = false,
  });

  factory TaskDependencyModel.fromEntry(TaskDependencyEntry entry) {
    return TaskDependencyModel(
      id: entry.id,
      blockerTaskId: entry.blockerTaskId,
      blockedTaskId: entry.blockedTaskId,
      createdAt: entry.createdAt,
      isDeleted: entry.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blocker_task_id': blockerTaskId,
      'blocked_task_id': blockedTaskId,
      'created_at': createdAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory TaskDependencyModel.fromJson(Map<String, dynamic> json) {
    return TaskDependencyModel(
      id: json['id'] as String,
      blockerTaskId: json['blocker_task_id'] as String,
      blockedTaskId: json['blocked_task_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }
}
