import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/sync/sync_queue_item.dart';
import '../data/users_repository.dart';
import '../domain/entities/app_user.dart';

/// Every screen that lists users reads through this repository.
final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  final factory = ref.watch(offlineStoreFactoryProvider);
  return UsersRepository(
    store: factory(
      boxName: AppConstants.usersBox,
      resource: SyncResource.user,
    ),
  );
});

/// All users, live-rebuilt after every local write or sync cycle.
final allUsersProvider = Provider<List<AppUser>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(usersRepositoryProvider).getAll();
});

final usersByIdProvider = Provider<Map<String, AppUser>>((ref) {
  final users = ref.watch(allUsersProvider);
  return {for (final u in users) u.id: u};
});

/// Internal users only - the roster used for downline selection.
final internalUsersProvider = Provider<List<AppUser>>(
  (ref) => ref.watch(allUsersProvider).where((u) => u.isInternal).toList(),
);

/// External entities only - the catalog used when booking a visit/order.
final externalEntitiesProvider = Provider<List<AppUser>>(
  (ref) => ref.watch(allUsersProvider).where((u) => u.isExternal).toList(),
);
