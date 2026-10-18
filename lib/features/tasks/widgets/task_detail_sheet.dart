import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../models/task_model.dart';
import '../models/task_priority.dart';
import '../models/recurring_rule.dart';
import '../providers/task_providers.dart';
import '../../categories/models/category_model.dart';
import '../../categories/providers/category_providers.dart';
import '../../../database/database_provider.dart';

class TaskDetailSheet extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailSheet({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<TaskDetailSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _subtaskController;
  TaskModel? _currentTask;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _subtaskController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _loadTask(TaskModel task) {
    if (!_isInit) {
      _currentTask = task;
      _titleController.text = task.title;
      _descController.text = task.description;
      _isInit = true;
    }
  }

  Future<void> _save() async {
    if (_currentTask == null) return;
    final repo = ref.read(taskRepositoryProvider);
    final updated = _currentTask!.copyWith(
      title: _titleController.text.trim().isEmpty ? _currentTask!.title : _titleController.text.trim(),
      description: _descController.text.trim(),
    );
    await repo.updateTask(updated);
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(filteredTasksStreamProvider);
    final allTasks = tasksAsync.asData?.value ?? [];
    final task = allTasks.where((t) => t.id == widget.taskId).firstOrNull;

    if (task == null && _currentTask == null) {
      return Container(
        height: 200,
        color: context.surface,
        child: Center(child: Text('Task not found', style: AppTypography.bodyMedium(context.mutedText))),
      );
    }

    if (task != null) {
      _loadTask(task);
    }

    final dependenciesAsync = ref.watch(taskDependenciesStreamProvider(widget.taskId));
    final dependencies = dependenciesAsync.asData?.value ?? [];
    final subtasksAsync = ref.watch(taskSubtasksStreamProvider(widget.taskId));
    final subtasks = subtasksAsync.asData?.value ?? [];
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final categories = categoriesAsync.asData?.value ?? [];

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: context.border, width: 1)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Task Details', style: AppTypography.labelLarge(context.mutedText)),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: () {
                    _save();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title input
            TextField(
              controller: _titleController,
              style: AppTypography.titleLarge(context.primaryText),
              decoration: const InputDecoration(
                hintText: 'Task Title',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
              onChanged: (_) => _save(),
            ),
            const SizedBox(height: 12),

            // Description input
            TextField(
              controller: _descController,
              maxLines: 4,
              style: AppTypography.bodyMedium(context.secondaryText),
              decoration: InputDecoration(
                hintText: 'Add notes or context...',
                hintStyle: AppTypography.bodyMedium(context.mutedText),
                filled: true,
                fillColor: context.isDarkMode ? AppColors.darkSecondarySurface : AppColors.lightSecondarySurface,
              ),
              onChanged: (_) => _save(),
            ),
            const SizedBox(height: 20),

            // Priority & Recurrence Row
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                // Priority picker
                _FilterChipButton<TaskPriority>(
                  label: _currentTask!.priority.displayName,
                  icon: LucideIcons.flag,
                  color: _currentTask!.priority.color,
                  items: TaskPriority.values,
                  itemLabel: (p) => p.displayName,
                  onSelect: (p) async {
                    setState(() => _currentTask = _currentTask!.copyWith(priority: p));
                    await _save();
                  },
                ),

                // Category picker
                _FilterChipButton<CategoryModel?>(
                  label: categories.where((c) => c.id == _currentTask!.categoryId).firstOrNull?.name ?? 'No Category',
                  icon: LucideIcons.tag,
                  color: context.secondaryText,
                  items: [null, ...categories],
                  itemLabel: (c) => c?.name ?? 'No Category',
                  onSelect: (c) async {
                    setState(() => _currentTask = _currentTask!.copyWith(
                      categoryId: c?.id,
                      clearCategoryId: c == null,
                    ));
                    await _save();
                  },
                ),

                // Deadline picker
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _currentTask!.deadline ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() => _currentTask = _currentTask!.copyWith(deadline: picked));
                      await _save();
                    }
                  },
                  icon: const Icon(LucideIcons.calendar, size: 14),
                  label: Text(
                    _currentTask!.deadline != null
                        ? DateFormat('MMM d').format(_currentTask!.deadline!)
                        : 'Set Deadline',
                    style: AppTypography.bodySmall(context.primaryText),
                  ),
                ),

                // Recurring rule picker
                _FilterChipButton<RecurringRule>(
                  label: _currentTask!.recurringRule.displayName,
                  icon: LucideIcons.repeat,
                  color: context.accent,
                  items: RecurringRule.values,
                  itemLabel: (r) => r.displayName,
                  onSelect: (r) async {
                    setState(() => _currentTask = _currentTask!.copyWith(recurringRule: r));
                    await _save();
                  },
                ),

                // Today's Focus Toggle
                FilterChip(
                  label: Text("Today's Focus", style: AppTypography.bodySmall(context.primaryText)),
                  selected: _currentTask!.isFocus,
                  selectedColor: context.accent.withValues(alpha: 0.2),
                  checkmarkColor: context.accent,
                  onSelected: (val) async {
                    setState(() => _currentTask = _currentTask!.copyWith(isFocus: val));
                    await _save();
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Subtasks & Action Checklist Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SUBTASKS & ACTION STEPS',
                  style: AppTypography.labelSmall(context.mutedText).copyWith(letterSpacing: 1.2),
                ),
                if (subtasks.isNotEmpty)
                  Text(
                    '${subtasks.where((s) => s.isCompleted).length} / ${subtasks.length} done',
                    style: AppTypography.code(context.accent, fontSize: 11),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            ...subtasks.map((st) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.secondarySurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: context.border, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          ref.read(taskRepositoryProvider).toggleTaskCompletion(st.id);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: st.isCompleted ? context.accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: st.isCompleted ? context.accent : context.border,
                              width: 1.2,
                            ),
                          ),
                          child: st.isCompleted
                              ? const Center(child: Icon(LucideIcons.check, size: 12, color: Colors.black))
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          st.title,
                          style: AppTypography.bodySmall(context.primaryText).copyWith(
                            decoration: st.isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor: context.mutedText,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 13),
                        color: context.mutedText,
                        onPressed: () {
                          ref.read(taskRepositoryProvider).deleteTask(st.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 6),
            // Inline add subtask input
            Container(
              height: 38,
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: context.border, width: 0.8),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(LucideIcons.plus, size: 14, color: context.mutedText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      style: AppTypography.bodySmall(context.primaryText),
                      decoration: InputDecoration(
                        hintText: 'Add an action step...',
                        hintStyle: AppTypography.bodySmall(context.mutedText),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (val) async {
                        final text = val.trim();
                        if (text.isEmpty) return;
                        _subtaskController.clear();
                        await ref.read(taskRepositoryProvider).createTask(
                          title: text,
                          parentTaskId: widget.taskId,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Dependencies section
            Text(
              'DEPENDENCIES',
              style: AppTypography.labelSmall(context.mutedText).copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),

            if (dependencies.isEmpty)
              Text('No prerequisite dependencies.', style: AppTypography.bodySmall(context.mutedText))
            else
              ...dependencies.map((dep) {
                final blocker = allTasks.where((t) => t.id == dep.blockerTaskId).firstOrNull;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.link2, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          blocker?.title ?? 'Prerequisite task',
                          style: AppTypography.bodySmall(context.secondaryText),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 14),
                        onPressed: () => ref.read(taskRepositoryProvider).removeDependency(dep.id),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showAddDependencyDialog(context, allTasks),
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text('Add Prerequisite Dependency'),
            ),

            const SizedBox(height: 24),

            // Delete action
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await ref.read(taskRepositoryProvider).deleteTask(widget.taskId);
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: Icon(LucideIcons.trash2, size: 14, color: context.colorScheme.error),
                label: Text('Delete Task', style: AppTypography.bodySmall(context.colorScheme.error)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDependencyDialog(BuildContext context, List<TaskModel> allTasks) {
    final eligible = allTasks.where((t) => t.id != widget.taskId).toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Select Prerequisite Task', style: AppTypography.titleMedium(context.primaryText)),
        content: SizedBox(
          width: 320,
          height: 250,
          child: ListView.builder(
            itemCount: eligible.length,
            itemBuilder: (_, i) {
              final t = eligible[i];
              return ListTile(
                title: Text(t.title, style: AppTypography.bodyMedium(context.primaryText)),
                onTap: () async {
                  await ref.read(taskRepositoryProvider).addDependency(
                        blockerTaskId: t.id,
                        blockedTaskId: widget.taskId,
                      );
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

class _FilterChipButton<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onSelect;

  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.items,
    required this.itemLabel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onSelect,
      itemBuilder: (_) => items.map((item) {
        return PopupMenuItem(
          value: item,
          child: Text(itemLabel(item), style: AppTypography.bodySmall(context.primaryText)),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: context.border, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(label, style: AppTypography.bodySmall(context.primaryText)),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 12, color: context.mutedText),
          ],
        ),
      ),
    );
  }
}
