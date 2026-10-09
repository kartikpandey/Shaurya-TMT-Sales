import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/domain/geo_point.dart';
import '../../../core/sync/offline_first_store.dart';
import '../../../core/sync/sync_queue_item.dart';
import '../domain/entities/punch_record.dart';

/// ON DUTY / OFF DUTY transitions.
///
/// Punching is permitted from anywhere (no geofencing) - the GPS reading is
/// captured opportunistically for audit purposes only.
class PunchRepository {
  PunchRepository({required this.store});

  final OfflineFirstStore store;

  List<PunchRecord> forUser(String userId, {int? limit}) {
    final items = store.box
        .all(
          orderBy: (a, b) => (b['createdAt'] as String? ?? '')
              .compareTo(a['createdAt'] as String? ?? ''),
        )
        .map(PunchRecord.fromJson)
        .where((p) => p.userId == userId)
        .toList();
    return limit == null ? items : items.take(limit).toList();
  }

  PunchRecord? latestFor(String userId) {
    final all = forUser(userId, limit: 1);
    return all.isEmpty ? null : all.first;
  }

  List<PunchRecord> forUsers(Set<String> userIds, {int? limit}) {
    final items = store.box
        .all(
          orderBy: (a, b) => (b['createdAt'] as String? ?? '')
              .compareTo(a['createdAt'] as String? ?? ''),
        )
        .map(PunchRecord.fromJson)
        .where((p) => userIds.contains(p.userId))
        .toList();
    return limit == null ? items : items.take(limit).toList();
  }

  bool isOnDuty(String userId) => latestFor(userId)?.isIn ?? false;

  Future<PunchRecord> punch({
    required String userId,
    required bool goingOnDuty,
    GeoPoint? location,
  }) async {
    final record = PunchRecord(
      id: const Uuid().v4(),
      userId: userId,
      type: goingOnDuty ? PunchType.punchIn : PunchType.punchOut,
      createdAt: DateTime.now(),
      location: location,
    );

    await store.save(
      id: record.id,
      data: record.toJson(),
      operation: SyncOperation.create,
      method: 'POST',
      endpoint: AppConstants.punchesEndpoint,
    );
    return record;
  }
}
