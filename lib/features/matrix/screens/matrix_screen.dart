import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/models/task_priority.dart';
import '../../tasks/providers/task_providers.dart';
import '../../tasks/widgets/task_detail_sheet.dart';
import '../../../database/database_provider.dart';

class MatrixScreen extends ConsumerWidget {
  const MatrixScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(filteredTasksStreamProvider);
    final allTasks = tasksAsync.asData?.value ?? [];
    final uncompleted = allTasks.where((t) => !t.isCompleted).toList();

    final now = DateTime.now();
    final urgentThreshold = now.add(const Duration(hours: 48));

    // Q1: Urgent & Important (High priority + deadline <= 48h or overdue)
    final q1Tasks = uncompleted.where((t) {
      final isHigh = t.priority == TaskPriority.high;
      final isUrgent = t.deadline != null && t.deadline!.isBefore(urgentThreshold);
      return isHigh && isUrgent;
    }).toList();

    // Q2: Important, Not Urgent (High priority + deadline > 48h or no deadline)
    final q2Tasks = uncompleted.where((t) {
      final isHigh = t.priority == TaskPriority.high;
      final isUrgent = t.deadline != null && t.deadline!.isBefore(urgentThreshold);
      return isHigh && !isUrgent;
    }).toList();

    // Q3: Urgent, Less Important (Medium/Low priority + deadline <= 48h or overdue)
    final q3Tasks = uncompleted.where((t) {
      final isHigh = t.priority == TaskPriority.high;
      final isUrgent = t.deadline != null && t.deadline!.isBefore(urgentThreshold);
      return !isHigh && isUrgent;
    }).toList();

    // Q4: Neither (Medium/Low/None priority + deadline > 48h or no deadline)
    final q4Tasks = uncompleted.where((t) {
      final isHigh = t.priority == TaskPriority.high;
      final isUrgent = t.deadline != null && t.deadline!.isBefore(urgentThreshold);
      return !isHigh && !isUrgent;
    }).toList();

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRIORITY MATRIX',
                          style: AppTypography.labelMedium(context.mutedText).copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Eisenhower Quadrants',
                          style: AppTypography.displayLarge(context.primaryText),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Decouple urgency from importance to focus on high-leverage strategic work.',
                          style: AppTypography.bodySmall(context.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quadrants Grid
              Expanded(
                child: isDesktop
                    ? Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: _QuadrantCard(
                                    quadrantNumber: 'Q1',
                                    title: 'DO FIRST',
                                    subtitle: 'Urgent & Critical (High Priority • Due Soon)',
                                    color: Colors.redAccent,
                                    icon: LucideIcons.alertTriangle,
                                    tasks: q1Tasks,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: _QuadrantCard(
                                    quadrantNumber: 'Q3',
                                    title: 'DELEGATE / QUICK WINS',
                                    subtitle: 'Urgent, Lower Stakes (Due Soon • Normal Priority)',
                                    color: Colors.amberAccent,
                                    icon: LucideIcons.clock,
                                    tasks: q3Tasks,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: _QuadrantCard(
                                    quadrantNumber: 'Q2',
                                    title: 'SCHEDULE / STRATEGIC',
                                    subtitle: 'Deep Leverage (High Priority • Strategic Focus)',
                                    color: context.accent,
                                    icon: LucideIcons.compass,
                                    tasks: q2Tasks,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: _QuadrantCard(
                                    quadrantNumber: 'Q4',
                                    title: 'BACKLOG & SOMEDAY',
                                    subtitle: 'Low Urgency & Low Impact (Review Later)',
                                    color: context.mutedText,
                                    icon: LucideIcons.inbox,
                                    tasks: q4Tasks,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        children: [
                          _QuadrantCard(
                            quadrantNumber: 'Q1',
                            title: 'DO FIRST',
                            subtitle: 'Urgent & Critical (High Priority • Due Soon)',
                            color: Colors.redAccent,
                            icon: LucideIcons.alertTriangle,
                            tasks: q1Tasks,
                          ),
                          const SizedBox(height: 14),
                          _QuadrantCard(
                            quadrantNumber: 'Q2',
                            title: 'SCHEDULE / STRATEGIC',
                            subtitle: 'Deep Leverage (High Priority • Strategic Focus)',
                            color: context.accent,
                            icon: LucideIcons.compass,
                            tasks: q2Tasks,
                          ),
                          const SizedBox(height: 14),
                          _QuadrantCard(
                            quadrantNumber: 'Q3',
                            title: 'DELEGATE / QUICK WINS',
                            subtitle: 'Urgent, Lower Stakes (Due Soon • Normal Priority)',
                            color: Colors.amberAccent,
                            icon: LucideIcons.clock,
                            tasks: q3Tasks,
                          ),
                          const SizedBox(height: 14),
                          _QuadrantCard(
                            quadrantNumber: 'Q4',
                            title: 'BACKLOG & SOMEDAY',
                            subtitle: 'Low Urgency & Low Impact (Review Later)',
                            color: context.mutedText,
                            icon: LucideIcons.inbox,
                            tasks: q4Tasks,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuadrantCard extends ConsumerWidget {
  final String quadrantNumber;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final List<TaskModel> tasks;

  const _QuadrantCard({
    required this.quadrantNumber,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, top: 12, bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Text(
                    quadrantNumber,
                    style: AppTypography.code(color, fontSize: 10).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleSmall(context.primaryText).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: context.secondarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: AppTypography.code(context.mutedText, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(subtitle, style: AppTypography.bodySmall(context.mutedText).copyWith(fontSize: 11)),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: context.border),

          // Tasks List
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'No active tasks in this quadrant.',
                        style: AppTypography.bodySmall(context.mutedText),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: tasks.length,
                    separatorBuilder: (_, index) => Divider(height: 1, color: context.border.withValues(alpha: 0.5)),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                        leading: InkWell(
                          onTap: () => ref.read(taskRepositoryProvider).toggleTaskCompletion(task.id),
                          borderRadius: BorderRadius.circular(4),
                          child: Icon(
                            task.isCompleted ? LucideIcons.checkSquare : LucideIcons.square,
                            size: 16,
                            color: task.isCompleted ? context.accent : context.mutedText,
                          ),
                        ),
                        title: Text(
                          task.title,
                          style: AppTypography.bodySmall(context.primaryText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: task.deadline != null
                            ? Text(
                                '${task.deadline!.month}/${task.deadline!.day}',
                                style: AppTypography.code(context.mutedText, fontSize: 10),
                              )
                            : null,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => TaskDetailSheet(taskId: task.id),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
