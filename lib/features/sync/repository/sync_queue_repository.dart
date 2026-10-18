import '../models/sync_operation.dart';
import '../../../database/app_database.dart';

/// Repository contract for persistent sync operation queue.
abstract class SyncQueueRepository {
  /// Enqueues a new sync mutation into local persistent storage.
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required SyncOperationType operationType,
    required String payload,
  });

  /// Retrieves eligible operations ready to sync (attempts < maxAttempts, nextRetryAt <= now)
  Future<List<SyncOperation>> getPendingOperations({int limit = 50});

  /// Marks operation as in flight
  Future<void> markInFlight(String id);

  /// Marks operation as successfully synced and removes from pending
  Future<void> markCompleted(String id);

  /// Records failed attempt and calculates exponential backoff retry time
  Future<void> markFailed(String id, String errorMessage, {Duration? retryDelay});

  /// Records a completed sync session in history
  Future<void> recordHistory({
    required bool success,
    required int changesCount,
    String? errorMessage,
  });

  /// Watches count of pending operations in queue
  Stream<int> watchPendingCount();

  /// Watches recent sync history entries
  Stream<List<SyncHistoryEntry>> watchHistory({int limit = 20});

  /// Clears completed entries older than retention window
  Future<void> purgeCompleted();
}
