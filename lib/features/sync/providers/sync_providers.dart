import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/network/api_client.dart';
import '../../../database/database_provider.dart';
import '../services/sync_engine.dart';

/// Connectivity service singleton provider
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// API Client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Core SyncEngine provider
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final queue = ref.watch(syncQueueRepositoryProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final api = ref.watch(apiClientProvider);

  final engine = SyncEngine(
    db: db,
    queue: queue,
    connectivity: connectivity,
    api: api,
  );

  ref.onDispose(() => engine.dispose());
  return engine;
});

/// Stream of real-time online/offline reachability
final isOnlineStreamProvider = StreamProvider<bool>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  return connectivity.isOnlineStream;
});

/// Provider for current sync state
final syncStateProvider = Provider<SyncState>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return engine.state;
});
