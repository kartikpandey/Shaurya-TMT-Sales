import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../dashboard/domain/entities/punch_record.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../orders/domain/entities/order.dart';
import '../../orders/providers/orders_providers.dart';
import '../../users/domain/entities/app_user.dart';
import '../../users/providers/users_providers.dart';
import '../../visits/domain/entities/visit.dart';
import '../../visits/providers/visits_providers.dart';
import '../data/team_repository.dart';

final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => TeamRepository(remote: ref.watch(remoteCacheServiceProvider)),
);

/// Downline ids only (self excluded) - the audience of the Team Activity tab.
final downlineScopeProvider = Provider<Set<String>>(
  (ref) => ref.watch(downlineUsersProvider).map((u) => u.id).toSet(),
);

/// Pulls the latest server-side activity for the scope. No-op offline.
Future<void> refreshTeamActivity(WidgetRef ref) =>
    ref.read(teamRepositoryProvider).refresh(
      ref.read(downlineScopeProvider).toList(),
    );

final teamPunchesProvider = Provider<List<PunchRecord>>((ref) {
  ref.watch(dataVersionProvider);
  final scope = ref.watch(downlineScopeProvider);
  if (scope.isEmpty) return const [];
  return ref.watch(punchRepositoryProvider).forUsers(scope);
});

final teamVisitsProvider = Provider<List<Visit>>((ref) {
  ref.watch(dataVersionProvider);
  final scope = ref.watch(downlineScopeProvider);
  if (scope.isEmpty) return const [];
  return ref.watch(visitsRepositoryProvider).forUsers(scope);
});

final teamOrdersProvider = Provider<List<Order>>((ref) {
  ref.watch(dataVersionProvider);
  final scope = ref.watch(downlineScopeProvider);
  if (scope.isEmpty) return const [];
  return ref.watch(ordersRepositoryProvider).forOwners(scope);
});

/// Internal/external accounts onboarded by the downline team.
final teamUserCreationsProvider = Provider<List<AppUser>>((ref) {
  ref.watch(dataVersionProvider);
  final scope = ref.watch(downlineScopeProvider);
  if (scope.isEmpty) return const [];
  return ref
      .watch(allUsersProvider)
      .where((u) => u.createdBy != null && scope.contains(u.createdBy))
      .toList();
});

/// Punch-in status per downline member, used by the roster header.
final teamOnDutyIdsProvider = Provider<Set<String>>((ref) {
  ref.watch(dataVersionProvider);
  final scope = ref.watch(downlineScopeProvider);
  if (scope.isEmpty) return const {};
  final punches = ref.watch(punchRepositoryProvider);
  return scope.where((id) => punches.isOnDuty(id)).toSet();
});
