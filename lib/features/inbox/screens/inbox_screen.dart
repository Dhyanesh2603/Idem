import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../today/widgets/quick_add_bar.dart';
import '../../today/widgets/today_task_item.dart';
import '../../tasks/providers/task_providers.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxTasksAsync = ref.watch(inboxTasksStreamProvider);

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 28, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CAPTURE & TRIAGE',
                    style: AppTypography.labelMedium(context.mutedText).copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Inbox',
                    style: AppTypography.displayLarge(context.primaryText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Temporary holding area. Capture freely without forced categorization.',
                    style: AppTypography.bodySmall(context.secondaryText),
                  ),
                ],
              ),
            ),

            // Quick capture bar (captures unscheduled to inbox)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: QuickAddBar(isTodayDefault: false),
            ),

            const SizedBox(height: 8),

            // Task list
            Expanded(
              child: inboxTasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.inbox, size: 36, color: context.mutedText),
                          const SizedBox(height: 16),
                          Text(
                            'Inbox Zero',
                            style: AppTypography.titleMedium(context.primaryText),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'All thoughts and capture items have been organized.',
                            style: AppTypography.bodyMedium(context.mutedText),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: tasks.length,
                    itemBuilder: (ctx, i) {
                      final task = tasks[i];
                      return TodayTaskItem(key: ValueKey(task.id), task: task);
                    },
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
                    'Error: $err',
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
