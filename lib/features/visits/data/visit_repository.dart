import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/domain/geo_point.dart';
import '../../../core/domain/sync_status.dart';
import '../../../core/sync/offline_first_store.dart';
import '../../../core/sync/sync_queue_item.dart';
import '../domain/entities/visit.dart';

/// Visit check-in / check-out at customer and dealer premises.
///
/// Per spec: coordinates + duration only, no notes or comments are captured.
class VisitRepository {
  VisitRepository({required this.store});

  final OfflineFirstStore store;

  List<Visit> all({int? limit}) {
    final items = store.box
        .all(
          orderBy: (a, b) => (b['checkInAt'] as String? ?? '')
              .compareTo(a['checkInAt'] as String? ?? ''),
        )
        .map(Visit.fromJson)
        .toList();
    return limit == null ? items : items.take(limit).toList();
  }

  List<Visit> forUser(String userId, {int? limit}) {
    final items = all().where((v) => v.userId == userId).toList();
    return limit == null ? items : items.take(limit).toList();
  }

  List<Visit> forUsers(Set<String> userIds) =>
      all().where((v) => userIds.contains(v.userId)).toList();

  Visit? activeVisit(String userId) {
    for (final visit in forUser(userId)) {
      if (visit.isActive) return visit;
    }
    return null;
  }

  Future<Visit> checkIn({
    required String userId,
    required String entityId,
    GeoPoint? location,
  }) async {
    final visit = Visit(
      id: const Uuid().v4(),
      userId: userId,
      entityId: entityId,
      checkInAt: DateTime.now(),
      checkInLocation: location,
      syncStatus: SyncStatus.pending,
    );

    await store.save(
      id: visit.id,
      data: visit.toJson(),
      operation: SyncOperation.create,
      method: 'POST',
      endpoint: AppConstants.visitsEndpoint,
    );
    return visit;
  }

  Future<Visit> checkOut(Visit visit, {GeoPoint? location}) async {
    final updated = visit.copyWith(
      checkOutAt: DateTime.now(),
      checkOutLocation: location,
      syncStatus: SyncStatus.pending,
    );

    await store.save(
      id: updated.id,
      data: updated.toJson(),
      operation: SyncOperation.update,
      method: 'PUT',
      endpoint: '${AppConstants.visitsEndpoint}/${updated.id}',
    );
    return updated;
  }
}
