import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../tasks/models/task_model.dart';
import '../../../database/database_provider.dart';
import '../services/smart_day_scheduler.dart';

class AutoScheduleDialog extends ConsumerWidget {
  final List<TaskModel> todayTasks;

  const AutoScheduleDialog({super.key, required this.todayTasks});

  static Future<void> show(BuildContext context, List<TaskModel> tasks) {
    return showDialog(
      context: context,
      builder: (_) => AutoScheduleDialog(todayTasks: tasks),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = SmartDayScheduler.generatePlan(tasks: todayTasks);

    return AlertDialog(
      backgroundColor: context.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.border, width: 1),
      ),
      title: Row(
        children: [
          Icon(LucideIcons.sparkles, size: 20, color: context.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ALGORITHMIC DAY ORCHESTRATOR',
                  style: AppTypography.code(context.mutedText, fontSize: 9).copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Auto-Schedule Timeline',
                  style: AppTypography.titleMedium(context.primaryText),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: plan.slots.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No pending tasks to schedule for today.',
                    style: AppTypography.bodyMedium(context.mutedText),
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Load Summary Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.secondarySurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.border, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: context.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: context.accent, width: 0.8),
                          ),
                          child: Text(
                            '${plan.cognitiveLoadLevel.toUpperCase()} LOAD',
                            style: AppTypography.code(context.accent, fontSize: 10).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${plan.slots.length} tasks • ${plan.totalMinutes ~/ 60}h ${plan.totalMinutes % 60}m planned',
                            style: AppTypography.bodySmall(context.primaryText).copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'OPTIMIZED FLOW SCHEDULE',
                    style: AppTypography.code(context.mutedText, fontSize: 9).copyWith(letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),

                  // Slots List
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: plan.slots.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final slot = plan.slots[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.border, width: 0.8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.secondarySurface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  slot.timeFormatted,
                                  style: AppTypography.code(context.accent, fontSize: 10),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  slot.task.title,
                                  style: AppTypography.bodySmall(context.primaryText),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (plan.slots.isNotEmpty)
          FilledButton.icon(
            onPressed: () async {
              final repo = ref.read(taskRepositoryProvider);
              await SmartDayScheduler.applyPlanToRepository(plan: plan, repo: repo);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Auto-scheduled ${plan.slots.length} tasks across your day timeline!'),
                    backgroundColor: context.surface,
                  ),
                );
              }
            },
            icon: const Icon(LucideIcons.check, size: 14),
            label: const Text('Apply Schedule'),
          ),
      ],
    );
  }
}
