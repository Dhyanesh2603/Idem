import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/today_task_item.dart';
import '../widgets/daily_planning_sheet.dart';
import '../widgets/quick_add_bar.dart';
import '../../tasks/providers/task_providers.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayTasksAsync = ref.watch(todayTasksStreamProvider);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Typographical Calm Header
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 28, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr.toUpperCase(),
                          style: AppTypography.labelMedium(context.mutedText).copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Today',
                          style: AppTypography.displayLarge(context.primaryText),
                        ),
                      ],
                    ),
                  ),
                  // Daily Planning Session Button
                  OutlinedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const DailyPlanningSheet(),
                      );
                    },
                    icon: Icon(LucideIcons.sparkles, size: 15, color: context.accent),
                    label: Text(
                      'Plan Day',
                      style: AppTypography.labelMedium(context.primaryText),
                    ),
                  ),
                ],
              ),
            ),

            // Inline Quick Add Input Bar
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: QuickAddBar(isTodayDefault: true),
            ),

            const SizedBox(height: 8),

            // Task List
            Expanded(
              child: todayTasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return _EmptyTodayState();
                  }

                  final focusTasks = tasks.where((t) => t.isFocus).toList();
                  final regularTasks = tasks.where((t) => !t.isFocus).toList();

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    children: [
                      if (focusTasks.isNotEmpty) ...[
                        _SectionHeader(
                          title: "TODAY'S FOCUS",
                          count: focusTasks.length,
                          accentColor: context.accent,
                        ),
                        ...focusTasks.map((t) => TodayTaskItem(key: ValueKey(t.id), task: t)),
                        const SizedBox(height: 24),
                      ],
                      if (regularTasks.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'SCHEDULED',
                          count: regularTasks.length,
                        ),
                        ...regularTasks.map((t) => TodayTaskItem(key: ValueKey(t.id), task: t)),
                      ],
                    ],
                  );
                },
                loading: () => const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Unable to load tasks: $err',
                    style: AppTypography.bodySmall(context.mutedText),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color? accentColor;

  const _SectionHeader({
    required this.title,
    required this.count,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Text(
            title,
            style: AppTypography.labelSmall(accentColor ?? context.mutedText).copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: context.secondarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: AppTypography.code(context.mutedText, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTodayState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.sun, size: 36, color: context.mutedText),
          const SizedBox(height: 16),
          Text(
            'Clear Horizon',
            style: AppTypography.titleMedium(context.primaryText),
          ),
          const SizedBox(height: 6),
          Text(
            'No tasks scheduled for today. Add a task above or plan your day.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(context.mutedText),
          ),
        ],
      ),
    );
  }
}
