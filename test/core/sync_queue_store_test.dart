import 'dart:io';

import 'package:hive/hive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_app/core/database/hive_service.dart';
import 'package:sales_app/core/sync/sync_queue_item.dart';
import 'package:sales_app/core/sync/sync_queue_store.dart';

void main() {
  late Directory tempDir;
  late SyncQueueStore store;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('sales_queue_test');
    await HiveService.initForTest(tempDir.path);
  });

  setUp(() async {
    await HiveService.wipe();
    store = SyncQueueStore();
  });

  tearDownAll(() async {
    await HiveService.wipe();
    await Hive.close();
    try { tempDir.deleteSync(recursive: true); } catch (_) {}
  });

  SyncQueueItem item(String id, DateTime createdAt) => SyncQueueItem(
    id: id,
    resource: SyncResource.visit,
    operation: SyncOperation.create,
    recordId: 'record-$id',
    recordBox: 'visitsBox',
    method: 'POST',
    endpoint: '/api/visits',
    payload: {'id': 'record-$id'},
    createdAt: createdAt,
  );

  test('enqueue then all() returns items in FIFO (createdAt) order', () async {
    await store.enqueue(item('c', DateTime.now().add(const Duration(seconds: 2))));
    await store.enqueue(item('a', DateTime.now()));
    await store.enqueue(item('b', DateTime.now().add(const Duration(seconds: 1))));

    expect(store.count, 3);
    expect(store.all().map((i) => i.id).toList(), ['a', 'b', 'c']);
  });

  test('payload round-trips through Hive', () async {
    final original = item('a', DateTime.now());
    await store.enqueue(original);

    final restored = store.all().firstWhere((i) => i.id == 'a');
    expect(restored.endpoint, original.endpoint);
    expect(restored.payload['id'], 'record-a');
    expect(restored.resource, SyncResource.visit);
    expect(restored.retries, 0);
  });

  test('containsRecord / remove / clear manage the queue', () async {
    await store.enqueue(item('a', DateTime.now()));
    expect(store.containsRecord('record-a'), isTrue);

    await store.remove('a');
    expect(store.count, 0);
    expect(store.containsRecord('record-a'), isFalse);

    await store.enqueue(item('b', DateTime.now()));
    await store.clear();
    expect(store.count, 0);
  });
}
