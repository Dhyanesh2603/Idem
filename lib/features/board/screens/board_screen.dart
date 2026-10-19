import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/models/task_priority.dart';
import '../../tasks/providers/task_providers.dart';
import '../../tasks/widgets/task_detail_sheet.dart';
import '../../categories/providers/category_providers.dart';
import '../../../database/database_provider.dart';

enum KanbanStage {
  backlog('Backlog', LucideIcons.archive, 'Unscheduled & ideas'),
  todo('To Do', LucideIcons.listTodo, 'Ready for execution'),
  inProgress('In Progress', LucideIcons.zap, 'Active deep focus'),
  done('Done', LucideIcons.checkCheck, 'Completed accomplishments');

  final String label;
  final IconData icon;
  final String subtitle;
  const KanbanStage(this.label, this.icon, this.subtitle);
}

class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  String? _selectedCategoryId;
  String _searchQuery = '';

  KanbanStage _getStageForTask(TaskModel task) {
    if (task.isCompleted) return KanbanStage.done;
    if (task.isFocus) return KanbanStage.inProgress;
    if (task.isScheduledToday || task.isOverdue || task.priority == TaskPriority.urgent || task.priority == TaskPriority.high) {
      return KanbanStage.todo;
    }
    return KanbanStage.backlog;
  }

  Future<void> _moveTaskStage(TaskModel task, KanbanStage targetStage) async {
    final repo = ref.read(taskRepositoryProvider);
    final now = DateTime.now();

    switch (targetStage) {
      case KanbanStage.backlog:
        await repo.updateTask(task.copyWith(
          isCompleted: false,
          isFocus: false,
          clearDeadline: true,
        ));
        break;
      case KanbanStage.todo:
        await repo.updateTask(task.copyWith(
          isCompleted: false,
          isFocus: false,
          deadline: DateTime(now.year, now.month, now.day, 23, 59),
        ));
        break;
      case KanbanStage.inProgress:
        await repo.updateTask(task.copyWith(
          isCompleted: false,
          isFocus: true,
          deadline: DateTime(now.year, now.month, now.day, 23, 59),
        ));
        break;
      case KanbanStage.done:
        await repo.toggleTaskCompletion(task.id);
        break;
    }
  }

  void _quickAddTask(KanbanStage stage) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        title: Text('Add to ${stage.label}', style: AppTypography.titleMedium(context.primaryText)),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: AppTypography.bodyMedium(context.primaryText),
          decoration: InputDecoration(
            hintText: 'Task title...',
            hintStyle: AppTypography.bodyMedium(context.mutedText),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              Navigator.of(ctx).pop();
              _createTaskForStage(val.trim(), stage);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop();
                _createTaskForStage(titleController.text.trim(), stage);
              }
            },
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTaskForStage(String title, KanbanStage stage) async {
    final repo = ref.read(taskRepositoryProvider);
    final now = DateTime.now();

    final task = await repo.createTask(
      title: title,
      categoryId: _selectedCategoryId,
      deadline: (stage == KanbanStage.todo || stage == KanbanStage.inProgress)
          ? DateTime(now.year, now.month, now.day, 23, 59)
          : null,
      isFocus: stage == KanbanStage.inProgress,
    );
    if (stage == KanbanStage.done) {
      await repo.toggleTaskCompletion(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(filteredTasksStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    final allTasks = tasksAsync.asData?.value ?? [];
    final categories = categoriesAsync.asData?.value ?? [];

    final filteredTasks = allTasks.where((t) {
      if (t.isDeleted) return false;
      if (_selectedCategoryId != null && t.categoryId != _selectedCategoryId) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return t.title.toLowerCase().contains(q) || t.description.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WORKSTATION VISUALIZER',
                          style: AppTypography.labelMedium(context.mutedText).copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kanban Board',
                          style: AppTypography.displayLarge(context.primaryText),
                        ),
                      ],
                    ),
                  ),
                  // Search Box
                  Container(
                    width: 200,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.border, width: 0.8),
                    ),
                    child: TextField(
                      style: AppTypography.bodySmall(context.primaryText),
                      decoration: InputDecoration(
                        hintText: 'Filter cards...',
                        hintStyle: AppTypography.bodySmall(context.mutedText),
                        prefixIcon: Icon(LucideIcons.search, size: 14, color: context.mutedText),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                ],
              ),
            ),

            // Category Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              child: Row(
                children: [
                  _filterChip('All', _selectedCategoryId == null, () {
                    setState(() => _selectedCategoryId = null);
                  }),
                  ...categories.map((cat) {
                    final isSel = _selectedCategoryId == cat.id;
                    return _filterChip(cat.name, isSel, () {
                      setState(() => _selectedCategoryId = cat.id);
                    });
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 4-Column Board
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: KanbanStage.values.map((stage) {
                  final stageTasks = filteredTasks.where((t) => _getStageForTask(t) == stage).toList();
                  return _KanbanColumn(
                    stage: stage,
                    tasks: stageTasks,
                    onMoveTask: _moveTaskStage,
                    onAddTask: () => _quickAddTask(stage),
                    onTapTask: (task) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => TaskDetailSheet(taskId: task.id),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? context.accentSubtle : context.secondarySurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? context.accent : context.border,
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.code(
              isSelected ? context.accent : context.secondaryText,
              fontSize: 11,
            ).copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400),
          ),
        ),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final KanbanStage stage;
  final List<TaskModel> tasks;
  final Future<void> Function(TaskModel, KanbanStage) onMoveTask;
  final VoidCallback onAddTask;
  final ValueChanged<TaskModel> onTapTask;

  const _KanbanColumn({
    required this.stage,
    required this.tasks,
    required this.onMoveTask,
    required this.onAddTask,
    required this.onTapTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.border, width: 0.8)),
            ),
            child: Row(
              children: [
                Icon(stage.icon, size: 15, color: context.accent),
                const SizedBox(width: 8),
                Text(
                  stage.label.toUpperCase(),
                  style: AppTypography.code(context.primaryText, fontSize: 11).copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.secondarySurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.border, width: 0.6),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: AppTypography.code(context.mutedText, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),

          // Cards List
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No cards in ${stage.label.toLowerCase()}',
                        style: AppTypography.bodySmall(context.mutedText),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: tasks.length,
                    itemBuilder: (context, i) {
                      final task = tasks[i];
                      return _KanbanCard(
                        task: task,
                        currentStage: stage,
                        onMove: (target) => onMoveTask(task, target),
                        onTap: () => onTapTask(task),
                      );
                    },
                  ),
          ),

          // Quick Add Card Button
          Padding(
            padding: const EdgeInsets.all(8),
            child: InkWell(
              onTap: onAddTask,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: context.secondarySurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.border, width: 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.plus, size: 13, color: context.mutedText),
                    const SizedBox(width: 6),
                    Text(
                      'Add Card',
                      style: AppTypography.labelSmall(context.mutedText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KanbanCard extends StatelessWidget {
  final TaskModel task;
  final KanbanStage currentStage;
  final ValueChanged<KanbanStage> onMove;
  final VoidCallback onTap;

  const _KanbanCard({
    required this.task,
    required this.currentStage,
    required this.onMove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color priorityColor;
    String priorityLabel;
    switch (task.priority) {
      case TaskPriority.urgent:
        priorityColor = AppColors.error;
        priorityLabel = 'P1 Urgent';
        break;
      case TaskPriority.high:
        priorityColor = AppColors.warning;
        priorityLabel = 'P2 High';
        break;
      case TaskPriority.medium:
        priorityColor = const Color(0xFF3B82F6);
        priorityLabel = 'P3 Med';
        break;
      case TaskPriority.low:
        priorityColor = context.mutedText;
        priorityLabel = 'P4 Low';
        break;
      case TaskPriority.none:
        priorityColor = context.mutedText;
        priorityLabel = 'No Priority';
        break;
    }

    final currentIndex = KanbanStage.values.indexOf(currentStage);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.secondarySurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: task.isFocus ? context.accent : context.border,
          width: task.isFocus ? 1.2 : 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tags
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: priorityColor.withValues(alpha: 0.4), width: 0.6),
                      ),
                      child: Text(
                        priorityLabel,
                        style: AppTypography.code(priorityColor, fontSize: 9).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (task.estimatedMinutes > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '~${task.estimatedMinutes}m',
                        style: AppTypography.code(context.mutedText, fontSize: 9),
                      ),
                    ],
                    const Spacer(),
                    if (task.isFocus)
                      Icon(LucideIcons.target, size: 13, color: context.accent),
                  ],
                ),
                const SizedBox(height: 8),

                // Card Title
                Text(
                  task.title,
                  style: AppTypography.bodyMedium(context.primaryText).copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: context.mutedText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: AppTypography.bodySmall(context.secondaryText),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 10),

                // Bottom Movement Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Move Left
                    if (currentIndex > 0)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        icon: const Icon(LucideIcons.arrowLeft, size: 14),
                        color: context.mutedText,
                        tooltip: 'Move to ${KanbanStage.values[currentIndex - 1].label}',
                        onPressed: () => onMove(KanbanStage.values[currentIndex - 1]),
                      )
                    else
                      const SizedBox(width: 24),

                    // Quick Stage Switch Dropdown Menu
                    PopupMenuButton<KanbanStage>(
                      icon: Icon(LucideIcons.moreHorizontal, size: 14, color: context.mutedText),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      color: context.surface,
                      onSelected: onMove,
                      itemBuilder: (ctx) => KanbanStage.values
                          .where((s) => s != currentStage)
                          .map(
                            (s) => PopupMenuItem(
                              value: s,
                              child: Row(
                                children: [
                                  Icon(s.icon, size: 14, color: context.accent),
                                  const SizedBox(width: 8),
                                  Text('Move to ${s.label}', style: AppTypography.bodySmall(context.primaryText)),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),

                    // Move Right
                    if (currentIndex < KanbanStage.values.length - 1)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        icon: const Icon(LucideIcons.arrowRight, size: 14),
                        color: context.accent,
                        tooltip: 'Move to ${KanbanStage.values[currentIndex + 1].label}',
                        onPressed: () => onMove(KanbanStage.values[currentIndex + 1]),
                      )
                    else
                      const SizedBox(width: 24),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
