import '../../../core/constants/app_constants.dart';
import '../../../core/database/hive_service.dart';
import '../../../core/network/remote_cache_service.dart';

/// Aggregates downline activity for the "Team Activity" tab.
///
/// Reads always come from Hive (which holds both seeded history and anything
/// the device created offline); [refresh] pulls the latest server-side state
/// for the scope the current head is allowed to observe and merges it in,
/// never clobbering a local record that is still queued for sync.
class TeamRepository {
  TeamRepository({required this.remote});

  final RemoteCacheService remote;

  Future<void> refresh(List<String> scopeIds) async {
    if (scopeIds.isEmpty) return;
    if (!await remote.isOnline) return;

    final data = await remote.getJson(
      '${AppConstants.teamActivityEndpoint}?ids=${scopeIds.join(',')}',
    );
    if (data == null) return;

    await _merge(AppConstants.punchesBox, data['punches']);
    await _merge(AppConstants.visitsBox, data['visits']);
    await _merge(AppConstants.ordersBox, data['orders']);
    await _merge(AppConstants.usersBox, data['allUsers']);
  }

  Future<void> _merge(String boxName, dynamic rawList) async {
    if (rawList is! List) return;
    final box = HiveService.byName(boxName);
    for (final raw in rawList) {
      if (raw is! Map) continue;
      final json = Map<String, dynamic>.from(raw)..['syncStatus'] = 'synced';
      final id = json['id'] as String?;
      if (id == null) continue;

      final local = box.get(id);
      if (local != null && local['syncStatus'] == 'pending') continue;
      await box.put(id, json);
    }
  }
}
