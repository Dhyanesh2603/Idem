import '../../../database/app_database.dart';

/// Supported synchronization operation types.
enum SyncOperationType {
  create('CREATE'),
  update('UPDATE'),
  delete('DELETE'),
  complete('COMPLETE'),
  reorder('REORDER');

  const SyncOperationType(this.value);
  final String value;

  static SyncOperationType fromString(String val) {
    return SyncOperationType.values.firstWhere(
      (op) => op.value == val.toUpperCase(),
      orElse: () => SyncOperationType.update,
    );
  }
}

/// Domain model for queued synchronization operations.
class SyncOperation {
  final String id;
  final String entityType;
  final String entityId;
  final SyncOperationType operationType;
  final String payload;
  final int attempts;
  final int maxAttempts;
  final DateTime? nextRetryAt;
  final DateTime createdAt;
  final String status;
  final String? lastError;

  const SyncOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payload,
    this.attempts = 0,
    this.maxAttempts = 5,
    this.nextRetryAt,
    required this.createdAt,
    this.status = 'pending',
    this.lastError,
  });

  factory SyncOperation.fromEntry(SyncQueueEntry entry) {
    return SyncOperation(
      id: entry.id,
      entityType: entry.entityType,
      entityId: entry.entityId,
      operationType: SyncOperationType.fromString(entry.operationType),
      payload: entry.payload,
      attempts: entry.attempts,
      maxAttempts: entry.maxAttempts,
      nextRetryAt: entry.nextRetryAt,
      createdAt: entry.createdAt,
      status: entry.status,
      lastError: entry.lastError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation_type': operationType.value,
      'payload': payload,
      'attempts': attempts,
      'max_attempts': maxAttempts,
      'next_retry_at': nextRetryAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'last_error': lastError,
    };
  }
}
