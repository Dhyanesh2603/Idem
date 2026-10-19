import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final bool isEmbedded;
  const BoardScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _showSearch = false;
  late final PageController _pageController;
  int _mobileActiveStageIndex = 1; // Default to 'To Do'

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _mobileActiveStageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        final bodyContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (only if not embedded inside TodayScreen)
            if (!widget.isEmbedded)
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
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
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kanban Board',
                            style: AppTypography.displayLarge(context.primaryText).copyWith(
                              fontSize: isMobile ? 26 : 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Filter cards',
                      icon: Icon(
                        _showSearch ? LucideIcons.x : LucideIcons.search,
                        size: 18,
                        color: _showSearch ? context.accent : context.mutedText,
                      ),
                      onPressed: () {
                        setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) _searchQuery = '';
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Optional Search Bar
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.border, width: 0.8),
                  ),
                  child: TextField(
                    autofocus: true,
                    style: AppTypography.bodySmall(context.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Filter cards by title or notes...',
                      hintStyle: AppTypography.bodySmall(context.mutedText),
                      prefixIcon: Icon(LucideIcons.search, size: 14, color: context.mutedText),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ),
              ),

            // Category Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
            const SizedBox(height: 6),

            // Mobile-Optimized Stage Switcher & Drop Targets Bar
            if (isMobile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.secondarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.border, width: 0.8),
                  ),
                  child: Row(
                    children: KanbanStage.values.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final stage = entry.value;
                      final isSelected = _mobileActiveStageIndex == idx;
                      final count = filteredTasks.where((t) => _getStageForTask(t) == stage).length;

                      // Each stage tab is ALSO a DragTarget so cards can be dropped directly onto other stage tabs!
                      return Expanded(
                        child: DragTarget<TaskModel>(
                          onWillAcceptWithDetails: (details) => true,
                          onAcceptWithDetails: (details) {
                            HapticFeedback.mediumImpact();
                            _moveTaskStage(details.data, stage);
                          },
                          builder: (context, candidateData, rejectedData) {
                            final isDragHovered = candidateData.isNotEmpty;
                            return InkWell(
                              onTap: () {
                                _pageController.animateToPage(
                                  idx,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDragHovered
                                      ? context.accent.withValues(alpha: 0.25)
                                      : isSelected
                                          ? context.surface
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: isDragHovered
                                      ? Border.all(color: context.accent, width: 1.2)
                                      : isSelected
                                          ? Border.all(color: context.border, width: 0.8)
                                          : null,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          stage.icon,
                                          size: 12,
                                          color: isSelected ? context.accent : context.mutedText,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          stage.label,
                                          style: AppTypography.code(
                                            isSelected ? context.primaryText : context.mutedText,
                                            fontSize: 10,
                                          ).copyWith(
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$count',
                                      style: AppTypography.code(
                                        isSelected ? context.accent : context.mutedText,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // Kanban Body: Snapping PageView on Mobile vs Horizontal ListView on Desktop
            Expanded(
              child: isMobile
                  ? PageView.builder(
                      controller: _pageController,
                      physics: const PageScrollPhysics(),
                      onPageChanged: (idx) {
                        setState(() => _mobileActiveStageIndex = idx);
                      },
                      itemCount: KanbanStage.values.length,
                      itemBuilder: (context, idx) {
                        final stage = KanbanStage.values[idx];
                        final stageTasks = filteredTasks.where((t) => _getStageForTask(t) == stage).toList();
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: _KanbanColumn(
                            stage: stage,
                            tasks: stageTasks,
                            isMobile: true,
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
                          ),
                        );
                      },
                    )
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      children: KanbanStage.values.map((stage) {
                        final stageTasks = filteredTasks.where((t) => _getStageForTask(t) == stage).toList();
                        return _KanbanColumn(
                          stage: stage,
                          tasks: stageTasks,
                          isMobile: false,
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
        );

        if (widget.isEmbedded) {
          return bodyContent;
        }

        return Scaffold(
          backgroundColor: context.background,
          body: SafeArea(child: bodyContent),
        );
      },
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
  final bool isMobile;
  final Future<void> Function(TaskModel, KanbanStage) onMoveTask;
  final VoidCallback onAddTask;
  final ValueChanged<TaskModel> onTapTask;

  const _KanbanColumn({
    required this.stage,
    required this.tasks,
    required this.isMobile,
    required this.onMoveTask,
    required this.onAddTask,
    required this.onTapTask,
  });

  @override
  Widget build(BuildContext context) {
    // Column acts as a DragTarget for tasks dropped into this stage
    return DragTarget<TaskModel>(
      onWillAcceptWithDetails: (details) => details.data.id.isNotEmpty,
      onAcceptWithDetails: (details) {
        HapticFeedback.mediumImpact();
        onMoveTask(details.data, stage);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isMobile ? double.infinity : 290,
          margin: EdgeInsets.only(right: isMobile ? 0 : 14),
          decoration: BoxDecoration(
            color: isHovered
                ? context.accent.withValues(alpha: 0.08)
                : context.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered ? context.accent : context.border,
              width: isHovered ? 1.5 : 0.8,
            ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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

              // Drop Hover Indicator Banner
              if (isHovered)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: context.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: context.accent, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      'Drop card to move to ${stage.label}',
                      style: AppTypography.code(context.accent, fontSize: 11).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Cards List (Independently scrollable on vertical axis)
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.inbox, size: 24, color: context.mutedText.withValues(alpha: 0.4)),
                              const SizedBox(height: 8),
                              Text(
                                'No cards in ${stage.label.toLowerCase()}',
                                style: AppTypography.bodySmall(context.mutedText),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Drag cards here or add new',
                                style: AppTypography.code(context.mutedText, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        physics: const AlwaysScrollableScrollPhysics(),
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
      },
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

    // Standard card presentation widget
    final cardContent = Container(
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
                // Top Tags with Drag Handle hint
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
                    if (task.isFocus) ...[
                      Icon(LucideIcons.target, size: 13, color: context.accent),
                      const SizedBox(width: 4),
                    ],
                    Icon(LucideIcons.gripVertical, size: 13, color: context.mutedText.withValues(alpha: 0.5)),
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
                    // Move Left Button
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

                    // Move Right Button
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

    // Card Wrapped in LongPressDraggable for Drag and Drop across columns and stages
    return LongPressDraggable<TaskModel>(
      data: task,
      delay: const Duration(milliseconds: 140),
      hapticFeedbackOnStart: true,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.rotate(
          angle: 0.04,
          child: Container(
            width: 260,
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.accent, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        priorityLabel,
                        style: AppTypography.code(priorityColor, fontSize: 9).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    Icon(LucideIcons.move, size: 13, color: context.accent),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  task.title,
                  style: AppTypography.bodyMedium(context.primaryText).copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: cardContent,
      ),
      child: cardContent,
    );
  }
}
