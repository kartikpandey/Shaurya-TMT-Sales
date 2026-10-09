import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/geo_point.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/kpi_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/sync_banner.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../orders/presentation/screens/order_form_screen.dart';
import '../../../visits/presentation/screens/visit_form_screen.dart';
import '../../providers/dashboard_providers.dart';
import 'home_shell.dart';
import 'profile_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const _locationService = LocationService();

  bool _punching = false;

  static const _visitTarget = 10;
  static const _orderTarget = 10;

  Future<void> _togglePunch(bool value, String userId) async {
    setState(() => _punching = true);
    // GPS is captured opportunistically for audit; never blocks the punch.
    final GeoPoint? point = await _locationService.current().timeout(
      const Duration(seconds: 6),
      onTimeout: () => null,
    );
    try {
      await ref
          .read(punchRepositoryProvider)
          .punch(userId: userId, goingOnDuty: value, location: point);
      ref.read(dataVersionProvider.notifier).increment();
    } finally {
      if (mounted) setState(() => _punching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    final user = ref.watch(currentUserProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          GreetingHeader(
            title: user == null
                ? ''
                : 'Hello, ${user.name.split(RegExp(r'\s+')).first}',
            subtitle: _greeting(),
            trailing: InkWell(
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primaryOrange,
                  size: 22,
                ),
              ),
            ),
          ),
          const SyncBanner(),
          const SizedBox(height: 8),

          _PunchCard(
            onDuty: stats.onDuty,
            since: stats.punchSince,
            busy: _punching,
            userId: stats.userId,
            onToggle: (value) => _togglePunch(value, stats.userId),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: KPICard(
                  title: 'Visits Today',
                  value: '${stats.visitsToday}',
                  subtitle: 'Target $_visitTarget / day',
                  icon: Icons.place_outlined,
                  accentColor: AppColors.primaryOrange,
                  progress: (stats.visitsToday / _visitTarget).clamp(0.0, 1.0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KPICard(
                  title: 'Orders Today',
                  value: '${stats.ordersToday}',
                  subtitle: 'Target $_orderTarget / day',
                  icon: Icons.receipt_long_outlined,
                  accentColor: AppColors.successGreen,
                  progress: (stats.ordersToday / _orderTarget).clamp(0.0, 1.0),
                ),
              ),
            ],
          ),

          if (stats.canViewTeam) ...[
            const SizedBox(height: 12),
            _TeamSummaryCard(stats: stats),
          ],

          const SizedBox(height: 20),
          SectionHeader(
            title: 'Quick actions',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.add_location_alt_outlined,
                  label: 'New Visit',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const VisitFormScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.add_shopping_cart_outlined,
                  label: 'New Order',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OrderFormScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.sync_outlined,
                  label: 'Sync',
                  onTap: () async {
                    await ref.read(syncEngineProvider).flush();
                    ref.read(dataVersionProvider.notifier).increment();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }
}

class _PunchCard extends StatelessWidget {
  const _PunchCard({
    required this.onDuty,
    required this.since,
    required this.busy,
    required this.userId,
    required this.onToggle,
  });

  final bool onDuty;
  final DateTime? since;
  final bool busy;
  final String userId;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final color = onDuty ? AppColors.successGreen : AppColors.textHint;

    return CustomCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha:0.35)),
            ),
            child: Icon(
              onDuty ? Icons.play_arrow_rounded : Icons.stop_rounded,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  onDuty ? 'ON DUTY' : 'OFF DUTY',
                  style: AppTextStyles.titleLarge(
                    context,
                  ).copyWith(color: onDuty ? AppColors.successGreen : AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  onDuty
                      ? 'Since ${AppFormatters.formatDateTime(since ?? DateTime.now())}'
                      : 'Tap the switch to start your day',
                  style: AppTextStyles.labelSmall(
                    context,
                  ).copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ),
          busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch.adaptive(
                  value: onDuty,
                  activeColor: AppColors.successGreen,
                  onChanged: (value) => onToggle(value),
                ),
        ],
      ),
    );
  }
}

class _TeamSummaryCard extends StatelessWidget {
  const _TeamSummaryCard({required this.stats});

  final dynamic stats;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.groups_outlined,
                color: AppColors.primaryOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Team today',
                  style: AppTextStyles.titleMedium(context),
                ),
              ),
              StatusChip(
                label: '${stats.teamOnDuty} on duty',
                tone: StatusTone.success,
                icon: Icons.radio_button_checked,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TeamStat(
                  label: 'Members',
                  value: '${stats.teamCount}',
                ),
              ),
              Expanded(
                child: _TeamStat(
                  label: 'Visits',
                  value: '${stats.teamVisitsToday}',
                ),
              ),
              Expanded(
                child: _TeamStat(
                  label: 'Orders',
                  value: '${stats.teamOrdersToday}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamStat extends StatelessWidget {
  const _TeamStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.numericMedium(context)),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.labelSmall(
            context,
          ).copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryOrange.withValues(alpha:0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryOrange.withValues(alpha:0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryOrange),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.labelSmall(
                context,
              ).copyWith(color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }
}
