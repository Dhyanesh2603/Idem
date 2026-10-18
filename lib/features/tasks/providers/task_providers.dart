import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../models/task_filter.dart';
import '../models/task_dependency_model.dart';
import '../../../database/database_provider.dart';

/// Notifier for active task filter criteria
class TaskFilterNotifier extends Notifier<TaskFilter> {
  @override
  TaskFilter build() => TaskFilter.empty;

  void setFilter(TaskFilter filter) {
    state = filter;
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void reset() {
    state = TaskFilter.empty;
  }
}

/// Active task filter state provider
final taskFilterProvider = NotifierProvider<TaskFilterNotifier, TaskFilter>(
  TaskFilterNotifier.new,
);

/// Stream provider for all tasks matching the active filter
final filteredTasksStreamProvider = StreamProvider<List<TaskModel>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final filter = ref.watch(taskFilterProvider);
  return repository.watchTasks(filter: filter);
});

/// Stream provider for Today's tasks (scheduled for today or flagged focus)
final todayTasksStreamProvider = StreamProvider<List<TaskModel>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTodayTasks();
});

/// Stream provider for Inbox tasks (unscheduled, raw capture)
final inboxTasksStreamProvider = StreamProvider<List<TaskModel>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchInboxTasks();
});

/// Stream provider for tasks on a specific calendar date
final tasksForDateStreamProvider =
    StreamProvider.family<List<TaskModel>, DateTime>((ref, date) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTasksForDate(date);
});

/// Stream provider for dependencies of a task
final taskDependenciesStreamProvider =
    StreamProvider.family<List<TaskDependencyModel>, String>((ref, taskId) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchDependenciesForTask(taskId);
});

/// Future provider checking if task has any unfinished blockers
final taskUnfinishedBlockersProvider =
    FutureProvider.family<List<TaskModel>, String>((ref, taskId) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getUnfinishedBlockers(taskId);
});
