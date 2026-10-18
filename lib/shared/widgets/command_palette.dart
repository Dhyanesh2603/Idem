import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../features/tasks/models/task_model.dart';
import '../../features/tasks/providers/task_providers.dart';
import '../../features/tasks/widgets/task_detail_sheet.dart';
import '../../features/today/widgets/daily_planning_sheet.dart';
import '../../features/categories/widgets/create_category_sheet.dart';
import '../../features/sync/providers/sync_providers.dart';

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => const CommandPalette(),
    );
  }

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(filteredTasksStreamProvider);
    final allTasks = tasksAsync.asData?.value ?? [];

    final matchingTasks = _query.isEmpty
        ? <TaskModel>[]
        : allTasks.where((t) {
            return t.title.toLowerCase().contains(_query.toLowerCase()) ||
                t.description.toLowerCase().contains(_query.toLowerCase());
          }).take(6).toList();

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 580,
          constraints: const BoxConstraints(maxHeight: 520),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Input Header
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(LucideIcons.search, size: 18, color: context.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        style: AppTypography.bodyMedium(context.primaryText),
                        decoration: InputDecoration(
                          hintText: 'Type a task, screen, or command...',
                          hintStyle: AppTypography.bodyMedium(context.mutedText),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (val) => setState(() => _query = val.trim()),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.secondarySurface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: context.border, width: 0.8),
                      ),
                      child: Text('ESC', style: AppTypography.code(context.mutedText, fontSize: 10)),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: context.border),

              // Results or Quick Actions List
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shrinkWrap: true,
                  children: [
                    if (_query.isNotEmpty && matchingTasks.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Text(
                          'MATCHING TASKS',
                          style: AppTypography.code(context.mutedText, fontSize: 10).copyWith(letterSpacing: 1.2),
                        ),
                      ),
                      ...matchingTasks.map((t) {
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            t.isCompleted ? LucideIcons.checkCircle : LucideIcons.circle,
                            size: 15,
                            color: t.isCompleted ? context.accent : context.mutedText,
                          ),
                          title: Text(t.title, style: AppTypography.bodySmall(context.primaryText)),
                          subtitle: t.deadline != null
                              ? Text('Due: ${t.deadline!.month}/${t.deadline!.day}', style: AppTypography.code(context.mutedText, fontSize: 9))
                              : null,
                          onTap: () {
                            Navigator.of(context).pop();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => TaskDetailSheet(taskId: t.id),
                            );
                          },
                        );
                      }),
                      Divider(height: 16, color: context.border),
                    ],

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(
                        'QUICK ACTIONS',
                        style: AppTypography.code(context.mutedText, fontSize: 10).copyWith(letterSpacing: 1.2),
                      ),
                    ),
                    _CommandItem(
                      icon: LucideIcons.sparkles,
                      title: 'Start Daily Planning Session',
                      shortcut: 'Plan Day',
                      onTap: () {
                        Navigator.of(context).pop();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const DailyPlanningSheet(),
                        );
                      },
                    ),
                    _CommandItem(
                      icon: LucideIcons.target,
                      title: 'Open Focus Mode Workstation',
                      shortcut: '⌘F',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/focus');
                      },
                    ),
                    _CommandItem(
                      icon: LucideIcons.tag,
                      title: 'Create New Category',
                      shortcut: '+ Cat',
                      onTap: () {
                        Navigator.of(context).pop();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const CreateCategorySheet(),
                        );
                      },
                    ),
                    _CommandItem(
                      icon: LucideIcons.refreshCw,
                      title: 'Trigger Cloud Synchronization',
                      shortcut: 'Sync',
                      onTap: () {
                        Navigator.of(context).pop();
                        ref.read(syncEngineProvider).synchronize();
                      },
                    ),
                    _CommandItem(
                      icon: LucideIcons.sunMedium,
                      title: 'Toggle Theme (Dark / Warm Paper)',
                      shortcut: 'Theme',
                      onTap: () {
                        Navigator.of(context).pop();
                        ref.read(themeNotifierProvider.notifier).toggleTheme();
                      },
                    ),

                    Divider(height: 16, color: context.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(
                        'NAVIGATION',
                        style: AppTypography.code(context.mutedText, fontSize: 10).copyWith(letterSpacing: 1.2),
                      ),
                    ),
                    _CommandItem(
                      icon: LucideIcons.sun,
                      title: 'Go to Today',
                      shortcut: '⌘1',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/today');
                      },
                    ),
                    _CommandItem(
                      icon: LucideIcons.inbox,
                      title: 'Go to Inbox',
                      shortcut: '⌘2',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/inbox');
                      },
                    ),
                    _CommandItem(
                      icon: LucideIcons.calendar,
                      title: 'Go to Schedule & Calendar',
                      shortcut: '⌘3',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/calendar');
                      },
                    ),
                    _CommandItem(
                      icon: LucideIcons.checkSquare,
                      title: 'Go to Reflection & Review',
                      shortcut: '⌘4',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/review');
                      },
                    ),
                    _CommandItem(
                      icon: LucideIcons.settings,
                      title: 'Go to Settings & Sync History',
                      shortcut: '⌘5',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/settings');
                      },
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

class _CommandItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String shortcut;
  final VoidCallback onTap;

  const _CommandItem({
    required this.icon,
    required this.title,
    required this.shortcut,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 16, color: context.secondaryText),
      title: Text(title, style: AppTypography.bodySmall(context.primaryText)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: context.secondarySurface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.border, width: 0.8),
        ),
        child: Text(shortcut, style: AppTypography.code(context.mutedText, fontSize: 10)),
      ),
      onTap: onTap,
    );
  }
}
