import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../tasks/models/task_model.dart';

class ContributionHeatmap extends StatelessWidget {
  final List<TaskModel> allTasks;
  final int weeksToShow;

  const ContributionHeatmap({
    super.key,
    required this.allTasks,
    this.weeksToShow = 18,
  });

  Map<String, int> _computeDailyCompletions() {
    final map = <String, int>{};
    final fmt = DateFormat('yyyy-MM-dd');
    for (final t in allTasks) {
      if (t.isCompleted && t.completedAt != null) {
        final key = fmt.format(t.completedAt!);
        map[key] = (map[key] ?? 0) + 1;
      }
    }
    return map;
  }

  int _calculateCurrentStreak(Map<String, int> dailyCounts) {
    final fmt = DateFormat('yyyy-MM-dd');
    final now = DateTime.now();
    final todayKey = fmt.format(now);
    final yesterdayKey = fmt.format(now.subtract(const Duration(days: 1)));

    if ((dailyCounts[todayKey] ?? 0) == 0 && (dailyCounts[yesterdayKey] ?? 0) == 0) {
      return 0;
    }

    int streak = 0;
    var checkDate = (dailyCounts[todayKey] ?? 0) > 0 ? now : now.subtract(const Duration(days: 1));

    while (true) {
      final key = fmt.format(checkDate);
      if ((dailyCounts[key] ?? 0) > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int _calculateLongestStreak(Map<String, int> dailyCounts) {
    int maxStreak = 0;
    int currentRun = 0;
    final now = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');

    // Walk back 120 days
    for (int i = 120; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = fmt.format(d);
      if ((dailyCounts[key] ?? 0) > 0) {
        currentRun++;
        if (currentRun > maxStreak) maxStreak = currentRun;
      } else {
        currentRun = 0;
      }
    }
    return maxStreak;
  }

  Color _getColorForCount(int count, BuildContext context) {
    if (count == 0) return context.secondarySurface;
    if (count <= 2) return context.accent.withValues(alpha: 0.25);
    if (count <= 4) return context.accent.withValues(alpha: 0.50);
    if (count <= 6) return context.accent.withValues(alpha: 0.75);
    return context.accent;
  }

  @override
  Widget build(BuildContext context) {
    final dailyCounts = _computeDailyCompletions();
    final currentStreak = _calculateCurrentStreak(dailyCounts);
    final longestStreak = _calculateLongestStreak(dailyCounts);
    final totalCompleted = allTasks.where((t) => t.isCompleted).length;

    final now = DateTime.now();
    final daysToSunday = 7 - now.weekday;
    final gridEnd = now.add(Duration(days: daysToSunday));
    final gridStart = gridEnd.subtract(Duration(days: weeksToShow * 7 - 1));
    final fmt = DateFormat('yyyy-MM-dd');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Streaks (Responsive for mobile to prevent overflow)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 460;

              final titleSection = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.flame, size: 16, color: Colors.orange.shade400),
                      const SizedBox(width: 8),
                      Text(
                        'ACTIVITY HEATMAP',
                        style: AppTypography.code(context.mutedText, fontSize: 10).copyWith(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalCompleted Lifetime Completions',
                    style: AppTypography.titleMedium(context.primaryText).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              );

              final streakBadges = Row(
                mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  isNarrow
                      ? Expanded(
                          child: _StreakBadge(
                            label: 'Current Streak',
                            value: '$currentStreak days',
                            icon: LucideIcons.zap,
                            color: context.accent,
                          ),
                        )
                      : _StreakBadge(
                          label: 'Current Streak',
                          value: '$currentStreak days',
                          icon: LucideIcons.zap,
                          color: context.accent,
                        ),
                  const SizedBox(width: 10),
                  isNarrow
                      ? Expanded(
                          child: _StreakBadge(
                            label: 'Best Streak',
                            value: '$longestStreak days',
                            icon: LucideIcons.trophy,
                            color: Colors.amber.shade400,
                          ),
                        )
                      : _StreakBadge(
                          label: 'Best Streak',
                          value: '$longestStreak days',
                          icon: LucideIcons.trophy,
                          color: Colors.amber.shade400,
                        ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleSection,
                    const SizedBox(height: 12),
                    streakBadges,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: titleSection),
                  streakBadges,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Horizontal Scrolling Contribution Grid
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(weeksToShow, (weekIdx) {
                    final weekStart = gridStart.add(Duration(days: weekIdx * 7));
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Column(
                        children: List.generate(7, (dayIdx) {
                          final cellDate = weekStart.add(Duration(days: dayIdx));
                          if (cellDate.isAfter(now)) {
                            return Container(
                              width: 13,
                              height: 13,
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            );
                          }

                          final dateKey = fmt.format(cellDate);
                          final count = dailyCounts[dateKey] ?? 0;
                          final color = _getColorForCount(count, context);

                          return Tooltip(
                            message: '${DateFormat('MMM d, yyyy').format(cellDate)}: $count tasks completed',
                            child: Container(
                              width: 13,
                              height: 13,
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2.5),
                                border: Border.all(
                                  color: count > 0 ? Colors.transparent : context.border.withValues(alpha: 0.5),
                                  width: 0.6,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),

                // Heatmap Legend
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Less', style: AppTypography.code(context.mutedText, fontSize: 9)),
                    const SizedBox(width: 6),
                    _legendBox(context.secondarySurface, context),
                    _legendBox(context.accent.withValues(alpha: 0.25), context),
                    _legendBox(context.accent.withValues(alpha: 0.50), context),
                    _legendBox(context.accent.withValues(alpha: 0.75), context),
                    _legendBox(context.accent, context),
                    const SizedBox(width: 6),
                    Text('More', style: AppTypography.code(context.mutedText, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendBox(Color color, BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: context.border.withValues(alpha: 0.5), width: 0.5),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StreakBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.secondarySurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppTypography.code(context.mutedText, fontSize: 8)),
              Text(
                value,
                style: AppTypography.code(context.primaryText, fontSize: 11).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
