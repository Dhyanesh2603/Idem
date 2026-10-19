import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/widgets/task_detail_sheet.dart';
import '../../categories/providers/category_providers.dart';
import '../../../database/database_provider.dart';

class TimeBlockTimeline extends ConsumerWidget {
  final List<TaskModel> todayTasks;

  const TimeBlockTimeline({
    super.key,
    required this.todayTasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final categories = categoriesAsync.asData?.value ?? [];

    // Calculate total committed hours
    final totalMinutesCommitted = todayTasks.fold<int>(0, (acc, t) {
      return acc + (t.estimatedMinutes > 0 ? t.estimatedMinutes : 30);
    });
    final committedHours = totalMinutesCommitted ~/ 60;
    final committedMinutes = totalMinutesCommitted % 60;
    final freeHours = (12 - (totalMinutesCommitted / 60)).clamp(0.0, 12.0);

    // Hours to display (8 AM to 9 PM)
    final hours = List.generate(14, (i) => 8 + i); // 8 to 21

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Capacity Summary Metric Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.border, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.clock, size: 14, color: context.accent),
                  const SizedBox(width: 8),
                  Text(
                    'SCHEDULED: ${committedHours}h ${committedMinutes}m',
                    style: AppTypography.code(context.primaryText, fontSize: 11).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: freeHours > 2 ? Colors.greenAccent : Colors.amberAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '~${freeHours.toStringAsFixed(1)}h AVAILABLE CAPACITY',
                    style: AppTypography.code(context.mutedText, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Hourly Grid List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: hours.length,
          itemBuilder: (context, idx) {
            final hour = hours[idx];
            final hourDate = DateTime(now.year, now.month, now.day, hour, 0);
            final timeLabel = DateFormat('h a').format(hourDate);

            // Filter tasks slotted for this hour
            final tasksInSlot = todayTasks.where((t) {
              if (t.deadline == null) return false;
              return t.deadline!.hour == hour;
            }).toList();

            final isCurrentHour = now.hour == hour;

            return Container(
              constraints: const BoxConstraints(minHeight: 64),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isCurrentHour ? context.accent.withValues(alpha: 0.6) : context.border.withValues(alpha: 0.4),
                    width: isCurrentHour ? 1.5 : 0.8,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hour Label
                  SizedBox(
                    width: 64,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        timeLabel,
                        style: AppTypography.code(
                          isCurrentHour ? context.accent : context.mutedText,
                          fontSize: 11,
                        ).copyWith(fontWeight: isCurrentHour ? FontWeight.w700 : FontWeight.normal),
                      ),
                    ),
                  ),

                  // Slot Tasks or Empty Slot Target
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: tasksInSlot.isEmpty
                          ? InkWell(
                              onTap: () {
                                _showQuickScheduleDialog(context, ref, hour);
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '+ Block time slot',
                                  style: AppTypography.code(context.mutedText.withValues(alpha: 0.4), fontSize: 10),
                                ),
                              ),
                            )
                          : Column(
                              children: tasksInSlot.map((task) {
                                final category = task.categoryId != null
                                    ? categories.where((c) => c.id == task.categoryId).firstOrNull
                                    : null;
                                final catColor = category != null
                                    ? Color(int.parse(category.colorHex.replaceFirst('#', '0xFF')))
                                    : context.accent;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: context.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: catColor.withValues(alpha: 0.4), width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => TaskDetailSheet(taskId: task.id),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 3,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: catColor,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                task.title,
                                                style: AppTypography.bodySmall(context.primaryText).copyWith(
                                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                                ),
                                              ),
                                              if (task.estimatedMinutes > 0)
                                                Text(
                                                  '${task.estimatedMinutes} min duration',
                                                  style: AppTypography.code(context.mutedText, fontSize: 9),
                                                ),
                                            ],
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => ref.read(taskRepositoryProvider).toggleTaskCompletion(task.id),
                                          child: Icon(
                                            task.isCompleted ? LucideIcons.checkSquare : LucideIcons.square,
                                            size: 16,
                                            color: task.isCompleted ? context.accent : context.mutedText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showQuickScheduleDialog(BuildContext context, WidgetRef ref, int hour) {
    final now = DateTime.now();
    final targetTime = DateTime(now.year, now.month, now.day, hour, 0);
    final unassignedTasks = todayTasks.where((t) => t.deadline == null && !t.isCompleted).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        title: Text('Schedule Task for ${DateFormat('h:mm a').format(targetTime)}', style: AppTypography.titleMedium(context.primaryText)),
        content: SizedBox(
          width: 340,
          height: 260,
          child: unassignedTasks.isEmpty
              ? Center(child: Text('All today\'s tasks are already scheduled or completed.', style: AppTypography.bodySmall(context.mutedText)))
              : ListView.builder(
                  itemCount: unassignedTasks.length,
                  itemBuilder: (_, i) {
                    final t = unassignedTasks[i];
                    return ListTile(
                      title: Text(t.title, style: AppTypography.bodySmall(context.primaryText)),
                      onTap: () async {
                        final updated = t.copyWith(deadline: targetTime);
                        await ref.read(taskRepositoryProvider).updateTask(updated);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}
