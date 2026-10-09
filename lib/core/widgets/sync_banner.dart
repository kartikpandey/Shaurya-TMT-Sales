import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Slim banner that surfaces connectivity and the offline queue.
/// Hides itself when online with an empty queue.
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncStatusProvider);
    final idle = sync.isOnline && !sync.hasPending && !sync.isSyncing;
    if (idle) return const SizedBox.shrink();

    final offline = !sync.isOnline;
    final Color color = offline
        ? AppColors.warningRed
        : sync.isSyncing
        ? AppColors.infoBlue
        : AppColors.gradeBColor;

    final String message = offline
        ? (sync.hasPending
              ? 'Offline - ${sync.pendingCount} change${sync.pendingCount == 1 ? '' : 's'} waiting to sync'
              : 'Offline - changes will sync automatically')
        : sync.isSyncing
        ? 'Syncing ${sync.pendingCount > 0 ? '${sync.pendingCount} change${sync.pendingCount == 1 ? '' : 's'}' : '...'}'
        : '${sync.pendingCount} change${sync.pendingCount == 1 ? '' : 's'} pending sync';

    return Container(
      margin: compact
          ? const EdgeInsets.fromLTRB(16, 0, 16, 8)
          : const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.35)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: sync.isSyncing
                ? CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(color),
                  )
                : Icon(offline ? Icons.cloud_off : Icons.sync, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.labelMedium(context).copyWith(color: color),
            ),
          ),
          if (!offline && sync.hasPending && !sync.isSyncing)
            GestureDetector(
              onTap: () async {
                await ref.read(syncEngineProvider).flush();
                ref.read(dataVersionProvider.notifier).increment();
              },
              child: Text(
                'Sync now',
                style: AppTextStyles.labelMedium(
                  context,
                ).copyWith(color: AppColors.primaryOrange),
              ),
            ),
        ],
      ),
    );
  }
}
