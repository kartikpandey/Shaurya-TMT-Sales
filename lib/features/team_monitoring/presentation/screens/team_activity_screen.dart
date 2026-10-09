import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../users/providers/users_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/sync_banner.dart';
import '../../../users/domain/entities/app_user.dart';
import '../../../orders/domain/entities/order.dart';
import '../../providers/team_providers.dart';

class TeamActivityScreen extends ConsumerStatefulWidget {
  const TeamActivityScreen({super.key});

  @override
  ConsumerState<TeamActivityScreen> createState() => _TeamActivityScreenState();
}

class _TeamActivityScreenState extends ConsumerState<TeamActivityScreen> {
  String? _memberFilter;
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await refreshTeamActivity(ref);
    ref.read(dataVersionProvider.notifier).increment();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final team = ref.watch(downlineUsersProvider);
    final onDutyIds = ref.watch(teamOnDutyIdsProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Team Activity',
          showBackButton: false,
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refreshing ? null : _refresh,
              icon: _refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SyncBanner(compact: true),
              _RosterStrip(
                members: team,
                onDutyIds: onDutyIds,
                selectedId: _memberFilter,
                onSelect: (id) => setState(() => _memberFilter = id),
              ),
              const TabBar(
                labelColor: AppColors.primaryOrange,
                unselectedLabelColor: AppColors.textHint,
                indicatorColor: AppColors.primaryOrange,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: [
                  Tab(text: 'Punches'),
                  Tab(text: 'Visits'),
                  Tab(text: 'Orders'),
                  Tab(text: 'Users'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _PunchTab(memberFilter: _memberFilter),
                    _VisitTab(memberFilter: _memberFilter),
                    _OrderTab(memberFilter: _memberFilter),
                    _UserTab(memberFilter: _memberFilter),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RosterStrip extends StatelessWidget {
  const _RosterStrip({
    required this.members,
    required this.onDutyIds,
    required this.selectedId,
    required this.onSelect,
  });

  final List<AppUser> members;
  final Set<String> onDutyIds;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        children: [
          _RosterChip(
            label: 'All (${members.length})',
            selected: selectedId == null,
            onDuty: false,
            showDot: false,
            onTap: () => onSelect(null),
          ),
          ...members.map(
            (member) => _RosterChip(
              label: member.name.split(RegExp(r'\s+')).first,
              selected: selectedId == member.id,
              onDuty: onDutyIds.contains(member.id),
              showDot: true,
              onTap: () => onSelect(selectedId == member.id ? null : member.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _RosterChip extends StatelessWidget {
  const _RosterChip({
    required this.label,
    required this.selected,
    required this.onDuty,
    required this.showDot,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool onDuty;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryOrange.withValues(alpha:0.14)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.primaryOrange
                  : AppColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDot) ...[
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: onDuty
                        ? AppColors.successGreen
                        : AppColors.textHint,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              Text(
                label,
                style: AppTextStyles.labelSmall(context).copyWith(
                  color: selected ? AppColors.primaryOrange : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [child],
    );
  }
}

class _ListTileCard extends StatelessWidget {
  const _ListTileCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium(context)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall(
                    context,
                  ).copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class _PunchTab extends ConsumerWidget {
  const _PunchTab({required this.memberFilter});

  final String? memberFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final punches = ref.watch(teamPunchesProvider).where((p) {
      return memberFilter == null || p.userId == memberFilter;
    }).take(60).toList();
    final byId = ref.watch(usersByIdProvider);

    if (punches.isEmpty) {
      return const EmptyState(
        icon: Icons.fingerprint,
        title: 'No punches yet',
        subtitle: 'Punch-in and punch-out events from your team appear here.',
      );
    }

    return _TabBody(
      child: Column(
        children: [
          for (final punch in punches)
            _ListTileCard(
              leading: UserAvatar(
                initials: byId[punch.userId]?.initials ?? '?',
                size: 36,
              ),
              title: byId[punch.userId]?.name ?? 'Unknown',
              subtitle:
                  '${AppFormatters.formatDate(punch.createdAt)} â€¢ ${AppFormatters.formatTime(punch.createdAt)}'
                  '${punch.location == null ? '' : '  â€¢  GPS captured'}',
              trailing: StatusChip(
                label: punch.isIn ? 'IN' : 'OUT',
                dense: true,
                tone: punch.isIn ? StatusTone.success : StatusTone.neutral,
                icon: punch.isIn
                    ? Icons.play_arrow_rounded
                    : Icons.stop_rounded,
              ),
            ),
        ],
      ),
    );
  }
}

class _VisitTab extends ConsumerWidget {
  const _VisitTab({required this.memberFilter});

  final String? memberFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visits = ref.watch(teamVisitsProvider).where((v) {
      return memberFilter == null || v.userId == memberFilter;
    }).take(60).toList();
    final byId = ref.watch(usersByIdProvider);

    if (visits.isEmpty) {
      return const EmptyState(
        icon: Icons.place_outlined,
        title: 'No visits yet',
        subtitle: 'Customer check-ins from your team appear here.',
      );
    }

    return _TabBody(
      child: Column(
        children: [
          for (final visit in visits)
            _ListTileCard(
              leading: UserAvatar(
                initials: byId[visit.userId]?.initials ?? '?',
                size: 36,
              ),
              title: byId[visit.entityId]?.name ?? 'Unknown customer',
              subtitle:
                  '${byId[visit.userId]?.name ?? 'Unknown'} â€¢ ${AppFormatters.formatDate(visit.checkInAt)}'
                  ' â€¢ ${AppFormatters.formatTime(visit.checkInAt)}'
                  '${visit.checkOutAt == null ? ' - open' : ' - ${AppFormatters.formatTime(visit.checkOutAt!)}'}',
              trailing: StatusChip(
                label: visit.duration.inMinutes < 60
                    ? '${visit.duration.inMinutes}m'
                    : '${visit.duration.inHours}h ${visit.duration.inMinutes.remainder(60)}m',
                dense: true,
                tone: visit.isActive ? StatusTone.info : StatusTone.neutral,
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderTab extends ConsumerWidget {
  const _OrderTab({required this.memberFilter});

  final String? memberFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(teamOrdersProvider).where((o) {
      return memberFilter == null || o.ownerId == memberFilter;
    }).take(60).toList();
    final byId = ref.watch(usersByIdProvider);

    if (orders.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        subtitle: 'Orders booked by your team appear here.',
      );
    }

    return _TabBody(
      child: Column(
        children: [
          for (final order in orders)
            _ListTileCard(
              leading: UserAvatar(
                initials: byId[order.ownerId]?.initials ?? '?',
                size: 36,
              ),
              title: '${byId[order.entityId]?.name ?? 'Unknown customer'} â€¢ '
                  '${AppFormatters.formatCurrency(order.totalAmount)}',
              subtitle:
                  '${byId[order.ownerId]?.name ?? 'Unknown'} â€¢ ${AppFormatters.formatDate(order.createdAt)} â€¢ '
                  '${order.totalUnits} units',
              trailing: StatusChip(
                label: order.status.name.toUpperCase(),
                dense: true,
                tone: switch (order.status) {
                  OrderStatus.accepted => StatusTone.success,
                  OrderStatus.rejected => StatusTone.error,
                  OrderStatus.placed => StatusTone.info,
                  OrderStatus.draft => StatusTone.neutral,
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _UserTab extends ConsumerWidget {
  const _UserTab({required this.memberFilter});

  final String? memberFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final created = ref.watch(teamUserCreationsProvider).where((u) {
      return memberFilter == null || u.createdBy == memberFilter;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final byId = ref.watch(usersByIdProvider);

    if (created.isEmpty) {
      return const EmptyState(
        icon: Icons.person_add_alt_outlined,
        title: 'No new users yet',
        subtitle: 'Accounts onboarded by your team will be listed here.',
      );
    }

    return _TabBody(
      child: Column(
        children: [
          for (final user in created)
            _ListTileCard(
              leading: UserAvatar(
                initials: user.initials,
                size: 36,
                accent: user.isInternal
                    ? AppColors.primaryOrange
                    : AppColors.infoBlue,
              ),
              title: user.name,
              subtitle:
                  '${user.displayRole} â€¢ created ${AppFormatters.formatDate(user.createdAt)}'
                  '${user.createdBy == null ? '' : ' by ${byId[user.createdBy]?.name ?? 'Unknown'}'}',
              trailing: StatusChip(
                label: user.isActive ? 'Active' : 'Inactive',
                dense: true,
                tone: user.isActive ? StatusTone.success : StatusTone.error,
              ),
            ),
        ],
      ),
    );
  }
}
