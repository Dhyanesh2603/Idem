import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../tasks/providers/task_providers.dart';
import '../../../database/database_provider.dart';
import '../widgets/contribution_heatmap.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(filteredTasksStreamProvider);
    final allTasks = tasksAsync.asData?.value ?? [];

    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));

    final completedThisWeek = allTasks.where((t) {
      if (!t.isCompleted || t.completedAt == null) return false;
      return t.completedAt!.isAfter(oneWeekAgo);
    }).toList();

    final overdueTasks = allTasks.where((t) => t.isOverdue).toList();

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          children: [
            // Header
            Text(
              'REFLECTION & RECOVERY',
              style: AppTypography.labelMedium(context.mutedText).copyWith(
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Review',
              style: AppTypography.displayLarge(context.primaryText),
            ),
            const SizedBox(height: 6),
            Text(
              'Mindful progress tracking and calm backlog recovery.',
              style: AppTypography.bodySmall(context.secondaryText),
            ),
            const SizedBox(height: 24),

            // Recovery Assistant (Guilt-free reset if overdue tasks exist)
            if (overdueTasks.isNotEmpty) ...[
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
                      children: [
                        Icon(LucideIcons.lifeBuoy, size: 18, color: context.accent),
                        const SizedBox(width: 10),
                        Text(
                          'Recovery Assistant',
                          style: AppTypography.titleMedium(context.primaryText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have ${overdueTasks.length} overdue tasks. Life happens. Clear your mental slate without guilt.',
                      style: AppTypography.bodyMedium(context.secondaryText),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            final repo = ref.read(taskRepositoryProvider);
                            for (final t in overdueTasks) {
                              await repo.snoozeTask(t.id, DateTime.now());
                            }
                          },
                          child: const Text('Reschedule All to Today'),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            final repo = ref.read(taskRepositoryProvider);
                            final nextWeek = DateTime.now().add(const Duration(days: 7));
                            for (final t in overdueTasks) {
                              await repo.snoozeTask(t.id, nextWeek);
                            }
                          },
                          child: const Text('Push to Next Week'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final repo = ref.read(taskRepositoryProvider);
                            for (final t in overdueTasks) {
                              final updated = t.copyWith(clearDeadline: true);
                              await repo.updateTask(updated);
                            }
                          },
                          child: const Text('Move to Inbox'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // GitHub-Style 365-Day Contribution Heatmap & Streaks
            ContributionHeatmap(allTasks: allTasks),
            const SizedBox(height: 28),

            // Calm Typographical Progress Section
            Text(
              'WEEKLY CADENCE',
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${completedThisWeek.length}',
                          style: AppTypography.displayMedium(context.accent).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tasks completed in past 7 days',
                          style: AppTypography.bodySmall(context.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: context.border,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${allTasks.where((t) => !t.isCompleted && !t.isDeleted).length}',
                          style: AppTypography.displayMedium(context.primaryText).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Remaining active backlog',
                          style: AppTypography.bodySmall(context.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Completed tasks list
            Text(
              'COMPLETED RECENTLY',
              style: AppTypography.labelSmall(context.mutedText).copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),

            if (completedThisWeek.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No completed tasks yet this week.',
                    style: AppTypography.bodyMedium(context.mutedText),
                  ),
                ),
              )
            else
              ...completedThisWeek.map((task) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.checkCheck, size: 16, color: context.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.title,
                          style: AppTypography.bodyMedium(context.primaryText).copyWith(
                            decoration: TextDecoration.lineThrough,
                            decorationColor: context.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
