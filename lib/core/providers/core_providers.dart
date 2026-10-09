import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/seed_data.dart';
import '../network/dio_client.dart';
import '../network/mock_server_store.dart';
import '../network/network_info.dart';
import '../network/remote_cache_service.dart';
import '../session/session_store.dart';
import '../sync/offline_first_store.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_queue_item.dart';
import '../sync/sync_queue_store.dart';

// ---------------------------------------------------------------- network --
final networkInfoProvider = Provider<NetworkInfo>((ref) => NetworkInfo());

final sessionStoreProvider = Provider<SessionStore>((ref) => SessionStore());

final mockServerStoreProvider = Provider<MockServerStore>(
  (ref) => MockServerStore(seed: SeedData.build()),
);

/// Session is read through a live closure (not watched) so rotating it never
/// rebuilds Dio - the closure always sees the current token.
final dioProvider = Provider<Dio>((ref) {
  final session = ref.watch(sessionStoreProvider);
  return DioClient.create(
    tokenProvider: () => session.token,
    mockStore: ref.watch(mockServerStoreProvider),
  );
});

final remoteCacheServiceProvider = Provider<RemoteCacheService>(
  (ref) => RemoteCacheService(
    dio: ref.watch(dioProvider),
    network: ref.watch(networkInfoProvider),
  ),
);

// -------------------------------------------------------------- data tick --
/// Bumped on every local write and after every sync cycle. Screens watch this
/// to re-read Hive.
class DataVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    if (!ref.mounted) return;
    state = state + 1;
  }
}

final dataVersionProvider =
    NotifierProvider<DataVersionNotifier, int>(DataVersionNotifier.new);

// ------------------------------------------------------------------- sync --
final syncQueueStoreProvider = Provider<SyncQueueStore>(
  (ref) => SyncQueueStore(),
);

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    queue: ref.watch(syncQueueStoreProvider),
    dio: ref.watch(dioProvider),
    network: ref.watch(networkInfoProvider),
    onStateChanged: () => ref.read(dataVersionProvider.notifier).increment(),
  );
  ref.onDispose(() => engine.onStateChanged = null);
  return engine;
});

/// Builds the shared offline-write path for a feature's Hive box.
final offlineStoreFactoryProvider =
    Provider<
      OfflineFirstStore Function({
        required String boxName,
        required SyncResource resource,
      })
    >((ref) {
      final queue = ref.watch(syncQueueStoreProvider);
      final engine = ref.watch(syncEngineProvider);
      final bump = ref.read(dataVersionProvider.notifier);

      return ({required String boxName, required SyncResource resource}) {
        return OfflineFirstStore.forBox(
          boxName: boxName,
          queue: queue,
          engine: engine,
          resource: resource,
          onLocalWrite: bump.increment,
        );
      };
    });

// ----------------------------------------------------------- connectivity --
class ConnectivityNotifier extends Notifier<bool> {
  @override
  bool build() {
    final network = ref.read(networkInfoProvider);
    final engine = ref.read(syncEngineProvider);

    network.isConnected.then((online) {
      if (ref.mounted && state != online) state = online;
    });

    final sub = network.onConnectivityChanged.listen((results) async {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (ref.mounted) state = online;
      if (online) {
        await engine.flush();
        if (ref.mounted) {
          ref.read(dataVersionProvider.notifier).increment();
        }
      }
    });
    ref.onDispose(sub.cancel);

    return true;
  }
}

final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, bool>(ConnectivityNotifier.new);

class SyncStatusState {
  const SyncStatusState({
    required this.isOnline,
    required this.isSyncing,
    required this.pendingCount,
    required this.tick,
  });

  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final int tick;

  bool get hasPending => pendingCount > 0;
}

final syncStatusProvider = Provider<SyncStatusState>((ref) {
  final online = ref.watch(connectivityProvider);
  final tick = ref.watch(dataVersionProvider);
  final engine = ref.watch(syncEngineProvider);
  final queue = ref.watch(syncQueueStoreProvider);

  return SyncStatusState(
    isOnline: online,
    isSyncing: engine.isFlushing,
    pendingCount: queue.count,
    tick: tick,
  );
});