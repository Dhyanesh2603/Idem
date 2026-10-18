import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../tasks/providers/task_providers.dart';
import '../../../database/database_provider.dart';

class DailyPlanningSheet extends ConsumerWidget {
  const DailyPlanningSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(filteredTasksStreamProvider);
    final allTasks = (tasksAsync.asData?.value ?? [])
        .where((t) => !t.isCompleted && !t.isDeleted)
        .toList();

    final focusCount = allTasks.where((t) => t.isFocus).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: context.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Planning Session',
                    style: AppTypography.titleLarge(context.primaryText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select 3 to 5 core priorities for today. Avoid overwhelm.',
                    style: AppTypography.bodySmall(context.mutedText),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Workload Intentional Recommendation Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.secondarySurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.border, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  focusCount > 5 ? LucideIcons.alertCircle : LucideIcons.sparkles,
                  size: 16,
                  color: focusCount > 5 ? context.colorScheme.error : context.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    focusCount > 5
                        ? '$focusCount tasks selected. Consider trimming to protect your focus.'
                        : '$focusCount / 5 target focus tasks selected.',
                    style: AppTypography.bodySmall(context.primaryText),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Task Selector List
          Expanded(
            child: ListView.separated(
              itemCount: allTasks.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 6),
              itemBuilder: (ctx, i) {
                final task = allTasks[i];
                return Container(
                  decoration: BoxDecoration(
                    color: task.isFocus
                        ? context.accentSubtle.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: task.isFocus ? context.accent : context.border,
                      width: 1,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: task.isFocus,
                    activeColor: context.accent,
                    checkColor: Colors.black,
                    title: Text(
                      task.title,
                      style: AppTypography.bodyMedium(context.primaryText).copyWith(
                        fontWeight: task.isFocus ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    subtitle: task.deadline != null
                        ? Text(
                            'Scheduled: ${task.deadline!.month}/${task.deadline!.day}',
                            style: AppTypography.bodySmall(context.mutedText),
                          )
                        : null,
                    onChanged: (val) {
                      ref.read(taskRepositoryProvider).toggleFocus(task.id);
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Commit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Commit to Today'),
            ),
          ),
        ],
      ),
    );
  }
}
