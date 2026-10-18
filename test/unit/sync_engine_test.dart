import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian_slate/core/network/api_client.dart';
import 'package:obsidian_slate/core/network/api_exceptions.dart';
import 'package:obsidian_slate/core/services/connectivity_service.dart';
import 'package:obsidian_slate/database/app_database.dart';
import 'package:obsidian_slate/database/connection/in_memory_connection.dart';
import 'package:obsidian_slate/features/sync/models/sync_operation.dart';
import 'package:obsidian_slate/features/sync/repository/sync_queue_repository_impl.dart';
import 'package:obsidian_slate/features/sync/services/sync_engine.dart';

class MockConnectivityService extends ConnectivityService {
  bool mockOnline = true;
  @override
  bool get isOnline => mockOnline;

  @override
  Future<bool> checkOnline() async => mockOnline;
}

class FakeApiClient extends ApiClient {
  final List<Map<String, dynamic>> pushedOperations = [];
  bool simulateConflict = false;
  Map<String, dynamic>? conflictServerData;

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    String? idempotencyKey,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (path == '/sync/push') {
      if (simulateConflict) {
        throw ConflictException(
          message: 'Server conflict',
          serverData: conflictServerData,
        );
      }
      pushedOperations.add(data as Map<String, dynamic>);
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {'success': true} as T,
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {'tasks': [], 'categories': []} as T,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SyncQueueRepositoryImpl queue;
  late MockConnectivityService mockConnectivity;
  late FakeApiClient fakeApi;
  late SyncEngine syncEngine;

  setUp(() {
    db = AppDatabase.forTesting(constructInMemoryDatabase());
    queue = SyncQueueRepositoryImpl(db);
    mockConnectivity = MockConnectivityService();
    fakeApi = FakeApiClient();
    syncEngine = SyncEngine(
      db: db,
      queue: queue,
      connectivity: mockConnectivity,
      api: fakeApi,
    );
  });

  tearDown(() async {
    syncEngine.dispose();
    await db.close();
  });

  group('SyncEngine Workflow Tests', () {
    test('synchronize pushes queued operations and marks them completed', () async {
      await queue.enqueue(
        entityType: 'task',
        entityId: 'task-abc',
        operationType: SyncOperationType.create,
        payload: '{"id": "task-abc", "title": "Buy groceries"}',
      );

      final initialOps = await queue.getPendingOperations();
      expect(initialOps.length, 1);

      await syncEngine.synchronize();

      expect(fakeApi.pushedOperations.length, 1);
      expect(fakeApi.pushedOperations.first['entity_id'], 'task-abc');

      // Operation should be marked completed
      final remaining = await queue.getPendingOperations();
      expect(remaining.isEmpty, isTrue);

      expect(syncEngine.state.status, SyncStatusState.idle);
      expect(syncEngine.state.lastSuccessfulSync, isNotNull);
    });

    test('synchronize sets offline status when network is unavailable', () async {
      mockConnectivity.mockOnline = false;

      await syncEngine.synchronize();

      expect(syncEngine.state.status, SyncStatusState.offline);
      expect(fakeApi.pushedOperations.isEmpty, isTrue);
    });

    test('Last-Write-Wins overwrites local data when server is newer', () async {
      final now = DateTime.now();
      // Insert local task with older timestamp
      final localCreatedAt = now.subtract(const Duration(hours: 2));
      final localUpdatedAt = now.subtract(const Duration(hours: 2));

      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: 'task-conflict-1',
              title: 'Old Local Title',
              createdAt: localCreatedAt,
              updatedAt: localUpdatedAt,
            ),
          );

      await queue.enqueue(
        entityType: 'task',
        entityId: 'task-conflict-1',
        operationType: SyncOperationType.update,
        payload: '{"id": "task-conflict-1", "title": "Old Local Title"}',
      );

      // Server has newer record
      fakeApi.simulateConflict = true;
      fakeApi.conflictServerData = {
        'id': 'task-conflict-1',
        'title': 'New Server Authoritative Title',
        'description': 'Updated from web client',
        'is_completed': false,
        'priority': 'urgent',
        'created_at': localCreatedAt.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'server_version': 2,
        'is_deleted': false,
      };

      await syncEngine.synchronize();

      // Check that local record was updated with server's authoritative version
      final updatedLocal = await (db.select(db.tasks)
            ..where((t) => t.id.equals('task-conflict-1')))
          .getSingle();

      expect(updatedLocal.title, 'New Server Authoritative Title');
      expect(updatedLocal.serverVersion, 2);
    });
  });
}
