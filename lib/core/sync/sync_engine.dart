import 'package:dio/dio.dart';

import '../database/hive_service.dart';
import '../domain/sync_status.dart';
import '../network/network_info.dart';
import 'sync_queue_store.dart';

/// Drains the offline mutation queue whenever connectivity returns.
///
/// Guarantees:
/// * **FIFO order** - a user created offline is pushed before an order that
///   references them; on a transient failure the engine stops and retries the
///   whole head of the queue later so ordering is never violated.
/// * **Permanent failures** (4xx) are dropped after marking the local record
///   `failed` so a bad payload cannot wedge the queue forever.
/// * Each successful push flips the originating Hive record to `synced`.
class SyncEngine {
  SyncEngine({
    required SyncQueueStore queue,
    required Dio dio,
    required NetworkInfo network,
    this.onStateChanged,
  }) : _queue = queue,
       _dio = dio,
       _network = network;

  final SyncQueueStore _queue;
  final Dio _dio;
  final NetworkInfo _network;

  /// Invoked after every flush attempt so Riverpod screens can re-read Hive.
  void Function()? onStateChanged;

  bool _flushing = false;

  bool get isFlushing => _flushing;

  int get pendingCount => _queue.count;

  /// Push every queued mutation. Safe to call concurrently.
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    onStateChanged?.call();
    try {
      if (!await _network.isConnected) return;

      final items = _queue.all();
      for (final item in items) {
        if (!item.canRetry) {
          await _markRecord(item.recordBox, item.recordId, SyncStatus.failed);
          await _queue.remove(item.id);
          continue;
        }

        try {
          await _dio.request<dynamic>(
            item.endpoint,
            data: item.payload,
            options: Options(method: item.method),
          );
          await _markRecord(item.recordBox, item.recordId, SyncStatus.synced);
          await _queue.remove(item.id);
        } on DioException catch (e) {
          final status = e.response?.statusCode;
          final isPermanent =
              status != null && status >= 400 && status < 500 && status != 408;
          item.retries += 1;
          item.lastError = e.message ?? 'sync failed';

          if (isPermanent) {
            await _markRecord(item.recordBox, item.recordId, SyncStatus.failed);
            await _queue.remove(item.id);
            continue;
          }

          // Transient (offline / 5xx): persist the retry count and stop so
          // FIFO ordering is preserved.
          await _queue.enqueue(item);
          break;
        }
      }
    } finally {
      _flushing = false;
      onStateChanged?.call();
    }
  }

  Future<void> _markRecord(
    String boxName,
    String recordId,
    SyncStatus status,
  ) async {
    if (boxName.isEmpty || recordId.isEmpty) return;
    final box = HiveService.byName(boxName);
    final record = box.get(recordId);
    if (record == null) return;
    record['syncStatus'] = status.name;
    await box.put(recordId, record);
  }
}
