import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../domain/sync_status.dart';

enum StatusTone { success, warning, error, info, neutral }

/// Small pill used for duty state, order status and sync state.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    this.dense = false,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;
  final bool dense;

  Color get _color => switch (tone) {
    StatusTone.success => AppColors.successGreen,
    StatusTone.warning => AppColors.gradeBColor,
    StatusTone.error => AppColors.warningRed,
    StatusTone.info => AppColors.infoBlue,
    StatusTone.neutral => AppColors.textHint,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color.withValues(alpha:0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: _color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall(
              context,
            ).copyWith(color: _color),
          ),
        ],
      ),
    );
  }
}

/// Sync state pill derived from a record's [SyncStatus].
class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key, required this.status, this.showSynced = false});

  final SyncStatus status;
  final bool showSynced;

  @override
  Widget build(BuildContext context) {
    if (status == SyncStatus.synced && !showSynced) {
      return const SizedBox.shrink();
    }
    return StatusChip(
      label: status.label,
      dense: true,
      icon: switch (status) {
        SyncStatus.pending => Icons.cloud_off_outlined,
        SyncStatus.synced => Icons.cloud_done_outlined,
        SyncStatus.failed => Icons.sync_problem_outlined,
      },
      tone: switch (status) {
        SyncStatus.pending => StatusTone.warning,
        SyncStatus.synced => StatusTone.success,
        SyncStatus.failed => StatusTone.error,
      },
    );
  }
}
