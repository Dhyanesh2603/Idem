import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';
import '../features/sync/repository/sync_queue_repository.dart';
import '../features/sync/repository/sync_queue_repository_impl.dart';
import '../features/tasks/repository/task_repository.dart';
import '../features/tasks/repository/task_repository_impl.dart';
import '../features/categories/repository/category_repository.dart';
import '../features/categories/repository/category_repository_impl.dart';

/// Database instance provider (Singleton lifecycle)
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Sync queue repository provider
final syncQueueRepositoryProvider = Provider<SyncQueueRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncQueueRepositoryImpl(db);
});

/// Task repository provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncQueue = ref.watch(syncQueueRepositoryProvider);
  return TaskRepositoryImpl(db, syncQueue);
});

/// Category repository provider
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncQueue = ref.watch(syncQueueRepositoryProvider);
  return CategoryRepositoryImpl(db, syncQueue);
});
