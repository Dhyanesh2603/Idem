import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_motion.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/models/task_priority.dart';
import '../../tasks/models/recurring_rule.dart';
import '../../tasks/providers/task_providers.dart';
import '../../tasks/widgets/task_detail_sheet.dart';
import '../../categories/providers/category_providers.dart';
import '../../../database/database_provider.dart';

class TodayTaskItem extends ConsumerWidget {
  final TaskModel task;
  final int? dragIndex;

  const TodayTaskItem({
    super.key,
    required this.task,
    this.dragIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockersAsync = ref.watch(taskUnfinishedBlockersProvider(task.id));
    final hasBlockers = blockersAsync.asData?.value.isNotEmpty ?? false;
    final subtasksAsync = ref.watch(taskSubtasksStreamProvider(task.id));
    final subtasks = subtasksAsync.asData?.value ?? [];
    final completedSubtasks = subtasks.where((s) => s.isCompleted).length;
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final category = task.categoryId != null
        ? categoriesAsync.asData?.value.where((c) => c.id == task.categoryId).firstOrNull
        : null;

    return AnimatedOpacity(
      duration: AppMotion.taskCompletion,
      opacity: task.isCompleted ? 0.45 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: task.isFocus
                ? context.accent.withValues(alpha: 0.4)
                : context.border,
            width: task.isFocus ? 1.5 : 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => TaskDetailSheet(taskId: task.id),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom Smooth Checkbox
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(taskRepositoryProvider).toggleTaskCompletion(task.id);
                      },
                      child: AnimatedContainer(
                        duration: AppMotion.checkboxCheck,
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: task.isCompleted ? context.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: task.isCompleted ? context.accent : context.border,
                            width: 1.5,
                          ),
                        ),
                        child: task.isCompleted
                            ? const Center(
                                child: Icon(LucideIcons.check, size: 13, color: Colors.black),
                              )
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Title, Description & Wrapped Metadata Badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: AppTypography.bodyLarge(context.primaryText).copyWith(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: context.mutedText,
                          ),
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall(context.mutedText),
                          ),
                        ],

                        // Responsive Wrapping Tag Chips
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Blocked indicator if prerequisite unfinished
                            if (hasBlockers)
                              Tooltip(
                                message: 'Blocked by prerequisite tasks',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: context.colorScheme.error.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: context.colorScheme.error.withValues(alpha: 0.3), width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.lock, size: 10, color: context.colorScheme.error),
                                      const SizedBox(width: 3),
                                      Text('Blocked', style: AppTypography.code(context.colorScheme.error, fontSize: 9)),
                                    ],
                                  ),
                                ),
                              ),

                            // Priority Pill (if set)
                            if (task.priority != TaskPriority.none)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: task.priority.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: task.priority.color.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  task.priority.displayName.toUpperCase(),
                                  style: AppTypography.code(task.priority.color, fontSize: 9).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                            // Category Pill (if set)
                            if (category != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Color(int.parse(category.colorHex.replaceFirst('#', '0xFF'))).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Color(int.parse(category.colorHex.replaceFirst('#', '0xFF'))).withValues(alpha: 0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  category.name,
                                  style: AppTypography.code(
                                    Color(int.parse(category.colorHex.replaceFirst('#', '0xFF'))),
                                    fontSize: 9,
                                  ),
                                ),
                              ),

                            // Deadline Badge (if set)
                            if (task.deadline != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.secondarySurface,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: context.border, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.clock, size: 9, color: context.mutedText),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('h:mm a').format(task.deadline!),
                                      style: AppTypography.code(context.mutedText, fontSize: 9),
                                    ),
                                  ],
                                ),
                              ),

                            // Subtasks Progress Pill (if has subtasks)
                            if (subtasks.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.secondarySurface,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: context.border, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.checkSquare,
                                      size: 9,
                                      color: completedSubtasks == subtasks.length ? context.accent : context.mutedText,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$completedSubtasks/${subtasks.length}',
                                      style: AppTypography.code(
                                        completedSubtasks == subtasks.length ? context.accent : context.mutedText,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Recurring Routine Badge
                            if (task.recurringRule != RecurringRule.none)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.secondarySurface,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: context.border, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.repeat, size: 9, color: context.accent),
                                    const SizedBox(width: 4),
                                    Text(
                                      task.recurringRule.displayName,
                                      style: AppTypography.code(context.accent, fontSize: 9),
                                    ),
                                  ],
                                ),
                              ),

                            // Focus Time Spent Badge
                            if (task.timeSpentMinutes > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.secondarySurface,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: context.border, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.timer, size: 9, color: context.mutedText),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${task.timeSpentMinutes}m focused',
                                      style: AppTypography.code(context.mutedText, fontSize: 9),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Trailing Section: Focus Launcher, More Actions & Drag Handle
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Direct Focus Mode Launcher
                      if (task.isFocus && !task.isCompleted)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: InkWell(
                            onTap: () => context.go('/focus'),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: context.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: context.accent, width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.play, size: 9, color: context.accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Focus',
                                    style: AppTypography.code(context.accent, fontSize: 10).copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Quick Actions Menu
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: Icon(LucideIcons.moreVertical, size: 16, color: context.mutedText),
                        onSelected: (action) {
                          final repo = ref.read(taskRepositoryProvider);
                          switch (action) {
                            case 'focus':
                              repo.toggleFocus(task.id);
                              break;
                            case 'tomorrow':
                              repo.snoozeTask(task.id, DateTime.now().add(const Duration(days: 1)));
                              break;
                            case 'delete':
                              repo.deleteTask(task.id);
                              break;
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'focus',
                            child: Row(
                              children: [
                                Icon(LucideIcons.target, size: 14, color: context.secondaryText),
                                const SizedBox(width: 8),
                                Text(task.isFocus ? 'Remove from Focus' : 'Set as Today Focus',
                                    style: AppTypography.bodySmall(context.primaryText)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'tomorrow',
                            child: Row(
                              children: [
                                Icon(LucideIcons.arrowRightCircle, size: 14, color: context.secondaryText),
                                const SizedBox(width: 8),
                                Text('Snooze to Tomorrow', style: AppTypography.bodySmall(context.primaryText)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(LucideIcons.trash2, size: 14, color: context.colorScheme.error),
                                const SizedBox(width: 8),
                                Text('Delete', style: AppTypography.bodySmall(context.colorScheme.error)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Drag handle for reordering
                      if (dragIndex != null)
                        ReorderableDragStartListener(
                          index: dragIndex!,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(LucideIcons.gripVertical, size: 16, color: context.mutedText),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
