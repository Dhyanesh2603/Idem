import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../database/app_database.dart';
import '../models/task_model.dart';
import '../models/task_filter.dart';
import '../models/task_priority.dart';
import '../models/recurring_rule.dart';
import '../models/task_dependency_model.dart';
import '../../sync/models/sync_operation.dart';
import '../../sync/repository/sync_queue_repository.dart';
import 'task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  final AppDatabase _db;
  final SyncQueueRepository _syncQueue;
  final Uuid _uuid;

  TaskRepositoryImpl(
    this._db,
    this._syncQueue, [
    Uuid? uuid,
  ]) : _uuid = uuid ?? const Uuid();

  @override
  Stream<List<TaskModel>> watchTasks({TaskFilter filter = TaskFilter.empty}) {
    final query = _db.select(_db.tasks)
      ..where((tbl) => tbl.isDeleted.equals(false));

    if (filter.isCompleted != null) {
      query.where((tbl) => tbl.isCompleted.equals(filter.isCompleted!));
    }

    if (filter.priority != null) {
      query.where((tbl) => tbl.priority.equals(filter.priority!.name));
    }

    if (filter.categoryId != null) {
      query.where((tbl) => tbl.categoryId.equals(filter.categoryId!));
    }

    if (filter.isFocus != null) {
      query.where((tbl) => tbl.isFocus.equals(filter.isFocus!));
    }

    if (filter.isInbox == true) {
      query.where((tbl) => tbl.deadline.isNull() & tbl.isCompleted.equals(false));
    }

    if (filter.isScheduled == true) {
      query.where((tbl) => tbl.deadline.isNotNull());
    }

    if (filter.searchQuery.trim().isNotEmpty) {
      final term = '%${filter.searchQuery.trim().toLowerCase()}%';
      query.where((tbl) =>
          tbl.title.lower().like(term) | tbl.description.lower().like(term));
    }

    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.orderIndex, mode: OrderingMode.asc),
      (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
    ]);

    return query.watch().map((entries) => entries.map(TaskModel.fromEntry).toList());
  }

  @override
  Stream<List<TaskModel>> watchTodayTasks() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    final query = _db.select(_db.tasks)
      ..where((tbl) =>
          tbl.isDeleted.equals(false) &
          (tbl.isFocus.equals(true) |
              (tbl.deadline.isBiggerOrEqualValue(startOfDay) &
                  tbl.deadline.isSmallerOrEqualValue(endOfDay))))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.isCompleted, mode: OrderingMode.asc),
        (tbl) => OrderingTerm(expression: tbl.orderIndex, mode: OrderingMode.asc),
        (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map((entries) => entries.map(TaskModel.fromEntry).toList());
  }

  @override
  Stream<List<TaskModel>> watchInboxTasks() {
    final query = _db.select(_db.tasks)
      ..where((tbl) =>
          tbl.isDeleted.equals(false) &
          tbl.isCompleted.equals(false) &
          tbl.deadline.isNull() &
          tbl.isFocus.equals(false))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.orderIndex, mode: OrderingMode.asc),
        (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map((entries) => entries.map(TaskModel.fromEntry).toList());
  }

  @override
  Stream<List<TaskModel>> watchTasksForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    final query = _db.select(_db.tasks)
      ..where((tbl) =>
          tbl.isDeleted.equals(false) &
          tbl.deadline.isBiggerOrEqualValue(start) &
          tbl.deadline.isSmallerOrEqualValue(end))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.isCompleted, mode: OrderingMode.asc),
        (tbl) => OrderingTerm(expression: tbl.orderIndex, mode: OrderingMode.asc),
      ]);

    return query.watch().map((entries) => entries.map(TaskModel.fromEntry).toList());
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    final entry = await (_db.select(_db.tasks)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return entry != null ? TaskModel.fromEntry(entry) : null;
  }

  @override
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
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    // Query highest order index to place new task at the top/end smoothly
    final maxOrderEntry = await (_db.select(_db.tasks)
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.orderIndex, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
    final nextOrder = (maxOrderEntry?.orderIndex ?? 0.0) + 1.0;

    final entry = TasksCompanion.insert(
      id: id,
      title: title.trim(),
      description: Value(description.trim()),
      priority: Value(priority.name),
      deadline: Value(deadline),
      categoryId: Value(categoryId),
      orderIndex: Value(nextOrder),
      isFocus: Value(isFocus),
      recurringRule: Value(recurringRule.name),
      parentTaskId: Value(parentTaskId),
      estimatedMinutes: Value(estimatedMinutes),
      createdAt: now,
      updatedAt: now,
      syncStatus: const Value('pending'),
    );

    await _db.into(_db.tasks).insert(entry);

    final model = TaskModel(
      id: id,
      title: title.trim(),
      description: description.trim(),
      priority: priority,
      deadline: deadline,
      categoryId: categoryId,
      orderIndex: nextOrder,
      isFocus: isFocus,
      recurringRule: recurringRule,
      parentTaskId: parentTaskId,
      estimatedMinutes: estimatedMinutes,
      createdAt: now,
      updatedAt: now,
      syncStatus: 'pending',
    );

    // Enqueue operation persistently
    await _syncQueue.enqueue(
      entityType: 'task',
      entityId: id,
      operationType: SyncOperationType.create,
      payload: jsonEncode(model.toJson()),
    );

    return model;
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    final now = DateTime.now();
    final updated = task.copyWith(updatedAt: now, syncStatus: 'pending');

    await (_db.update(_db.tasks)..where((tbl) => tbl.id.equals(task.id))).write(
      TasksCompanion(
        title: Value(updated.title),
        description: Value(updated.description),
        isCompleted: Value(updated.isCompleted),
        completedAt: Value(updated.completedAt),
        priority: Value(updated.priority.name),
        deadline: Value(updated.deadline),
        categoryId: Value(updated.categoryId),
        orderIndex: Value(updated.orderIndex),
        isFocus: Value(updated.isFocus),
        recurringRule: Value(updated.recurringRule.name),
        parentTaskId: Value(updated.parentTaskId),
        estimatedMinutes: Value(updated.estimatedMinutes),
        timeSpentMinutes: Value(updated.timeSpentMinutes),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );

    await _syncQueue.enqueue(
      entityType: 'task',
      entityId: task.id,
      operationType: SyncOperationType.update,
      payload: jsonEncode(updated.toJson()),
    );

    return updated;
  }

  @override
  Future<TaskModel> toggleTaskCompletion(String id) async {
    final existing = await getTaskById(id);
    if (existing == null) throw Exception('Task not found: $id');

    final now = DateTime.now();
    final willBeCompleted = !existing.isCompleted;

    final updated = existing.copyWith(
      isCompleted: willBeCompleted,
      completedAt: willBeCompleted ? now : null,
      clearCompletedAt: !willBeCompleted,
      updatedAt: now,
      syncStatus: 'pending',
    );

    await (_db.update(_db.tasks)..where((tbl) => tbl.id.equals(id))).write(
      TasksCompanion(
        isCompleted: Value(willBeCompleted),
        completedAt: Value(willBeCompleted ? now : null),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );

    await _syncQueue.enqueue(
      entityType: 'task',
      entityId: id,
      operationType: SyncOperationType.complete,
      payload: jsonEncode({
        'id': id,
        'is_completed': willBeCompleted,
        'completed_at': willBeCompleted ? now.toIso8601String() : null,
      }),
    );

    // Recurring task handling: if completed and has a recurrence rule, spawn next occurrence
    if (willBeCompleted && existing.recurringRule != RecurringRule.none) {
      final baseDate = existing.deadline ?? now;
      final nextDeadline = existing.recurringRule.computeNextDeadline(baseDate);

      await createTask(
        title: existing.title,
        description: existing.description,
        priority: existing.priority,
        deadline: nextDeadline,
        categoryId: existing.categoryId,
        isFocus: false,
        recurringRule: existing.recurringRule,
        estimatedMinutes: existing.estimatedMinutes,
      );
    }

    return updated;
  }

  @override
  Future<TaskModel> toggleFocus(String id) async {
    final existing = await getTaskById(id);
    if (existing == null) throw Exception('Task not found: $id');

    final updated = existing.copyWith(
      isFocus: !existing.isFocus,
      updatedAt: DateTime.now(),
      syncStatus: 'pending',
    );

    await (_db.update(_db.tasks)..where((tbl) => tbl.id.equals(id))).write(
      TasksCompanion(
        isFocus: Value(updated.isFocus),
        updatedAt: Value(updated.updatedAt),
        syncStatus: const Value('pending'),
      ),
    );

    await _syncQueue.enqueue(
      entityType: 'task',
      entityId: id,
      operationType: SyncOperationType.update,
      payload: jsonEncode(updated.toJson()),
    );

    return updated;
  }

  @override
  Future<void> deleteTask(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.tasks)..where((tbl) => tbl.id.equals(id))).write(
      TasksCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );

    await _syncQueue.enqueue(
      entityType: 'task',
      entityId: id,
      operationType: SyncOperationType.delete,
      payload: jsonEncode({'id': id, 'is_deleted': true, 'updated_at': now.toIso8601String()}),
    );
  }

  @override
  Future<void> reorderTasks(List<String> orderedTaskIds) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      for (int i = 0; i < orderedTaskIds.length; i++) {
        final taskId = orderedTaskIds[i];
        final order = i.toDouble();
        await (_db.update(_db.tasks)..where((tbl) => tbl.id.equals(taskId))).write(
          TasksCompanion(
            orderIndex: Value(order),
            updatedAt: Value(now),
          ),
        );
      }
    });

    await _syncQueue.enqueue(
      entityType: 'task',
      entityId: 'reorder_batch',
      operationType: SyncOperationType.reorder,
      payload: jsonEncode({
        'ordered_ids': orderedTaskIds,
        'timestamp': now.toIso8601String(),
      }),
    );
  }

  @override
  Future<TaskModel> snoozeTask(String id, DateTime targetDate) async {
    final existing = await getTaskById(id);
    if (existing == null) throw Exception('Task not found: $id');

    final now = DateTime.now();
    final updated = existing.copyWith(
      deadline: targetDate,
      updatedAt: now,
      syncStatus: 'pending',
    );

    await (_db.update(_db.tasks)..where((tbl) => tbl.id.equals(id))).write(
      TasksCompanion(
        deadline: Value(targetDate),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );

    await _syncQueue.enqueue(
      entityType: 'task',
      entityId: id,
      operationType: SyncOperationType.update,
      payload: jsonEncode(updated.toJson()),
    );

    return updated;
  }

  // --- Task Dependencies ---

  @override
  Future<void> addDependency({
    required String blockerTaskId,
    required String blockedTaskId,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    await _db.into(_db.taskDependencies).insert(
          TaskDependenciesCompanion.insert(
            id: id,
            blockerTaskId: blockerTaskId,
            blockedTaskId: blockedTaskId,
            createdAt: now,
          ),
        );

    await _syncQueue.enqueue(
      entityType: 'dependency',
      entityId: id,
      operationType: SyncOperationType.create,
      payload: jsonEncode({
        'id': id,
        'blocker_task_id': blockerTaskId,
        'blocked_task_id': blockedTaskId,
        'created_at': now.toIso8601String(),
      }),
    );
  }

  @override
  Future<void> removeDependency(String dependencyId) async {
    await (_db.update(_db.taskDependencies)..where((tbl) => tbl.id.equals(dependencyId))).write(
      const TaskDependenciesCompanion(isDeleted: Value(true)),
    );

    await _syncQueue.enqueue(
      entityType: 'dependency',
      entityId: dependencyId,
      operationType: SyncOperationType.delete,
      payload: jsonEncode({'id': dependencyId, 'is_deleted': true}),
    );
  }

  @override
  Stream<List<TaskDependencyModel>> watchDependenciesForTask(String taskId) {
    final query = _db.select(_db.taskDependencies)
      ..where((tbl) =>
          tbl.isDeleted.equals(false) &
          (tbl.blockedTaskId.equals(taskId) | tbl.blockerTaskId.equals(taskId)));

    return query.watch().map((rows) => rows.map(TaskDependencyModel.fromEntry).toList());
  }

  @override
  Future<List<TaskModel>> getUnfinishedBlockers(String taskId) async {
    // 1. Get all active dependencies where blockedTaskId == taskId
    final deps = await (_db.select(_db.taskDependencies)
          ..where((tbl) => tbl.blockedTaskId.equals(taskId) & tbl.isDeleted.equals(false)))
        .get();

    if (deps.isEmpty) return [];

    final blockerIds = deps.map((d) => d.blockerTaskId).toList();

    // 2. Query unfinished tasks with these blocker IDs
    final blockers = await (_db.select(_db.tasks)
          ..where((tbl) =>
              tbl.id.isIn(blockerIds) &
              tbl.isCompleted.equals(false) &
              tbl.isDeleted.equals(false)))
        .get();

    return blockers.map(TaskModel.fromEntry).toList();
  }

  @override
  Future<List<TaskModel>> getTasksBlockedBy(String taskId) async {
    final deps = await (_db.select(_db.taskDependencies)
          ..where((tbl) => tbl.blockerTaskId.equals(taskId) & tbl.isDeleted.equals(false)))
        .get();

    if (deps.isEmpty) return [];

    final blockedIds = deps.map((d) => d.blockedTaskId).toList();

    final blockedTasks = await (_db.select(_db.tasks)
          ..where((tbl) => tbl.id.isIn(blockedIds) & tbl.isDeleted.equals(false)))
        .get();

    return blockedTasks.map(TaskModel.fromEntry).toList();
  }
}
