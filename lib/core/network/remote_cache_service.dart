import 'package:dio/dio.dart';

import '../database/hive_service.dart';
import 'network_info.dart';

/// Pulls collections from the backend and merges them into Hive so that every
/// screen can keep reading from local storage only.
class RemoteCacheService {
  RemoteCacheService({required Dio dio, required NetworkInfo network})
    : _dio = dio,
      _network = network;

  final Dio _dio;
  final NetworkInfo _network;

  Future<bool> get isOnline => _network.isConnected;

  /// GET [endpoint] and merge every record into [boxName].
  /// Records are keyed by `id` and always stored as `synced`.
  Future<int> mergeCollection(String endpoint, String boxName) async {
    final box = HiveService.byName(boxName);
    final response = await _dio.get<dynamic>(endpoint);
    final data = response.data;
    if (data is! List) return 0;

    var merged = 0;
    for (final raw in data) {
      if (raw is! Map) continue;
      final json = Map<String, dynamic>.from(raw)
        ..['syncStatus'] = 'synced';
      final id = json['id'] as String?;
      if (id == null) continue;

      // Never clobber an offline edit that is still queued for sync.
      final local = box.get(id);
      if (local != null && local['syncStatus'] == 'pending') continue;

      await box.put(id, json);
      merged++;
    }
    return merged;
  }

  Future<Map<String, dynamic>?> getJson(String endpoint) async {
    final response = await _dio.get<dynamic>(endpoint);
    final data = response.data;
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }
}
