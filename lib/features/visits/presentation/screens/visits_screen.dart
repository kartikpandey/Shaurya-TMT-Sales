import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/sync_banner.dart';
import '../../providers/visits_providers.dart';
import '../../../users/providers/users_providers.dart';
import '../../../../core/location/location_service.dart';
import '../../domain/entities/visit.dart';
import 'visit_form_screen.dart';

class VisitsScreen extends ConsumerWidget {
  const VisitsScreen({super.key});

  static const _locationService = LocationService();

  Future<void> _checkOut(
    BuildContext context,
    WidgetRef ref,
    Visit visit,
    String entityName,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Check out?',
      message: 'Check out of $entityName and close this visit?',
      confirmLabel: 'Check out',
    );
    if (!confirmed || !context.mounted) return;

    final location = await _locationService.current().timeout(
      const Duration(seconds: 6),
      onTimeout: () => null,
    );
    if (!context.mounted) return;

    await ref.read(visitsRepositoryProvider).checkOut(visit, location: location);
    ref.read(dataVersionProvider.notifier).increment();
    if (context.mounted) {
      showAppSnack(context, 'Checked out - visit closed');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeVisitProvider);
    final visits = ref.watch(myVisitsProvider);
    final byId = ref.watch(usersByIdProvider);

    return Scaffold(
      appBar: CustomAppBar(title: 'Visits', showBackButton: false),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'visits_fab',
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const VisitFormScreen())),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Check in'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          children: [
            const SyncBanner(compact: true),

            if (active != null)
              _ActiveVisitCard(
                visit: active,
                entityName: byId[active.entityId]?.name ?? 'Customer',
                entityType: byId[active.entityId]?.entityType?.label ?? '',
                onCheckOut: () => _checkOut(
                  context,
                  ref,
                  active,
                  byId[active.entityId]?.name ?? 'this customer',
                ),
              )
            else
              CustomCardIdleHint(
                icon: Icons.directions_walk_outlined,
                title: 'No visit in progress',
                subtitle:
                    'Check in when you reach a distributor, dealer or '
                    'sub-dealer. Duration is tracked until you check out.',
                actionLabel: 'Start a visit',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VisitFormScreen()),
                ),
              ),

            SectionHeader(title: 'History', padding: const EdgeInsets.only(top: 20, bottom: 4)),
            if (visits.isEmpty)
              const EmptyState(
                icon: Icons.place_outlined,
                title: 'No visits yet',
                subtitle: 'Your check-ins will appear here with their duration.',
              )
            else
              ...visits.map((visit) {
                final entity = byId[visit.entityId];
                return _VisitTile(
                  visit: visit,
                  entityName: entity?.name ?? 'Unknown customer',
                  entityType: entity?.entityType?.label ?? '',
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ActiveVisitCard extends StatelessWidget {
  const _ActiveVisitCard({
    required this.visit,
    required this.entityName,
    required this.entityType,
    required this.onCheckOut,
  });

  final Visit visit;
  final String entityName;
  final String entityType;
  final VoidCallback onCheckOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha:0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.successGreen.withValues(alpha:0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusChip(
                label: 'CHECKED IN',
                tone: StatusTone.success,
                icon: Icons.radio_button_checked,
                dense: true,
              ),
              const Spacer(),
              Text(
                'Since ${AppFormatters.formatTime(visit.checkInAt)}',
                style: AppTextStyles.labelSmall(
                  context,
                ).copyWith(color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(entityName, style: AppTextStyles.titleLarge(context)),
          if (entityType.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              entityType,
              style: AppTextStyles.labelSmall(
                context,
              ).copyWith(color: AppColors.textHint),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Check out',
                  backgroundColor: AppColors.warningRed,
                  foregroundColor: Colors.white,
                  icon: Icons.logout_rounded,
                  onPressed: onCheckOut,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisitTile extends StatelessWidget {
  const _VisitTile({
    required this.visit,
    required this.entityName,
    required this.entityType,
  });

  final Visit visit;
  final String entityName;
  final String entityType;

  String get _duration {
    final d = visit.duration;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.place_outlined,
              color: AppColors.primaryOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entityName, style: AppTextStyles.bodyMedium(context)),
                const SizedBox(height: 3),
                Text(
                  [
                    if (entityType.isNotEmpty) entityType,
                    '${AppFormatters.formatDate(visit.checkInAt)} â€¢ '
                        '${AppFormatters.formatTime(visit.checkInAt)}'
                        '${visit.checkOutAt == null ? '' : ' - ${AppFormatters.formatTime(visit.checkOutAt!)}'}',
                  ].join('  |  '),
                  style: AppTextStyles.labelSmall(
                    context,
                  ).copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_duration, style: AppTextStyles.numericSmall(context)),
              const SizedBox(height: 4),
              SyncBadge(status: visit.syncStatus),
            ],
          ),
        ],
      ),
    );
  }
}

/// Soft "nothing happening yet" prompt with a call to action.
class CustomCardIdleHint extends StatelessWidget {
  const CustomCardIdleHint({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryOrange),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppTextStyles.titleMedium(context))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: CustomButton(
              label: actionLabel,
              type: ButtonType.secondary,
              width: 160,
              onPressed: onAction,
            ),
          ),
        ],
      ),
    );
  }
}
