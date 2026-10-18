import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../database/app_database.dart';
import '../models/sync_operation.dart';
import 'sync_queue_repository.dart';

class SyncQueueRepositoryImpl implements SyncQueueRepository {
  final AppDatabase _db;
  final Uuid _uuid;

  SyncQueueRepositoryImpl(this._db, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  @override
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required SyncOperationType operationType,
    required String payload,
  }) async {
    final entry = SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: entityType,
      entityId: entityId,
      operationType: operationType.value,
      payload: payload,
      createdAt: DateTime.now(),
      status: const Value('pending'),
      attempts: const Value(0),
    );

    await _db.into(_db.syncQueue).insert(entry);
  }

  @override
  Future<List<SyncOperation>> getPendingOperations({int limit = 50}) async {
    final now = DateTime.now();
    final query = _db.select(_db.syncQueue)
      ..where((tbl) =>
          tbl.status.isIn(['pending', 'failed']) &
          tbl.attempts.isSmallerThan(tbl.maxAttempts) &
          (tbl.nextRetryAt.isNull() | tbl.nextRetryAt.isSmallerOrEqualValue(now)))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc)])
      ..limit(limit);

    final entries = await query.get();
    return entries.map(SyncOperation.fromEntry).toList();
  }

  @override
  Future<void> markInFlight(String id) async {
    await (_db.update(_db.syncQueue)..where((tbl) => tbl.id.equals(id))).write(
      const SyncQueueCompanion(
        status: Value('in_flight'),
      ),
    );
  }

  @override
  Future<void> markCompleted(String id) async {
    await (_db.update(_db.syncQueue)..where((tbl) => tbl.id.equals(id))).write(
      const SyncQueueCompanion(
        status: Value('completed'),
      ),
    );
  }

  @override
  Future<void> markFailed(
    String id,
    String errorMessage, {
    Duration? retryDelay,
  }) async {
    final current = await (_db.select(_db.syncQueue)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (current == null) return;

    final newAttempts = current.attempts + 1;
    // Calculate exponential backoff: 1s, 2s, 4s, 8s, 16s
    final delaySeconds = retryDelay != null
        ? retryDelay.inSeconds
        : (1 << (newAttempts.clamp(0, 5)));
    final nextRetry = DateTime.now().add(Duration(seconds: delaySeconds));

    final isDead = newAttempts >= current.maxAttempts;

    await (_db.update(_db.syncQueue)..where((tbl) => tbl.id.equals(id))).write(
      SyncQueueCompanion(
        attempts: Value(newAttempts),
        status: Value(isDead ? 'failed' : 'pending'),
        nextRetryAt: Value(isDead ? null : nextRetry),
        lastError: Value(errorMessage),
      ),
    );
  }

  @override
  Future<void> recordHistory({
    required bool success,
    required int changesCount,
    String? errorMessage,
  }) async {
    await _db.into(_db.syncHistory).insert(
          SyncHistoryCompanion.insert(
            id: _uuid.v4(),
            timestamp: DateTime.now(),
            status: success ? 'success' : 'failure',
            changesCount: Value(changesCount),
            errorMessage: Value(errorMessage),
          ),
        );
  }

  @override
  Stream<int> watchPendingCount() {
    final countExp = _db.syncQueue.id.count();
    final query = _db.selectOnly(_db.syncQueue)
      ..addColumns([countExp])
      ..where(_db.syncQueue.status.isIn(['pending', 'failed', 'in_flight']));

    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  @override
  Stream<List<SyncHistoryEntry>> watchHistory({int limit = 20}) {
    final query = _db.select(_db.syncHistory)
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.timestamp, mode: OrderingMode.desc)])
      ..limit(limit);

    return query.watch();
  }

  @override
  Future<void> purgeCompleted() async {
    await (_db.delete(_db.syncQueue)..where((tbl) => tbl.status.equals('completed'))).go();
  }
}
