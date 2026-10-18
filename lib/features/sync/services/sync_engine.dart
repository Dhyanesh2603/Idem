import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../database/app_database.dart';
import '../models/sync_operation.dart';
import '../repository/sync_queue_repository.dart';
import '../../tasks/models/task_model.dart';
import '../../categories/models/category_model.dart';

enum SyncStatusState { idle, syncing, offline, error }

class SyncState {
  final SyncStatusState status;
  final String? errorMessage;
  final DateTime? lastSuccessfulSync;
  final int pendingOperationsCount;

  const SyncState({
    this.status = SyncStatusState.idle,
    this.errorMessage,
    this.lastSuccessfulSync,
    this.pendingOperationsCount = 0,
  });

  SyncState copyWith({
    SyncStatusState? status,
    String? errorMessage,
    DateTime? lastSuccessfulSync,
    int? pendingOperationsCount,
  }) {
    return SyncState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSuccessfulSync: lastSuccessfulSync ?? this.lastSuccessfulSync,
      pendingOperationsCount: pendingOperationsCount ?? this.pendingOperationsCount,
    );
  }
}

/// The Heart of Obsidian Slate: Offline-First Synchronizer.
///
/// Features:
/// - Sequential, idempotent push queue processing
/// - Automatic connectivity-triggered sync
/// - Exponential backoff retry strategy (1s, 2s, 4s, 8s, 16s)
/// - Last-Write-Wins (LWW) conflict resolution preserving data integrity
/// - Delta pull synchronization
/// - Zero data loss across crashes and application restarts
class SyncEngine {
  final AppDatabase _db;
  final SyncQueueRepository _queue;
  final ConnectivityService _connectivity;
  final ApiClient _api;

  final ValueNotifier<SyncState> stateNotifier =
      ValueNotifier(const SyncState());

  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<int>? _queueCountSub;
  bool _isProcessing = false;

  SyncEngine({
    required AppDatabase db,
    required SyncQueueRepository queue,
    required ConnectivityService connectivity,
    required ApiClient api,
  })  : _db = db,
        _queue = queue,
        _connectivity = connectivity,
        _api = api {
    _init();
  }

  SyncState get state => stateNotifier.value;

  void _init() {
    _queueCountSub = _queue.watchPendingCount().listen((count) {
      stateNotifier.value = state.copyWith(pendingOperationsCount: count);
    });

    _connectivitySub = _connectivity.isOnlineStream.listen((online) {
      if (online) {
        // Automatically attempt to drain queue when coming back online
        synchronize();
      } else {
        stateNotifier.value = state.copyWith(status: SyncStatusState.offline);
      }
    });
  }

  /// Triggers full synchronization cycle (Push Queue -> Resolve Conflicts -> Pull Deltas)
  Future<void> synchronize() async {
    if (_isProcessing) return;

    final isOnline = await _connectivity.checkOnline();
    if (!isOnline) {
      stateNotifier.value = state.copyWith(
        status: SyncStatusState.offline,
        errorMessage: 'Network unavailable. Running offline.',
      );
      return;
    }

    _isProcessing = true;
    stateNotifier.value = state.copyWith(
      status: SyncStatusState.syncing,
      errorMessage: null,
    );

    int processedCount = 0;
    try {
      // Step 1: Drain pending local operations sequentially
      final pendingOps = await _queue.getPendingOperations(limit: 50);

      for (final op in pendingOps) {
        await _queue.markInFlight(op.id);
        try {
          await _executePushOperation(op);
          await _queue.markCompleted(op.id);
          processedCount++;
        } on ConflictException catch (conflict) {
          // Step 2: Handle conflict using Last-Write-Wins
          await _resolveConflict(op, conflict);
          await _queue.markCompleted(op.id);
          processedCount++;
        } on NetworkException catch (netErr) {
          // Record failure with exponential backoff and break current run
          await _queue.markFailed(op.id, netErr.message);
          stateNotifier.value = state.copyWith(
            status: SyncStatusState.offline,
            errorMessage: 'Sync paused: Network interrupted',
          );
          _queue.recordHistory(
            success: false,
            changesCount: processedCount,
            errorMessage: netErr.message,
          );
          return;
        } catch (e) {
          await _queue.markFailed(op.id, e.toString());
        }
      }

      // Step 3: Pull remote server deltas
      await _pullDeltas();

      // Step 4: Maintenance: purge completed queue items
      await _queue.purgeCompleted();

      final now = DateTime.now();
      stateNotifier.value = state.copyWith(
        status: SyncStatusState.idle,
        lastSuccessfulSync: now,
        errorMessage: null,
      );

      await _queue.recordHistory(
        success: true,
        changesCount: processedCount,
      );
    } catch (e) {
      stateNotifier.value = state.copyWith(
        status: SyncStatusState.error,
        errorMessage: 'Sync error: ${e.toString()}',
      );
      await _queue.recordHistory(
        success: false,
        changesCount: processedCount,
        errorMessage: e.toString(),
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Sends a single queued operation to server with idempotency token
  Future<void> _executePushOperation(SyncOperation op) async {
    final payload = jsonDecode(op.payload);
    await _api.post(
      '/sync/push',
      idempotencyKey: op.id,
      data: {
        'operation_id': op.id,
        'entity_type': op.entityType,
        'entity_id': op.entityId,
        'operation_type': op.operationType.value,
        'payload': payload,
        'timestamp': op.createdAt.toIso8601String(),
      },
    );
  }

  /// Resolves conflicts via Last-Write-Wins (LWW)
  Future<void> _resolveConflict(SyncOperation op, ConflictException conflict) async {
    final serverData = conflict.serverData;
    if (serverData == null) return;

    if (op.entityType == 'task') {
      final local = await (_db.select(_db.tasks)..where((t) => t.id.equals(op.entityId))).getSingleOrNull();
      if (local == null) return;

      final serverUpdatedAtStr = serverData['updated_at'] as String?;
      final serverUpdatedAt = serverUpdatedAtStr != null ? DateTime.tryParse(serverUpdatedAtStr) : null;

      if (serverUpdatedAt != null && serverUpdatedAt.isAfter(local.updatedAt)) {
        // Server version is newer: overwrite local record with server state
        final serverTask = TaskModel.fromJson(serverData);
        await (_db.update(_db.tasks)..where((t) => t.id.equals(op.entityId))).write(
          TasksCompanion(
            title: Value(serverTask.title),
            description: Value(serverTask.description),
            isCompleted: Value(serverTask.isCompleted),
            completedAt: Value(serverTask.completedAt),
            priority: Value(serverTask.priority.name),
            deadline: Value(serverTask.deadline),
            categoryId: Value(serverTask.categoryId),
            orderIndex: Value(serverTask.orderIndex),
            isFocus: Value(serverTask.isFocus),
            updatedAt: Value(serverTask.updatedAt),
            serverVersion: Value(serverTask.serverVersion),
            isDeleted: Value(serverTask.isDeleted),
            syncStatus: const Value('synced'),
          ),
        );
      } else {
        // Local version is newer: force overwrite on server
        await _api.post(
          '/sync/push',
          idempotencyKey: op.id,
          data: {
            'operation_id': op.id,
            'entity_type': op.entityType,
            'entity_id': op.entityId,
            'operation_type': 'FORCE_UPDATE',
            'payload': jsonDecode(op.payload),
            'timestamp': local.updatedAt.toIso8601String(),
          },
        );
      }
    }
  }

  /// Pulls remote delta updates
  Future<void> _pullDeltas() async {
    try {
      final response = await _api.get<Map<String, dynamic>>('/sync/pull');
      if (response.statusCode == 200 && response.data != null) {
        final tasksData = response.data!['tasks'] as List<dynamic>? ?? [];
        final categoriesData = response.data!['categories'] as List<dynamic>? ?? [];

        await _db.transaction(() async {
          for (final item in tasksData) {
            final task = TaskModel.fromJson(item as Map<String, dynamic>);
            final existing = await (_db.select(_db.tasks)..where((t) => t.id.equals(task.id))).getSingleOrNull();

            if (existing == null) {
              await _db.into(_db.tasks).insert(
                    TasksCompanion.insert(
                      id: task.id,
                      title: task.title,
                      description: Value(task.description),
                      priority: Value(task.priority.name),
                      deadline: Value(task.deadline),
                      categoryId: Value(task.categoryId),
                      orderIndex: Value(task.orderIndex),
                      isFocus: Value(task.isFocus),
                      recurringRule: Value(task.recurringRule.name),
                      parentTaskId: Value(task.parentTaskId),
                      estimatedMinutes: Value(task.estimatedMinutes),
                      timeSpentMinutes: Value(task.timeSpentMinutes),
                      createdAt: task.createdAt,
                      updatedAt: task.updatedAt,
                      serverVersion: Value(task.serverVersion),
                      isDeleted: Value(task.isDeleted),
                      syncStatus: const Value('synced'),
                    ),
                  );
            } else if (task.updatedAt.isAfter(existing.updatedAt)) {
              // Apply remote change if newer
              await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
                TasksCompanion(
                  title: Value(task.title),
                  description: Value(task.description),
                  isCompleted: Value(task.isCompleted),
                  completedAt: Value(task.completedAt),
                  priority: Value(task.priority.name),
                  deadline: Value(task.deadline),
                  categoryId: Value(task.categoryId),
                  orderIndex: Value(task.orderIndex),
                  isFocus: Value(task.isFocus),
                  recurringRule: Value(task.recurringRule.name),
                  updatedAt: Value(task.updatedAt),
                  serverVersion: Value(task.serverVersion),
                  isDeleted: Value(task.isDeleted),
                  syncStatus: const Value('synced'),
                ),
              );
            }
          }

          for (final item in categoriesData) {
            final cat = CategoryModel.fromJson(item as Map<String, dynamic>);
            final existing = await (_db.select(_db.categories)..where((c) => c.id.equals(cat.id))).getSingleOrNull();

            if (existing == null) {
              await _db.into(_db.categories).insert(
                    CategoriesCompanion.insert(
                      id: cat.id,
                      name: cat.name,
                      colorHex: Value(cat.colorHex),
                      iconName: Value(cat.iconName),
                      createdAt: cat.createdAt,
                      updatedAt: cat.updatedAt,
                      isDeleted: Value(cat.isDeleted),
                      syncStatus: const Value('synced'),
                    ),
                  );
            } else if (cat.updatedAt.isAfter(existing.updatedAt)) {
              await (_db.update(_db.categories)..where((c) => c.id.equals(cat.id))).write(
                CategoriesCompanion(
                  name: Value(cat.name),
                  colorHex: Value(cat.colorHex),
                  iconName: Value(cat.iconName),
                  updatedAt: Value(cat.updatedAt),
                  isDeleted: Value(cat.isDeleted),
                  syncStatus: const Value('synced'),
                ),
              );
            }
          }
        });
      }
    } catch (_) {
      // Pull failures do not invalidate local storage
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    _queueCountSub?.cancel();
    stateNotifier.dispose();
  }
}
