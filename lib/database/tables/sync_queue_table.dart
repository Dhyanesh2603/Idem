import 'package:drift/drift.dart';

/// Table schema for the Persistent Sync Operation Queue.
///
/// Every mutation (create, update, delete, complete, reorder) is written
/// atomically to this queue before returning to UI. This guarantees zero
/// data loss across crashes and restarts.
@DataClassName('SyncQueueEntry')
class SyncQueue extends Table {
  /// Unique queue operation ID (UUID)
  TextColumn get id => text()();

  /// Target entity type: 'task', 'category', 'dependency'
  TextColumn get entityType => text()();

  /// ID of target entity
  TextColumn get entityId => text()();

  /// Operation: 'CREATE', 'UPDATE', 'DELETE', 'COMPLETE', 'REORDER'
  TextColumn get operationType => text()();

  /// Serialized JSON payload containing state snapshots or delta changes
  TextColumn get payload => text()();

  /// Number of retry attempts made
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Max retries allowed before holding for manual user triage
  IntColumn get maxAttempts => integer().withDefault(const Constant(5))();

  /// Next scheduled retry timestamp (exponential backoff)
  DateTimeColumn get nextRetryAt => dateTime().nullable()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime()();

  /// Status: 'pending', 'in_flight', 'failed', 'completed'
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Last error message encountered during synchronization
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
