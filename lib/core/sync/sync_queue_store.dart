import '../database/hive_service.dart';
import '../database/json_box.dart';
import 'sync_queue_item.dart';

/// FIFO store of pending offline mutations.
class SyncQueueStore {
  SyncQueueStore([JsonBox? box]) : _box = box ?? HiveService.syncQueue;

  final JsonBox _box;

  Future<void> enqueue(SyncQueueItem item) => _box.put(item.id, item.toJson());

  List<SyncQueueItem> all() {
    final items = _box
        .all()
        .map(SyncQueueItem.fromJson)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  int get count => _box.length;

  bool containsRecord(String recordId) => _box.all().any(
    (json) => json['recordId'] == recordId,
  );

  Future<void> remove(String id) => _box.delete(id);

  Future<void> clear() => _box.clear();
}
