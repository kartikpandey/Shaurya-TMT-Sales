import 'dart:async';

import '../database/hive_service.dart';
import '../database/json_box.dart';
import '../domain/sync_status.dart';
import 'sync_engine.dart';
import 'sync_queue_item.dart';
import 'sync_queue_store.dart';

/// Single write-path used by every repository.
///
/// 1. stamps `syncStatus` and writes to Hive (this is what the UI reads), then
/// 2. enqueues the HTTP mutation for the sync engine, then
/// 3. kicks off an immediate flush (a no-op when offline).
///
/// This is what makes check-ins, orders and user creation work with no
/// connectivity while still updating downline feeds the moment the device
/// comes back online.
class OfflineFirstStore {
  OfflineFirstStore({
    required this.box,
    required this.queue,
    required this.engine,
    required this.resource,
    this.onLocalWrite,
  });

  final JsonBox box;
  final SyncQueueStore queue;
  final SyncEngine engine;
  final SyncResource resource;

  /// Called after every local write so Riverpod-driven screens rebuild from
  /// Hive immediately.
  final void Function()? onLocalWrite;

  factory OfflineFirstStore.forBox({
    required String boxName,
    required SyncQueueStore queue,
    required SyncEngine engine,
    required SyncResource resource,
    void Function()? onLocalWrite,
  }) => OfflineFirstStore(
    box: HiveService.byName(boxName),
    queue: queue,
    engine: engine,
    resource: resource,
    onLocalWrite: onLocalWrite,
  );

  Future<void> save({
    required String id,
    required Map<String, dynamic> data,
    required SyncOperation operation,
    required String method,
    required String endpoint,
    SyncStatus status = SyncStatus.pending,
  }) async {
    data['syncStatus'] = status.name;
    await box.put(id, data);
    onLocalWrite?.call();

    if (status == SyncStatus.synced) return;

    await queue.enqueue(
      SyncQueueItem(
        resource: resource,
        operation: operation,
        recordId: id,
        recordBox: box.name,
        method: method,
        endpoint: endpoint,
        payload: data,
      ),
    );
    unawaited(engine.flush());
  }

  Future<void> delete({required String id, required String endpoint}) async {
    await box.delete(id);
    onLocalWrite?.call();
    await queue.enqueue(
      SyncQueueItem(
        resource: resource,
        operation: SyncOperation.delete,
        recordId: id,
        recordBox: box.name,
        method: 'DELETE',
        endpoint: endpoint,
      ),
    );
    unawaited(engine.flush());
  }
}
