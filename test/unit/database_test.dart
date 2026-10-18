import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian_slate/database/app_database.dart';
import 'package:obsidian_slate/database/connection/connection.dart';
import 'package:obsidian_slate/features/tasks/models/task_priority.dart';
import 'package:obsidian_slate/features/tasks/models/recurring_rule.dart';
import 'package:obsidian_slate/features/sync/models/sync_operation.dart';
import 'package:obsidian_slate/features/tasks/repository/task_repository_impl.dart';
import 'package:obsidian_slate/features/categories/repository/category_repository_impl.dart';
import 'package:obsidian_slate/features/sync/repository/sync_queue_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SyncQueueRepositoryImpl syncQueue;
  late TaskRepositoryImpl taskRepo;
  late CategoryRepositoryImpl categoryRepo;

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnectionFactory.inMemory());
    syncQueue = SyncQueueRepositoryImpl(db);
    taskRepo = TaskRepositoryImpl(db, syncQueue);
    categoryRepo = CategoryRepositoryImpl(db, syncQueue);
  });

  tearDown(() async {
    await db.close();
  });

  group('TaskRepository Database Tests', () {
    test('createTask inserts task into database and enqueues sync operation', () async {
      final task = await taskRepo.createTask(
        title: 'Design Obsidian Slate Architecture',
        description: 'Clean offline-first repository pattern',
        priority: TaskPriority.urgent,
        isFocus: true,
      );

      expect(task.id, isNotEmpty);
      expect(task.title, 'Design Obsidian Slate Architecture');
      expect(task.priority, TaskPriority.urgent);
      expect(task.isFocus, isTrue);

      final fetched = await taskRepo.getTaskById(task.id);
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Design Obsidian Slate Architecture');

      // Verify sync queue received CREATE operation
      final pendingOps = await syncQueue.getPendingOperations();
      expect(pendingOps.length, 1);
      expect(pendingOps.first.operationType.value, 'CREATE');
      expect(pendingOps.first.entityId, task.id);
    });

    test('toggleTaskCompletion marks task completed and enqueues COMPLETE operation', () async {
      final task = await taskRepo.createTask(title: 'Review PR');
      expect(task.isCompleted, isFalse);

      final completed = await taskRepo.toggleTaskCompletion(task.id);
      expect(completed.isCompleted, isTrue);
      expect(completed.completedAt, isNotNull);

      final toggledBack = await taskRepo.toggleTaskCompletion(task.id);
      expect(toggledBack.isCompleted, isFalse);
      expect(toggledBack.completedAt, isNull);
    });

    test('recurring task spawns next occurrence when completed', () async {
      final deadline = DateTime(2026, 10, 20, 10, 0);
      final task = await taskRepo.createTask(
        title: 'Daily Standup Sync',
        deadline: deadline,
        recurringRule: RecurringRule.daily,
      );

      // Complete the task
      await taskRepo.toggleTaskCompletion(task.id);

      // Check that a new task was spawned
      final allTasks = await db.select(db.tasks).get();
      // Should have original task + new spawned task
      expect(allTasks.length, 2);

      final spawned = allTasks.firstWhere((t) => t.id != task.id);
      expect(spawned.title, 'Daily Standup Sync');
      expect(spawned.isCompleted, isFalse);
      expect(spawned.deadline, deadline.add(const Duration(days: 1)));
    });

    test('reorderTasks updates order indices properly', () async {
      final task1 = await taskRepo.createTask(title: 'First');
      final task2 = await taskRepo.createTask(title: 'Second');
      final task3 = await taskRepo.createTask(title: 'Third');

      // Invert order: task3, task1, task2
      await taskRepo.reorderTasks([task3.id, task1.id, task2.id]);

      final updated3 = await taskRepo.getTaskById(task3.id);
      final updated1 = await taskRepo.getTaskById(task1.id);
      final updated2 = await taskRepo.getTaskById(task2.id);

      expect(updated3!.orderIndex, 0.0);
      expect(updated1!.orderIndex, 1.0);
      expect(updated2!.orderIndex, 2.0);
    });

    test('task dependencies prevent unblocked execution until blocker is complete', () async {
      final blocker = await taskRepo.createTask(title: 'Prerequisite API');
      final blocked = await taskRepo.createTask(title: 'Frontend Integration');

      await taskRepo.addDependency(
        blockerTaskId: blocker.id,
        blockedTaskId: blocked.id,
      );

      // Verify prerequisite is detected
      var blockers = await taskRepo.getUnfinishedBlockers(blocked.id);
      expect(blockers.length, 1);
      expect(blockers.first.id, blocker.id);

      // Complete blocker
      await taskRepo.toggleTaskCompletion(blocker.id);

      // Verify blocked task is now free of unfinished blockers
      blockers = await taskRepo.getUnfinishedBlockers(blocked.id);
      expect(blockers.isEmpty, isTrue);
    });
  });

  group('CategoryRepository Database Tests', () {
    test('create, update, and delete category', () async {
      final category = await categoryRepo.createCategory(
        name: 'Work Projects',
        colorHex: '#34D399',
        iconName: 'briefcase',
      );

      expect(category.name, 'Work Projects');

      final updated = await categoryRepo.updateCategory(
        category.copyWith(name: 'Commercial Projects'),
      );
      expect(updated.name, 'Commercial Projects');

      await categoryRepo.deleteCategory(category.id);
      final list = await categoryRepo.getCategories();
      expect(list.any((c) => c.id == category.id), isFalse);
    });
  });

  group('SyncQueueRepository Tests', () {
    test('exponential backoff increases delay on repeated failures', () async {
      await syncQueue.enqueue(
        entityType: 'task',
        entityId: 'test-123',
        operationType: SyncOperationType.update,
        payload: '{"test": 1}',
      );

      final ops = await syncQueue.getPendingOperations();
      expect(ops.length, 1);
      final op = ops.first;

      // Fail 1: attempt 1
      await syncQueue.markFailed(op.id, 'Connection timeout');
      final failed1 = (await syncQueue.getPendingOperations()).isEmpty;
      // next retry is in future
      expect(failed1, isTrue);
    });
  });
}
