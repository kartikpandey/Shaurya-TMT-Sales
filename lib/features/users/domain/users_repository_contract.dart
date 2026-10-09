import '../../../core/domain/geo_point.dart';
import 'entities/app_user.dart';

/// Contract for the user/entity store used by auth, user management, orders
/// and team monitoring.
abstract interface class UsersRepositoryContract {
  List<AppUser> getAll();
  AppUser? getById(String id);
  AppUser? getByEmailOrPhone(String identifier);

  /// Direct + indirect downline of an internal user.
  List<AppUser> downlineOf(String userId);

  /// `userId` plus every descendant id - the observable scope of a head.
  List<String> scopeIdsFor(String userId);

  Future<AppUser> create(AppUser user);
  Future<AppUser> update(AppUser user);
  Future<void> saveHomeLocation(String userId, GeoPoint point);
  Future<void> delete(String id);
}
