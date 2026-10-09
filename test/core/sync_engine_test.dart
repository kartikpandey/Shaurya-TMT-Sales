import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_app/core/constants/app_constants.dart';
import 'package:sales_app/core/database/hive_service.dart';
import 'package:sales_app/core/domain/sync_status.dart';
import 'package:sales_app/core/network/network_info.dart';
import 'package:sales_app/core/sync/sync_engine.dart';
import 'package:sales_app/core/sync/sync_queue_item.dart';
import 'package:sales_app/core/sync/sync_queue_store.dart';

class _FakeNetwork implements NetworkInfo {
  _FakeNetwork(this.online);
  bool online;

  @override
  Future<bool> get isConnected async => online;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

Dio _dioReturning(int? statusCode) {
  final dio = Dio(BaseOptions(baseUrl: 'http://sync.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final response = Response<dynamic>(
          requestOptions: options,
          statusCode: statusCode,
          data: {'ok': true},
        );
        if (statusCode != null && statusCode >= 200 && statusCode < 300) {
          handler.resolve(response);
        } else {
          handler.reject(
            DioException(
              requestOptions: options,
              response: response,
              type: DioExceptionType.badResponse,
              message: 'server error',
            ),
          );
        }
      },
    ),
  );
  return dio;
}

void main() {
  late Directory tempDir;
  late SyncQueueStore queue;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('sales_engine_test');
    await HiveService.initForTest(tempDir.path);
  });

  setUp(() async {
    await HiveService.wipe();
    queue = SyncQueueStore();
  });

  tearDownAll(() async {
    await HiveService.wipe();
    await Hive.close();
    try { tempDir.deleteSync(recursive: true); } catch (_) {}
  });

  SyncQueueItem makeItem({
    String id = 'q1',
    DateTime? createdAt,
    int retries = 0,
  }) => SyncQueueItem(
    id: id,
    resource: SyncResource.visit,
    operation: SyncOperation.create,
    recordId: 'v-$id',
    recordBox: AppConstants.visitsBox,
    method: 'POST',
    endpoint: '/api/visits',
    payload: {'id': 'v-$id'},
    createdAt: createdAt ?? DateTime.now(),
  )..retries = retries;

  Future<void> seedRecord(String id) => HiveService.visits.put(id, {
    'id': id,
    'userId': 'u',
    'entityId': 'e',
    'checkInAt': DateTime.now().toIso8601String(),
    'syncStatus': 'pending',
  });

  Future<SyncStatus?> statusOf(String id) async {
    final json = HiveService.visits.get(id);
    return json == null ? null : SyncStatus.fromName(json['syncStatus'] as String?);
  }

  SyncEngine engine({required bool online, required Dio dio}) => SyncEngine(
    queue: queue,
    dio: dio,
    network: _FakeNetwork(online),
  );

  test('successful push empties the queue and marks the record synced',
      () async {
    await seedRecord('v-q1');
    await queue.enqueue(makeItem());

    await engine(online: true, dio: _dioReturning(200)).flush();

    expect(queue.count, 0);
    expect(await statusOf('v-q1'), SyncStatus.synced);
  });

  test('permanent 4xx failure drops the item and marks the record failed',
      () async {
    await seedRecord('v-q1');
    await queue.enqueue(makeItem());

    await engine(online: true, dio: _dioReturning(400)).flush();

    expect(queue.count, 0);
    expect(await statusOf('v-q1'), SyncStatus.failed);
  });

  test('transient 5xx keeps the item queued for a later retry', () async {
    await seedRecord('v-q1');
    final item = makeItem();
    await queue.enqueue(item);

    await engine(online: true, dio: _dioReturning(500)).flush();

    expect(queue.count, 1);
    expect(queue.all().first.retries, 1);
    expect(await statusOf('v-q1'), SyncStatus.pending);
  });

  test('FIFO: a transient failure at the head stops the whole drain', () async {
    await seedRecord('v-a');
    await seedRecord('v-b');

    final first = makeItem(id: 'a');
    final second = makeItem(id: 'b', createdAt: DateTime.now().add(const Duration(seconds: 1)));

    await queue.enqueue(first);
    await queue.enqueue(second);

    await engine(online: true, dio: _dioReturning(500)).flush();

    final remaining = queue.all().map((i) => i.id).toList();
    expect(remaining, ['a', 'b']);
    expect(await statusOf('v-b'), SyncStatus.pending);
  });

  test('offline: nothing is pushed', () async {
    await seedRecord('v-q1');
    await queue.enqueue(makeItem());

    await engine(online: false, dio: _dioReturning(200)).flush();

    expect(queue.count, 1);
    expect(await statusOf('v-q1'), SyncStatus.pending);
  });

  test('items past the retry budget are dropped as failed', () async {
    await seedRecord('v-q1');
    await queue.enqueue(makeItem(retries: 5));

    await engine(online: true, dio: _dioReturning(200)).flush();

    expect(queue.count, 0);
    expect(await statusOf('v-q1'), SyncStatus.failed);
  });
}
