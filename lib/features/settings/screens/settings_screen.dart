import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/accent_packs.dart';
import '../../../core/theme/theme_provider.dart';
import '../../sync/providers/sync_providers.dart';
import '../../sync/services/sync_engine.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../database/database_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/widgets/auth_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeNotifierProvider);
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    final syncEngine = ref.watch(syncEngineProvider);
    final syncState = ref.watch(syncStateProvider);
    final syncQueueRepo = ref.watch(syncQueueRepositoryProvider);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          children: [
            // Header
            Text(
              'PREFERENCES & SYSTEM',
              style: AppTypography.labelMedium(context.mutedText).copyWith(
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Settings',
              style: AppTypography.displayLarge(context.primaryText),
            ),
            const SizedBox(height: 24),

            // --- Account & Cloud Identity Section ---
            Text(
              'ACCOUNT & CLOUD IDENTITY',
              style: AppTypography.labelSmall(context.mutedText).copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border, width: 1),
              ),
              child: authState.isAuthenticated
                  ? Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: context.accent, width: 1),
                          ),
                          child: Center(
                            child: Icon(LucideIcons.userCheck, size: 20, color: context.accent),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    authState.user!.email,
                                    style: AppTypography.bodyMedium(context.primaryText).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.green.withValues(alpha: 0.5), width: 0.8),
                                    ),
                                    child: Text(
                                      'ONLINE & SYNCED',
                                      style: AppTypography.code(Colors.greenAccent, fontSize: 9).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'UUID: ${authState.user!.id.substring(0, authState.user!.id.length > 8 ? 8 : authState.user!.id.length)}... • Cloud replication active',
                                style: AppTypography.code(context.mutedText, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.secondarySurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: context.border, width: 1),
                          ),
                          child: Center(
                            child: Icon(LucideIcons.shield, size: 20, color: context.mutedText),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Local Offline Guest Mode',
                                style: AppTypography.bodyMedium(context.primaryText).copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Data stored locally in SQLite. Connect account for cross-device sync.',
                                style: AppTypography.bodySmall(context.mutedText),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => AuthDialog.show(context),
                          icon: const Icon(LucideIcons.logIn, size: 14, color: Colors.black),
                          label: const Text('Connect'),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // --- Theme Mode Section ---
            Text(
              'APPEARANCE',
              style: AppTypography.labelSmall(context.mutedText).copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border, width: 1),
              ),
              child: Column(
                children: [
                  _ThemeOptionTile(
                    title: 'Obsidian Slate (Dark)',
                    subtitle: 'Deep graphite tones to eliminate glare',
                    isSelected: themeState.themeMode == ThemeMode.dark,
                    onTap: () => themeNotifier.setThemeMode(ThemeMode.dark),
                  ),
                  const Divider(height: 1),
                  _ThemeOptionTile(
                    title: 'Warm Paper (Light)',
                    subtitle: 'Calm cream and paper hues without clinical white glare',
                    isSelected: themeState.themeMode == ThemeMode.light,
                    onTap: () => themeNotifier.setThemeMode(ThemeMode.light),
                  ),
                  const Divider(height: 1),
                  _ThemeOptionTile(
                    title: 'System Default',
                    subtitle: 'Follows system brightness schedule',
                    isSelected: themeState.themeMode == ThemeMode.system,
                    onTap: () => themeNotifier.setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // --- Accent Pack Section ---
            Text(
              'ACCENT PACK',
              style: AppTypography.labelSmall(context.mutedText).copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              'Accents strictly tint interactive feedback (checkboxes, progress, active items).',
              style: AppTypography.bodySmall(context.mutedText),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border, width: 1),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AccentPack.values.map((pack) {
                  final isSelected = themeState.accentPack == pack;
                  final accentColor = pack.colorFor(Theme.of(context).brightness);

                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => themeNotifier.setAccentPack(pack),
                    child: Container(
                      width: 130,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? context.accentSubtle.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? accentColor : context.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pack.displayName,
                              style: AppTypography.bodySmall(context.primaryText).copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 28),

            // --- Synchronization & Offline First Diagnostics ---
            Text(
              'SYNC ENGINE & OFFLINE DIAGNOSTICS',
              style: AppTypography.labelSmall(context.mutedText).copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: ${syncState.status.name.toUpperCase()}',
                            style: AppTypography.titleMedium(context.primaryText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            syncState.lastSuccessfulSync != null
                                ? 'Last synced: ${DateFormat('hh:mm a').format(syncState.lastSuccessfulSync!)}'
                                : 'No remote sync executed yet',
                            style: AppTypography.bodySmall(context.mutedText),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: syncState.status == SyncStatusState.syncing
                            ? null
                            : () => syncEngine.synchronize(),
                        icon: const Icon(LucideIcons.refreshCw, size: 14, color: Colors.black),
                        label: const Text('Sync Now'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pending persistent queue mutations:',
                        style: AppTypography.bodyMedium(context.secondaryText),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.secondarySurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: context.border, width: 0.8),
                        ),
                        child: Text(
                          '${syncState.pendingOperationsCount}',
                          style: AppTypography.code(context.accent, fontSize: 12).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // --- Data Backup & Portability Section ---
            Text(
              'DATA OWNERSHIP & BACKUP',
              style: AppTypography.labelSmall(context.mutedText).copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              'Your data is stored locally in SQLite. Export anytime with zero lock-in.',
              style: AppTypography.bodySmall(context.mutedText),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(LucideIcons.fileCode, size: 15),
                      label: const Text('Export JSON'),
                      onPressed: () async {
                        final tasks = await ref.read(taskRepositoryProvider).watchTasks().first;
                        final categories = await ref.read(categoryRepositoryProvider).getCategories();
                        final exportMap = {
                          'exportedAt': DateTime.now().toIso8601String(),
                          'categories': categories.map((c) => c.toJson()).toList(),
                          'tasks': tasks.map((t) => t.toJson()).toList(),
                        };
                        final jsonStr = const JsonEncoder.withIndent('  ').convert(exportMap);
                        if (context.mounted) {
                          _showExportDialog(context, 'JSON Backup', jsonStr);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(LucideIcons.fileText, size: 15),
                      label: const Text('Export Markdown'),
                      onPressed: () async {
                        final tasks = await ref.read(taskRepositoryProvider).watchTasks().first;
                        final buffer = StringBuffer();
                        buffer.writeln('# Task Export — ${DateFormat('yyyy-MM-dd').format(DateTime.now())}\n');
                        buffer.writeln('## Active Tasks');
                        for (final t in tasks.where((t) => !t.isCompleted)) {
                          buffer.writeln('- [ ] ${t.title}${t.priority.name != 'none' ? ' [${t.priority.displayName}]' : ''}');
                        }
                        buffer.writeln('\n## Completed Tasks');
                        for (final t in tasks.where((t) => t.isCompleted)) {
                          buffer.writeln('- [x] ${t.title}');
                        }
                        if (context.mounted) {
                          _showExportDialog(context, 'Markdown Checklist', buffer.toString());
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // --- Sync History Audit Log ---
            Text(
              'RECENT SYNC HISTORY',
              style: AppTypography.labelSmall(context.mutedText).copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),

            StreamBuilder(
              stream: syncQueueRepo.watchHistory(limit: 5),
              builder: (ctx, snapshot) {
                final history = snapshot.data ?? [];
                if (history.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.border, width: 1),
                    ),
                    child: Center(
                      child: Text('No sync history records yet.', style: AppTypography.bodySmall(context.mutedText)),
                    ),
                  );
                }

                return Column(
                  children: history.map((entry) {
                    final isSuccess = entry.status == 'success';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSuccess ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                            size: 14,
                            color: isSuccess ? context.accent : context.colorScheme.error,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('hh:mm:ss a').format(entry.timestamp),
                            style: AppTypography.code(context.secondaryText, fontSize: 11),
                          ),
                          const Spacer(),
                          Text(
                            '${entry.changesCount} mutations',
                            style: AppTypography.bodySmall(context.mutedText),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: context.border, width: 1),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.titleMedium(context.primaryText)),
            IconButton(
              icon: const Icon(LucideIcons.copy, size: 16),
              tooltip: 'Copy to clipboard',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title copied to clipboard!'),
                    backgroundColor: context.surface,
                  ),
                );
              },
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 350,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.secondarySurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.border, width: 0.8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                content,
                style: AppTypography.code(context.primaryText, fontSize: 11),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? context.accent : context.border,
                  width: isSelected ? 5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyMedium(context.primaryText)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodySmall(context.mutedText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
