import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/domain/geo_point.dart';
import '../../../core/domain/sync_status.dart';
import '../../../core/sync/offline_first_store.dart';
import '../../../core/sync/sync_queue_item.dart';
import '../domain/entities/app_user.dart';
import '../domain/user_hierarchy.dart';
import '../domain/users_repository_contract.dart';

/// Offline-first CRUD for every user type (internal roles *and* external
/// entities). Reads come from Hive; writes land locally first and are queued
/// for the sync engine.
class UsersRepository implements UsersRepositoryContract {
  UsersRepository({required this.store});

  final OfflineFirstStore store;

  @override
  List<AppUser> getAll() => store.box
      .all(
        orderBy: (a, b) => (a['createdAt'] as String? ?? '').compareTo(
          b['createdAt'] as String? ?? '',
        ),
      )
      .map(AppUser.fromJson)
      .toList();

  @override
  AppUser? getById(String id) {
    final json = store.box.get(id);
    return json == null ? null : AppUser.fromJson(json);
  }

  @override
  AppUser? getByEmailOrPhone(String identifier) {
    final normalized = identifier.trim().toLowerCase();
    for (final json in store.box.all()) {
      final user = AppUser.fromJson(json);
      if (user.email.toLowerCase() == normalized ||
          user.phone == identifier.trim()) {
        return user;
      }
    }
    return null;
  }

  @override
  List<AppUser> downlineOf(String userId) =>
      UserHierarchy.downlineOf(getAll(), userId);

  @override
  List<String> scopeIdsFor(String userId) =>
      UserHierarchy.scopeIds(getAll(), userId);

  @override
  Future<AppUser> create(AppUser user) async {
    final id = user.id.isEmpty ? const Uuid().v4() : user.id;
    final record = user.copyWith(id: id, syncStatus: SyncStatus.pending);
    await store.save(
      id: id,
      data: record.toJson(),
      operation: SyncOperation.create,
      method: 'POST',
      endpoint: AppConstants.usersEndpoint,
    );
    return record;
  }

  @override
  Future<AppUser> update(AppUser user) async {
    final record = user.copyWith(syncStatus: SyncStatus.pending);
    await store.save(
      id: record.id,
      data: record.toJson(),
      operation: SyncOperation.update,
      method: 'PUT',
      endpoint: '${AppConstants.usersEndpoint}/${record.id}',
    );
    return record;
  }

  @override
  Future<void> saveHomeLocation(String userId, GeoPoint point) async {
    final user = getById(userId);
    if (user == null) return;
    final record = user.copyWith(
      homeLocation: point,
      syncStatus: SyncStatus.pending,
    );
    await store.save(
      id: userId,
      data: record.toJson(),
      operation: SyncOperation.update,
      method: 'PUT',
      endpoint: AppConstants.userHomeCoordinatesEndpoint(userId),
    );
  }

  @override
  Future<void> delete(String id) => store.delete(
    id: id,
    endpoint: '${AppConstants.usersEndpoint}/$id',
  );
}
