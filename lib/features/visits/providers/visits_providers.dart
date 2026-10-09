import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/sync/sync_queue_item.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/visit_repository.dart';
import '../domain/entities/visit.dart';

final visitsRepositoryProvider = Provider<VisitRepository>((ref) {
  final factory = ref.watch(offlineStoreFactoryProvider);
  return VisitRepository(
    store: factory(
      boxName: AppConstants.visitsBox,
      resource: SyncResource.visit,
    ),
  );
});

/// The signed-in user's visits, newest first.
final myVisitsProvider = Provider<List<Visit>>((ref) {
  ref.watch(dataVersionProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  return ref.watch(visitsRepositoryProvider).forUser(user.id);
});

/// The single open visit of the signed-in user (at most one at a time).
final activeVisitProvider = Provider<Visit?>((ref) {
  final visits = ref.watch(myVisitsProvider);
  for (final visit in visits) {
    if (visit.isActive) return visit;
  }
  return null;
});

/// Visits across the observable scope (own + downline), for heads.
final scopedVisitsProvider = Provider<List<Visit>>((ref) {
  ref.watch(dataVersionProvider);
  final scope = ref.watch(userScopeProvider).toSet();
  if (scope.isEmpty) return const [];
  return ref.watch(visitsRepositoryProvider).forUsers(scope);
});
