import '../models/task_model.dart';
import '../models/task_filter.dart';
import '../models/task_priority.dart';
import '../models/recurring_rule.dart';
import '../models/task_dependency_model.dart';

/// Clean repository interface for all task operations.
/// Completely abstracts the persistence and synchronization layer from the UI.
abstract class TaskRepository {
  /// Watches all non-deleted tasks matching an optional filter
  Stream<List<TaskModel>> watchTasks({TaskFilter filter = TaskFilter.empty});

  /// Watches tasks scheduled for Today or flagged as Today's Focus
  Stream<List<TaskModel>> watchTodayTasks();

  /// Watches inbox tasks (unscheduled, not completed, not deleted)
  Stream<List<TaskModel>> watchInboxTasks();

  /// Watches tasks for a specific calendar date
  Stream<List<TaskModel>> watchTasksForDate(DateTime date);

  /// Retrieves a single task by ID
  Future<TaskModel?> getTaskById(String id);

  /// Creates a new task, immediately writes to SQLite, and enqueues CREATE sync op
  Future<TaskModel> createTask({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.none,
    DateTime? deadline,
    String? categoryId,
    bool isFocus = false,
    RecurringRule recurringRule = RecurringRule.none,
    String? parentTaskId,
    int estimatedMinutes = 0,
  });

  /// Updates an existing task and enqueues UPDATE sync op
  Future<TaskModel> updateTask(TaskModel task);

  /// Toggles completion status. If recurring, generates next cycle task.
  Future<TaskModel> toggleTaskCompletion(String id);

  /// Toggles isFocus state for Today's Focus Mode
  Future<TaskModel> toggleFocus(String id);

  /// Soft deletes a task and enqueues DELETE sync op
  Future<void> deleteTask(String id);

  /// Updates task order positions (for Drag & Drop reordering)
  Future<void> reorderTasks(List<String> orderedTaskIds);

  /// Snoozes/reschedules a task to a target date
  Future<TaskModel> snoozeTask(String id, DateTime targetDate);

  // --- Task Dependencies ---
  /// Adds a dependency constraint: [blockedTaskId] cannot start until [blockerTaskId] completes
  Future<void> addDependency({
    required String blockerTaskId,
    required String blockedTaskId,
  });

  /// Removes an existing dependency
  Future<void> removeDependency(String dependencyId);

  /// Retrieves dependencies for a task
  Stream<List<TaskDependencyModel>> watchDependenciesForTask(String taskId);

  /// Checks if a task is currently blocked by any unfinished prerequisite tasks
  Future<List<TaskModel>> getUnfinishedBlockers(String taskId);

  /// Checks if any tasks depend on this task
  Future<List<TaskModel>> getTasksBlockedBy(String taskId);
}
