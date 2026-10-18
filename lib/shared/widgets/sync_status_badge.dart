import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';
import '../../features/sync/providers/sync_providers.dart';
import '../../features/sync/services/sync_engine.dart';

class SyncStatusBadge extends ConsumerWidget {
  final bool compact;

  const SyncStatusBadge({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);

    Color indicatorColor;
    String statusText;
    IconData? actionIcon;

    switch (syncState.status) {
      case SyncStatusState.idle:
        if (syncState.pendingOperationsCount > 0) {
          indicatorColor = context.accent;
          statusText = '${syncState.pendingOperationsCount} queued';
          actionIcon = LucideIcons.uploadCloud;
        } else {
          indicatorColor = AppColors.success;
          statusText = 'Synced';
          actionIcon = LucideIcons.check;
        }
        break;
      case SyncStatusState.syncing:
        indicatorColor = context.accent;
        statusText = 'Syncing...';
        actionIcon = LucideIcons.refreshCw;
        break;
      case SyncStatusState.offline:
        indicatorColor = AppColors.warning;
        statusText = 'Offline';
        actionIcon = LucideIcons.cloudOff;
        break;
      case SyncStatusState.error:
        indicatorColor = AppColors.error;
        statusText = 'Sync alert';
        actionIcon = LucideIcons.alertCircle;
        break;
    }

    return InkWell(
      onTap: () => _showSyncSheet(context, ref, syncState),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 6,
        ),
        decoration: BoxDecoration(
          color: context.secondarySurface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: syncState.status == SyncStatusState.offline
                ? AppColors.warning.withValues(alpha: 0.4)
                : context.border,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6.5,
              height: 6.5,
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: AppTypography.code(
                syncState.status == SyncStatusState.offline
                    ? AppColors.warning
                    : context.mutedText,
                fontSize: compact ? 10.5 : 11,
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 4),
              Icon(actionIcon, size: 11, color: context.mutedText),
            ],
          ],
        ),
      ),
    );
  }

  void _showSyncSheet(BuildContext context, WidgetRef ref, SyncState syncState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sync Status', style: AppTypography.titleMedium(context.primaryText)),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SyncInfoRow(
                  label: 'Connectivity',
                  value: syncState.status == SyncStatusState.offline ? 'Offline' : 'Online',
                  color: syncState.status == SyncStatusState.offline ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(height: 8),
                _SyncInfoRow(
                  label: 'Pending Queue',
                  value: '${syncState.pendingOperationsCount} operations',
                  color: syncState.pendingOperationsCount > 0 ? context.accent : context.mutedText,
                ),
                const SizedBox(height: 8),
                _SyncInfoRow(
                  label: 'Last Sync',
                  value: syncState.lastSuccessfulSync != null
                      ? '${syncState.lastSuccessfulSync!.hour.toString().padLeft(2, '0')}:${syncState.lastSuccessfulSync!.minute.toString().padLeft(2, '0')}:${syncState.lastSuccessfulSync!.second.toString().padLeft(2, '0')}'
                      : 'Never',
                  color: context.mutedText,
                ),
                if (syncState.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  _SyncInfoRow(
                    label: 'Status Note',
                    value: syncState.errorMessage!,
                    color: AppColors.error,
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ref.read(syncEngineProvider).synchronize();
                    },
                    icon: const Icon(LucideIcons.refreshCw, size: 14),
                    label: const Text('Sync Now'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SyncInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SyncInfoRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall(context.secondaryText)),
        Text(value, style: AppTypography.labelSmall(color)),
      ],
    );
  }
}
