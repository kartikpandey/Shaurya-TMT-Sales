import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/geo_point.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../users/domain/entities/app_user.dart';
import '../../../users/presentation/widgets/entity_picker.dart';
import '../../providers/visits_providers.dart';

class VisitFormScreen extends ConsumerStatefulWidget {
  const VisitFormScreen({super.key, this.onCheckedIn});

  final VoidCallback? onCheckedIn;

  @override
  ConsumerState<VisitFormScreen> createState() => _VisitFormScreenState();
}

class _VisitFormScreenState extends ConsumerState<VisitFormScreen> {
  static const _locationService = LocationService();

  AppUser? _entity;
  bool _submitting = false;

  Future<void> _pickEntity() async {
    final picked = await showEntityPicker(context, title: 'Who are you visiting?');
    if (picked != null) setState(() => _entity = picked);
  }

  Future<void> _checkIn() async {
    final entity = _entity;
    if (entity == null) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _submitting = true);
    final GeoPoint? location = await _locationService.current().timeout(
      const Duration(seconds: 8),
      onTimeout: () => null,
    );
    if (!mounted) return;

    await ref
        .read(visitsRepositoryProvider)
        .checkIn(userId: user.id, entityId: entity.id, location: location);
    ref.read(dataVersionProvider.notifier).increment();

    if (!mounted) return;
    setState(() => _submitting = false);
    showAppSnack(context, 'Checked in at ${entity.name}');
    widget.onCheckedIn?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeVisitProvider);
    final chain = _entity == null
        ? <String>[]
        : [
            _entity!.entityType!.label,
            if (_entity!.companyName?.isNotEmpty == true)
              _entity!.companyName!,
          ];

    return Scaffold(
      appBar: CustomAppBar(title: 'Check in'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (active != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningRed.withValues(alpha:0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.warningRed.withValues(alpha:0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warningRed,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You already have an open visit. Check out before '
                        'starting another one.',
                        style: AppTextStyles.bodySmall(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text('Customer', style: AppTextStyles.labelMedium(context)),
            const SizedBox(height: 6),
            InkWell(
              onTap: active == null && !_submitting ? _pickEntity : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _entity == null
                        ? AppColors.borderLight
                        : AppColors.primaryOrange.withValues(alpha:0.5),
                  ),
                ),
                child: _entity == null
                    ? Row(
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            color: AppColors.primaryOrange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tap to select a distributor, dealer or '
                              'sub-dealer',
                              style: AppTextStyles.bodyMedium(
                                context,
                              ).copyWith(color: AppColors.textHint),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppColors.textHint,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          UserAvatar(initials: _entity!.initials),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _entity!.name,
                                  style: AppTextStyles.titleMedium(context),
                                ),
                                if (chain.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    chain.join(' â€¢ '),
                                    style: AppTextStyles.labelSmall(
                                      context,
                                    ).copyWith(color: AppColors.textHint),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.swap_horiz,
                            color: AppColors.textHint,
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.my_location,
                        size: 18,
                        color: AppColors.primaryOrange,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Location capture',
                        style: AppTextStyles.titleMedium(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your GPS coordinates are recorded at check-in and '
                    'check-out to build an auditable visit trail. A visit '
                    'tracks time only - no notes are required.',
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            CustomButton(
              label: _entity == null
                  ? 'Select a customer first'
                  : 'Check in',
              isLoading: _submitting,
              isEnabled: _entity != null && active == null && !_submitting,
              icon: Icons.login_rounded,
              onPressed: _checkIn,
            ),
          ],
        ),
      ),
    );
  }
}
