import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/sync_banner.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../users/providers/users_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    await ref.read(syncEngineProvider).flush();
    ref.read(dataVersionProvider.notifier).increment();
    if (context.mounted) showAppSnack(context, 'Sync complete');
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: 'Any unsynced changes stay queued and will sync next time.',
      confirmLabel: 'Log out',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(authStateProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final sync = ref.watch(syncStatusProvider);
    if (user == null) return const SizedBox.shrink();

    final manager = ref.watch(
      usersByIdProvider.select((map) {
        final parentId = user.reportsToId ?? user.parentEntityId;
        return parentId == null ? null : map[parentId];
      }),
    );

    return Scaffold(
      appBar: CustomAppBar(title: 'Profile'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SyncBanner(),
          CustomCard(
            child: Row(
              children: [
                UserAvatar(
                  initials: user.initials,
                  size: 56,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: AppTextStyles.titleLarge(context)),
                      const SizedBox(height: 4),
                      Text(
                        user.displayRole,
                        style: AppTextStyles.labelMedium(
                          context,
                        ).copyWith(color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          SectionHeader(title: 'Details', padding: EdgeInsets.zero),
          const SizedBox(height: 8),
          CustomCard(
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.badge_outlined,
                  label: 'Type',
                  value: user.isInternal ? 'Internal' : user.entityType!.label,
                ),
                _DetailRow(
                  icon: Icons.alternate_email,
                  label: 'Email / Phone',
                  value: (user.email.isNotEmpty ? user.email : user.phone),
                ),
                _DetailRow(
                  icon: Icons.supervisor_account_outlined,
                  label: 'Reports to',
                  value: manager?.name ?? 'Top of hierarchy',
                ),
                _DetailRow(
                  icon: Icons.home_outlined,
                  label: 'Home coordinates',
                  value: user.homeLocation == null
                      ? 'Not set'
                      : '${user.homeLocation!.lat.toStringAsFixed(5)}, '
                            '${user.homeLocation!.lng.toStringAsFixed(5)}',
                ),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Joined',
                  value: AppFormatters.formatDate(user.createdAt),
                  showDivider: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          SectionHeader(title: 'Sync', padding: EdgeInsets.zero),
          const SizedBox(height: 8),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Offline queue',
                        style: AppTextStyles.bodyMedium(context),
                      ),
                    ),
                    StatusChip(
                      label: sync.hasPending
                          ? '${sync.pendingCount} pending'
                          : 'All synced',
                      tone: sync.hasPending
                          ? StatusTone.warning
                          : StatusTone.success,
                      dense: true,
                      icon: sync.hasPending
                          ? Icons.cloud_off_outlined
                          : Icons.cloud_done_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  sync.isOnline
                      ? 'Connected to ${sync.isSyncing ? 'syncing now' : 'server'}'
                      : 'Offline - changes are queued on this device',
                  style: AppTextStyles.labelSmall(
                    context,
                  ).copyWith(color: AppColors.textHint),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: 'Sync now',
                        type: ButtonType.secondary,
                        icon: Icons.sync,
                        onPressed: () => _syncNow(context, ref),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          CustomButton(
            label: 'Log out',
            type: ButtonType.secondary,
            foregroundColor: AppColors.warningRed,
            backgroundColor: AppColors.warningRed,
            icon: Icons.logout_rounded,
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryOrange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelMedium(
                    context,
                  ).copyWith(color: AppColors.textHint),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.bodySmall(context),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.borderLight),
      ],
    );
  }
}
