import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/habit_providers.dart';

class DailyRitualsBar extends ConsumerWidget {
  const DailyRitualsBar({super.key});

  IconData _resolveIcon(String name) {
    switch (name) {
      case 'zap':
        return LucideIcons.zap;
      case 'inbox':
        return LucideIcons.inbox;
      case 'code':
        return LucideIcons.code;
      case 'activity':
        return LucideIcons.activity;
      case 'sunset':
        return LucideIcons.sunset;
      case 'book':
        return LucideIcons.bookOpen;
      default:
        return LucideIcons.checkCircle2;
    }
  }

  void _showAddHabitDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String timeOfDay = 'morning';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: context.surface,
            title: Text('New Daily Ritual', style: AppTypography.titleMedium(context.primaryText)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: AppTypography.bodyMedium(context.primaryText),
                  decoration: InputDecoration(
                    hintText: 'e.g. 30m LeetCode or Read 20 pages',
                    hintStyle: AppTypography.bodySmall(context.mutedText),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  style: AppTypography.bodyMedium(context.primaryText),
                  decoration: InputDecoration(
                    hintText: 'Description or intention...',
                    hintStyle: AppTypography.bodySmall(context.mutedText),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Time: ', style: AppTypography.bodySmall(context.mutedText)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: timeOfDay,
                      dropdownColor: context.surface,
                      items: const [
                        DropdownMenuItem(value: 'morning', child: Text('Morning')),
                        DropdownMenuItem(value: 'afternoon', child: Text('Afternoon')),
                        DropdownMenuItem(value: 'evening', child: Text('Evening')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => timeOfDay = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty) {
                    ref.read(habitsNotifierProvider.notifier).addHabit(
                          title: titleController.text.trim(),
                          description: descController.text.trim(),
                          timeOfDay: timeOfDay,
                          iconName: 'zap',
                        );
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Create Ritual'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsNotifierProvider);
    final notifier = ref.read(habitsNotifierProvider.notifier);

    final completedCount = habits.where((h) => h.isCompletedToday).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.flame, size: 14, color: Colors.orange.shade400),
                    const SizedBox(width: 6),
                    Text(
                      'DAILY RITUALS',
                      style: AppTypography.code(context.mutedText, fontSize: 10).copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '$completedCount/${habits.length} completed',
                      style: AppTypography.code(context.accent, fontSize: 10),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showAddHabitDialog(context, ref),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(LucideIcons.plusCircle, size: 14, color: context.mutedText),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Horizontal Scroll of Ritual Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: habits.map((h) {
                  final isDone = h.isCompletedToday;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => notifier.toggleHabit(h.id),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDone
                              ? context.accent.withValues(alpha: 0.12)
                              : context.secondarySurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDone ? context.accent : context.border,
                            width: isDone ? 1.0 : 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDone ? LucideIcons.checkCircle2 : _resolveIcon(h.iconName),
                              size: 13,
                              color: isDone ? context.accent : context.mutedText,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              h.title,
                              style: AppTypography.bodySmall(
                                isDone ? context.primaryText : context.secondaryText,
                              ).copyWith(
                                fontSize: 11,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                                decorationColor: context.mutedText,
                              ),
                            ),
                            if (h.streakCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: context.surface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.flame, size: 9, color: Colors.orange.shade400),
                                    Text(
                                      '${h.streakCount}d',
                                      style: AppTypography.code(Colors.orange.shade400, fontSize: 8),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
