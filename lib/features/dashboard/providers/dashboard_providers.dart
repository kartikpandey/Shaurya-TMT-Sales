import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/sync/sync_queue_item.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/utils/extensions.dart';
import '../../auth/providers/auth_providers.dart';
import '../../orders/providers/orders_providers.dart';
import '../../visits/providers/visits_providers.dart';
import '../data/punch_repository.dart';

final punchRepositoryProvider = Provider<PunchRepository>((ref) {
  final factory = ref.watch(offlineStoreFactoryProvider);
  return PunchRepository(
    store: factory(
      boxName: AppConstants.punchesBox,
      resource: SyncResource.punch,
    ),
  );
});

class DashboardStats {
  const DashboardStats({
    this.onDuty = false,
    this.punchSince,
    this.visitsToday = 0,
    this.ordersToday = 0,
    this.teamCount = 0,
    this.teamOnDuty = 0,
    this.teamVisitsToday = 0,
    this.teamOrdersToday = 0,
    this.pendingSync = 0,
    this.isOnline = true,
    this.isSyncing = false,
    this.canViewTeam = false,
    this.userId = '',
  });

  final bool onDuty;
  final DateTime? punchSince;
  final int visitsToday;
  final int ordersToday;
  final int teamCount;
  final int teamOnDuty;
  final int teamVisitsToday;
  final int teamOrdersToday;
  final int pendingSync;
  final bool isOnline;
  final bool isSyncing;
  final bool canViewTeam;
  final String userId;
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  ref.watch(dataVersionProvider);
  final user = ref.watch(currentUserProvider);
  final sync = ref.watch(syncStatusProvider);
  if (user == null) return const DashboardStats();

  final punches = ref.watch(punchRepositoryProvider);
  final visits = ref.watch(visitsRepositoryProvider);
  final orders = ref.watch(ordersRepositoryProvider);
  final downline = ref.watch(downlineUsersProvider);

  final latest = punches.latestFor(user.id);
  final scopeIds = downline.map((u) => u.id).toSet();

  return DashboardStats(
    onDuty: latest?.isIn ?? false,
    punchSince: latest?.isIn == true ? latest!.createdAt : null,
    visitsToday: visits.forUser(user.id).where((v) => v.checkInAt.isToday).length,
    ordersToday: orders
        .forOwners({user.id})
        .where((o) => o.createdAt.isToday)
        .length,
    teamCount: downline.length,
    teamOnDuty: downline.where((u) => punches.isOnDuty(u.id)).length,
    teamVisitsToday: visits
        .forUsers(scopeIds)
        .where((v) => v.checkInAt.isToday)
        .length,
    teamOrdersToday: orders
        .forOwners(scopeIds)
        .where((o) => o.createdAt.isToday)
        .length,
    pendingSync: sync.pendingCount,
    isOnline: sync.isOnline,
    isSyncing: sync.isSyncing,
    canViewTeam: user.isInternal &&
        user.role != null &&
        PermissionService.canViewTeam(user.role!),
    userId: user.id,
  );
});
