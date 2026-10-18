import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../tasks/providers/task_providers.dart';
import '../../../database/database_provider.dart';

class ShutdownSheet extends ConsumerStatefulWidget {
  const ShutdownSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ShutdownSheet(),
    );
  }

  @override
  ConsumerState<ShutdownSheet> createState() => _ShutdownSheetState();
}

class _ShutdownSheetState extends ConsumerState<ShutdownSheet> {
  final TextEditingController _reflectionController = TextEditingController();
  bool _isCompleted = false;

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayTasksAsync = ref.watch(todayTasksStreamProvider);
    final tasks = todayTasksAsync.asData?.value ?? [];

    final completedTasks = tasks.where((t) => t.isCompleted).toList();
    final remainingTasks = tasks.where((t) => !t.isCompleted).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: context.border, width: 1)),
      ),
      child: _isCompleted
          ? _buildSuccessView(context, completedTasks.length)
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.sunset, size: 20, color: context.accent),
                          const SizedBox(width: 10),
                          Text(
                            'Daily Shutdown Ritual',
                            style: AppTypography.titleMedium(context.primaryText),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Clear open loops, triage leftover tasks, and close your day with peace of mind.',
                    style: AppTypography.bodySmall(context.mutedText),
                  ),
                  const SizedBox(height: 18),

                  // Accomplishments Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.secondarySurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.border, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.award, size: 18, color: context.accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${completedTasks.length} Accomplishment(s) Today',
                                style: AppTypography.bodyMedium(context.primaryText).copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                remainingTasks.isEmpty
                                    ? 'Zero leftover tasks. Exceptional focus!'
                                    : '${remainingTasks.length} pending task(s) to triage before closing.',
                                style: AppTypography.bodySmall(context.mutedText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Remaining Tasks Triage
                  if (remainingTasks.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TRIAGE UNFINISHED TASKS',
                          style: AppTypography.code(context.mutedText, fontSize: 10).copyWith(letterSpacing: 1.2),
                        ),
                        TextButton(
                          onPressed: () async {
                            final repo = ref.read(taskRepositoryProvider);
                            final tomorrow = DateTime.now().add(const Duration(days: 1));
                            for (final t in remainingTasks) {
                              await repo.snoozeTask(t.id, tomorrow);
                            }
                          },
                          child: Text('Move All to Tomorrow', style: AppTypography.code(context.accent, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...remainingTasks.map((t) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.border, width: 0.8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(t.title, style: AppTypography.bodySmall(context.primaryText)),
                              ),
                              // Quick Move to Tomorrow
                              IconButton(
                                tooltip: 'Move to Tomorrow',
                                icon: const Icon(LucideIcons.arrowRightCircle, size: 15),
                                color: context.accent,
                                onPressed: () {
                                  final tomorrow = DateTime.now().add(const Duration(days: 1));
                                  ref.read(taskRepositoryProvider).snoozeTask(t.id, tomorrow);
                                },
                              ),
                              // Move to Inbox (Unschedule)
                              IconButton(
                                tooltip: 'Move to Inbox',
                                icon: const Icon(LucideIcons.inbox, size: 15),
                                color: context.mutedText,
                                onPressed: () {
                                  final repo = ref.read(taskRepositoryProvider);
                                  repo.updateTask(t.copyWith(clearDeadline: true, isFocus: false));
                                },
                              ),
                              // Complete Now
                              IconButton(
                                tooltip: 'Mark Completed',
                                icon: const Icon(LucideIcons.check, size: 15),
                                color: Colors.green,
                                onPressed: () {
                                  ref.read(taskRepositoryProvider).toggleTaskCompletion(t.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Reflection Note
                  Text(
                    'DAILY REFLECTION / BRAIN DUMP',
                    style: AppTypography.code(context.mutedText, fontSize: 10).copyWith(letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reflectionController,
                    style: AppTypography.bodySmall(context.primaryText),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'What went well? Any thoughts to clear from your mind before signing off...',
                      hintStyle: AppTypography.bodySmall(context.mutedText),
                      filled: true,
                      fillColor: context.secondarySurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: context.border, width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: context.accent, width: 1.2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Complete Shutdown Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        setState(() => _isCompleted = true);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: context.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(LucideIcons.checkCircle2, size: 16),
                      label: Text(
                        'Complete Daily Shutdown',
                        style: AppTypography.labelMedium(Colors.black).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSuccessView(BuildContext context, int completedCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.moon, size: 48, color: context.accent),
          const SizedBox(height: 16),
          Text(
            'Daily Shutdown Complete',
            style: AppTypography.titleLarge(context.primaryText),
          ),
          const SizedBox(height: 8),
          Text(
            'You accomplished $completedCount task(s) today. Your slate is clean for tomorrow. Rest and recharge.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(context.mutedText),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: context.secondarySurface,
              foregroundColor: context.primaryText,
              side: BorderSide(color: context.border, width: 1),
            ),
            child: const Text('Close Workstation'),
          ),
        ],
      ),
    );
  }
}
