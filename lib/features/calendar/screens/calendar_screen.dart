import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../today/widgets/today_task_item.dart';
import '../../tasks/providers/task_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final tasksForDateAsync = ref.watch(tasksForDateStreamProvider(_selectedDate));
    final allTasksAsync = ref.watch(filteredTasksStreamProvider);
    final allTasks = allTasksAsync.asData?.value ?? [];

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(14, (i) => weekStart.add(Duration(days: i)));

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 28, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedDate).toUpperCase(),
                    style: AppTypography.labelMedium(context.mutedText).copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Schedule',
                    style: AppTypography.displayLarge(context.primaryText),
                  ),
                ],
              ),
            ),

            // Horizontal Date Strip with Workload Load-Balancer Indicators
            SizedBox(
              height: 82,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: weekDays.length,
                itemBuilder: (ctx, i) {
                  final day = weekDays[i];
                  final isSelected = day.year == _selectedDate.year &&
                      day.month == _selectedDate.month &&
                      day.day == _selectedDate.day;
                  final isToday = day.year == now.year &&
                      day.month == now.month &&
                      day.day == now.day;

                  final count = allTasks.where((t) {
                    if (t.deadline == null || t.isCompleted || t.isDeleted) return false;
                    return t.deadline!.year == day.year &&
                        t.deadline!.month == day.month &&
                        t.deadline!.day == day.day;
                  }).length;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = day),
                    child: Container(
                      width: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.accentSubtle.withValues(alpha: 0.25)
                            : context.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? context.accent : context.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('E').format(day).toUpperCase(),
                            style: AppTypography.labelSmall(
                              isSelected ? context.accent : context.mutedText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${day.day}',
                            style: AppTypography.titleMedium(
                              isSelected ? context.primaryText : context.secondaryText,
                            ).copyWith(
                              fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Workload dot indicator
                          if (count > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: count > 4 ? context.colorScheme.error : context.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                if (count > 2) ...[
                                  const SizedBox(width: 2),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: count > 4 ? context.colorScheme.error : context.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            )
                          else
                            const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Tasks for selected date
            Expanded(
              child: tasksForDateAsync.when(
                data: (tasks) {
                  final activeTasks = tasks.where((t) => !t.isDeleted).toList();

                  // Deadline Load Balancer warning
                  final isOverloaded = activeTasks.length > 5;

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      if (isOverloaded) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: context.secondarySurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.border, width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.scale, size: 16, color: context.colorScheme.error),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Heavy workload (${activeTasks.length} tasks). Use Smart Snooze to balance your schedule.',
                                  style: AppTypography.bodySmall(context.primaryText),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (activeTasks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(LucideIcons.calendarCheck, size: 36, color: context.mutedText),
                                const SizedBox(height: 12),
                                Text(
                                  'Nothing scheduled for this day',
                                  style: AppTypography.titleMedium(context.primaryText),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Enjoy your open calendar or schedule a task.',
                                  style: AppTypography.bodySmall(context.mutedText),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...activeTasks.map((t) => TodayTaskItem(key: ValueKey(t.id), task: t)),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
