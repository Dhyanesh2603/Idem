import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../providers/task_providers.dart';

/// Deadline status alert summary
class DeadlineAlertSummary {
  final List<TaskModel> overdueTasks;
  final List<TaskModel> dueTodayTasks;
  final List<TaskModel> upcomingTasks;

  const DeadlineAlertSummary({
    required this.overdueTasks,
    required this.dueTodayTasks,
    required this.upcomingTasks,
  });

  bool get hasUrgentAlerts => overdueTasks.isNotEmpty || dueTodayTasks.isNotEmpty;
  int get totalUrgentCount => overdueTasks.length + dueTodayTasks.length;

  static const empty = DeadlineAlertSummary(
    overdueTasks: [],
    dueTodayTasks: [],
    upcomingTasks: [],
  );
}

/// Provider that monitors task deadlines and categorizes them into overdue, due today, and upcoming
final deadlineAlertsProvider = Provider<DeadlineAlertSummary>((ref) {
  final tasksAsync = ref.watch(filteredTasksStreamProvider);
  final allTasks = tasksAsync.asData?.value ?? [];

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  final next48Hours = now.add(const Duration(hours: 48));

  final incompleteTasks = allTasks.where((t) => !t.isCompleted && t.deadline != null).toList();

  final overdue = <TaskModel>[];
  final dueToday = <TaskModel>[];
  final upcoming = <TaskModel>[];

  for (final task in incompleteTasks) {
    final deadline = task.deadline!;
    if (deadline.isBefore(startOfDay)) {
      overdue.add(task);
    } else if (deadline.isBefore(endOfDay) || deadline.isAtSameMomentAs(endOfDay)) {
      dueToday.add(task);
    } else if (deadline.isBefore(next48Hours)) {
      upcoming.add(task);
    }
  }

  return DeadlineAlertSummary(
    overdueTasks: overdue,
    dueTodayTasks: dueToday,
    upcomingTasks: upcoming,
  );
});
