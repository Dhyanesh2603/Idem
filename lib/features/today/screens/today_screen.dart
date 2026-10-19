import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/sync_status_badge.dart';
import '../widgets/today_task_item.dart';
import '../widgets/daily_planning_sheet.dart';
import '../widgets/quick_add_bar.dart';
import '../widgets/daily_intention_card.dart';
import '../widgets/shutdown_sheet.dart';
import '../widgets/time_block_timeline.dart';
import '../../../shared/widgets/command_palette.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/providers/task_providers.dart';
import '../../tasks/services/deadline_notification_service.dart';
import '../../categories/providers/category_providers.dart';
import '../../categories/widgets/create_category_sheet.dart';
import '../../../database/database_provider.dart';
import '../../habits/widgets/daily_rituals_bar.dart';
import '../../board/screens/board_screen.dart';
import '../widgets/auto_schedule_dialog.dart';

enum TodayViewMode { list, timeline, board }

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _showSearch = false;
  bool _showCompleted = true;
  TodayViewMode _viewMode = TodayViewMode.list;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayTasksAsync = ref.watch(todayTasksStreamProvider);
    final deadlineAlerts = ref.watch(deadlineAlertsProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final categories = categoriesAsync.asData?.value ?? [];

    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Typographical Calm Header with SyncStatusBadge & Actions
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;

                  final headerTitle = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateStr.toUpperCase(),
                        style: AppTypography.labelMedium(context.mutedText).copyWith(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Today',
                        style: AppTypography.displayLarge(context.primaryText).copyWith(
                          fontSize: isNarrow ? 28 : 34,
                        ),
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: headerTitle),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SyncStatusBadge(compact: true),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'Search tasks',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              icon: Icon(
                                _showSearch ? LucideIcons.x : LucideIcons.search,
                                size: 18,
                                color: _showSearch ? context.accent : context.mutedText,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showSearch = !_showSearch;
                                  if (!_showSearch) {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  }
                                });
                              },
                            ),
                            IconButton(
                              tooltip: 'Plan Day',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              icon: Icon(LucideIcons.sparkles, size: 18, color: context.accent),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => const DailyPlanningSheet(),
                                );
                              },
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'More actions',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              icon: Icon(LucideIcons.moreVertical, size: 18, color: context.mutedText),
                              color: context.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: context.border, width: 0.8),
                              ),
                              onSelected: (val) {
                                switch (val) {
                                  case 'command':
                                    CommandPalette.show(context);
                                    break;
                                  case 'autoschedule':
                                    final tasks = todayTasksAsync.asData?.value ?? [];
                                    AutoScheduleDialog.show(context, tasks);
                                    break;
                                  case 'shutdown':
                                    ShutdownSheet.show(context);
                                    break;
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'command',
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.command, size: 15, color: context.primaryText),
                                      const SizedBox(width: 10),
                                      Text('Command Palette (⌘K)', style: AppTypography.bodySmall(context.primaryText)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'autoschedule',
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.wand2, size: 15, color: context.accent),
                                      const SizedBox(width: 10),
                                      Text('Auto-Schedule Day', style: AppTypography.bodySmall(context.primaryText)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'shutdown',
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.sunset, size: 15, color: context.primaryText),
                                      const SizedBox(width: 10),
                                      Text('Evening Shutdown', style: AppTypography.bodySmall(context.primaryText)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: headerTitle),
                      Row(
                        children: [
                          const SyncStatusBadge(compact: true),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Search tasks',
                            icon: Icon(
                              _showSearch ? LucideIcons.x : LucideIcons.search,
                              size: 18,
                              color: _showSearch ? context.accent : context.mutedText,
                            ),
                            onPressed: () {
                              setState(() {
                                _showSearch = !_showSearch;
                                if (!_showSearch) {
                                  _searchQuery = '';
                                  _searchController.clear();
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Command Palette (⌘K)',
                            icon: Icon(LucideIcons.command, size: 17, color: context.mutedText),
                            onPressed: () => CommandPalette.show(context),
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            tooltip: 'Daily Shutdown Ritual',
                            icon: Icon(LucideIcons.sunset, size: 17, color: context.mutedText),
                            onPressed: () => ShutdownSheet.show(context),
                          ),
                          const SizedBox(width: 4),
                          OutlinedButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const DailyPlanningSheet(),
                              );
                            },
                            icon: Icon(LucideIcons.sparkles, size: 14, color: context.accent),
                            label: Text(
                              'Plan Day',
                              style: AppTypography.labelMedium(context.primaryText),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Algorithmic Day Orchestrator',
                            icon: Icon(LucideIcons.wand2, size: 16, color: context.accent),
                            onPressed: () {
                              final tasks = todayTasksAsync.asData?.value ?? [];
                              AutoScheduleDialog.show(context, tasks);
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            // Imminent Deadline Alert Banner (if applicable)
            if (deadlineAlerts.hasUrgentAlerts)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: InkWell(
                  onTap: () => _showDeadlineAlertDetails(context, deadlineAlerts),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertTriangle, size: 15, color: AppColors.warning),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            deadlineAlerts.overdueTasks.isNotEmpty
                                ? '${deadlineAlerts.overdueTasks.length} task(s) overdue • Tap to inspect'
                                : '${deadlineAlerts.dueTodayTasks.length} deadline(s) due today • Tap to inspect',
                            style: AppTypography.bodySmall(context.primaryText).copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(LucideIcons.chevronRight, size: 14, color: context.mutedText),
                      ],
                    ),
                  ),
                ),
              ),

            // Optional Search Input Bar
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.border, width: 0.8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: AppTypography.bodyMedium(context.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Search today’s tasks...',
                      hintStyle: AppTypography.bodySmall(context.mutedText),
                      prefixIcon: Icon(LucideIcons.search, size: 16, color: context.mutedText),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                ),
              ),

            // Daily Intention / North Star Focus Card
            const DailyIntentionCard(),

            // Daily Rituals & Habit Cadence Tracker
            const DailyRitualsBar(),

            // Daily Horizon Progress Bar (shows if any tasks exist)
            todayTasksAsync.maybeWhen(
              data: (tasks) {
                if (tasks.isEmpty) return const SizedBox.shrink();
                final total = tasks.length;
                final completed = tasks.where((t) => t.isCompleted).length;
                final active = tasks.where((t) => !t.isCompleted).toList();
                final focusCount = active.where((t) => t.isFocus).length;
                final progress = total > 0 ? (completed / total) : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.border, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '$completed of $total tasks completed • ${(progress * 100).toInt()}%',
                                style: AppTypography.labelSmall(context.primaryText).copyWith(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (focusCount > 0) ...[
                                  Icon(LucideIcons.target, size: 12, color: context.accent),
                                  const SizedBox(width: 4),
                                  Text('$focusCount focus', style: AppTypography.code(context.accent, fontSize: 10)),
                                  const SizedBox(width: 8),
                                ],
                                Icon(LucideIcons.listTodo, size: 12, color: context.mutedText),
                                const SizedBox(width: 4),
                                Text('${active.length} pending', style: AppTypography.code(context.mutedText, fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: context.secondarySurface,
                            valueColor: AlwaysStoppedAnimation<Color>(context.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            // Category Filter Pills with "+ New Category" Action
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              child: Row(
                children: [
                  // View Switcher (List vs Timeline vs Board)
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: context.secondarySurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.border, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewTab(TodayViewMode.list, 'List', LucideIcons.list),
                        _buildViewTab(TodayViewMode.timeline, 'Timeline', LucideIcons.clock),
                        _buildViewTab(TodayViewMode.board, 'Board', LucideIcons.columns),
                      ],
                    ),
                  ),
                  _CategoryFilterPill(
                    label: 'All',
                    isSelected: _selectedCategoryId == null,
                    onTap: () => setState(() => _selectedCategoryId = null),
                  ),
                  ...categories.map((cat) {
                    final color = Color(int.parse(cat.colorHex.replaceFirst('#', '0xFF')));
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _CategoryFilterPill(
                        label: cat.name,
                        dotColor: color,
                        isSelected: _selectedCategoryId == cat.id,
                        onTap: () => setState(() {
                          _selectedCategoryId = (_selectedCategoryId == cat.id) ? null : cat.id;
                        }),
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const CreateCategorySheet(),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.secondarySurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.border, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.plus, size: 12, color: context.mutedText),
                            const SizedBox(width: 4),
                            Text(
                              'New',
                              style: AppTypography.labelSmall(context.mutedText),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Inline Quick Add Input Bar
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: QuickAddBar(isTodayDefault: true),
            ),

            const SizedBox(height: 4),

            // Task List Area (Active reorderable + Collapsible completed)
            Expanded(
              child: todayTasksAsync.when(
                data: (tasks) {
                  if (_viewMode == TodayViewMode.board) {
                    return const BoardScreen();
                  }
                  if (_viewMode == TodayViewMode.timeline) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: TimeBlockTimeline(todayTasks: tasks),
                    );
                  }

                  // Apply active filters (search and category)
                  var filtered = tasks;
                  if (_selectedCategoryId != null) {
                    filtered = filtered.where((t) => t.categoryId == _selectedCategoryId).toList();
                  }
                  if (_searchQuery.isNotEmpty) {
                    filtered = filtered.where((t) =>
                        t.title.toLowerCase().contains(_searchQuery) ||
                        t.description.toLowerCase().contains(_searchQuery)).toList();
                  }

                  if (filtered.isEmpty) {
                    return _EmptyTodayState(
                      hasFilter: _selectedCategoryId != null || _searchQuery.isNotEmpty,
                      onClearFilters: () {
                        setState(() {
                          _selectedCategoryId = null;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    );
                  }

                  final activeTasks = filtered.where((t) => !t.isCompleted).toList();
                  final completedTasks = filtered.where((t) => t.isCompleted).toList();

                  return CustomScrollView(
                    slivers: [
                      // Active Reorderable Tasks
                      if (activeTasks.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                          sliver: SliverReorderableList(
                            itemCount: activeTasks.length,
                            onReorder: (oldIndex, newIndex) {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final reordered = List<TaskModel>.from(activeTasks);
                              final item = reordered.removeAt(oldIndex);
                              reordered.insert(newIndex, item);
                              ref.read(taskRepositoryProvider).reorderTasks(
                                    reordered.map((t) => t.id).toList(),
                                  );
                            },
                            itemBuilder: (ctx, i) {
                              final task = activeTasks[i];
                              return ReorderableDelayedDragStartListener(
                                key: ValueKey(task.id),
                                index: i,
                                child: TodayTaskItem(
                                  task: task,
                                  dragIndex: i,
                                ),
                              );
                            },
                          ),
                        )
                      else if (completedTasks.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(LucideIcons.checkCircle2, size: 28, color: context.accent),
                                  const SizedBox(height: 8),
                                  Text(
                                    'All scheduled tasks completed!',
                                    style: AppTypography.titleMedium(context.primaryText),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Great focus today. Take a break or plan upcoming goals.',
                                    style: AppTypography.bodySmall(context.mutedText),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Collapsible Completed Section
                      if (completedTasks.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
                            child: InkWell(
                              onTap: () => setState(() => _showCompleted = !_showCompleted),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      _showCompleted ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                                      size: 15,
                                      color: context.mutedText,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Completed (${completedTasks.length})',
                                      style: AppTypography.labelMedium(context.mutedText).copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_showCompleted)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) {
                                  final task = completedTasks[i];
                                  return TodayTaskItem(
                                    key: ValueKey(task.id),
                                    task: task,
                                    dragIndex: null,
                                  );
                                },
                                childCount: completedTasks.length,
                              ),
                            ),
                          ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
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

  Widget _buildViewTab(TodayViewMode mode, String label, IconData icon) {
    final isSel = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSel ? context.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 11, color: isSel ? context.accent : context.mutedText),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.code(isSel ? context.primaryText : context.mutedText, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _showDeadlineAlertDetails(BuildContext context, DeadlineAlertSummary alerts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.bellRing, size: 18, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text('Deadline Reminders', style: AppTypography.titleMedium(context.primaryText)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (alerts.overdueTasks.isNotEmpty) ...[
                  Text(
                    'OVERDUE',
                    style: AppTypography.labelSmall(AppColors.error).copyWith(letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 6),
                  ...alerts.overdueTasks.take(4).map(
                        (t) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.alertCircle, size: 14, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(t.title, style: AppTypography.bodySmall(context.primaryText)),
                              ),
                              Text(
                                t.deadline != null ? DateFormat('MMM d').format(t.deadline!) : '',
                                style: AppTypography.code(AppColors.error, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 12),
                ],
                if (alerts.dueTodayTasks.isNotEmpty) ...[
                  Text(
                    'DUE TODAY',
                    style: AppTypography.labelSmall(AppColors.warning).copyWith(letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 6),
                  ...alerts.dueTodayTasks.take(4).map(
                        (t) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.clock, size: 14, color: AppColors.warning),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(t.title, style: AppTypography.bodySmall(context.primaryText)),
                              ),
                              Text('Today', style: AppTypography.code(AppColors.warning, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Dismiss Alert'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryFilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? dotColor;
  final VoidCallback onTap;

  const _CategoryFilterPill({
    required this.label,
    required this.isSelected,
    this.dotColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? context.accent.withValues(alpha: 0.15) : context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? context.accent : context.border,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.labelSmall(isSelected ? context.accent : context.mutedText).copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTodayState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback? onClearFilters;

  const _EmptyTodayState({
    this.hasFilter = false,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(hasFilter ? LucideIcons.filterX : LucideIcons.sun, size: 36, color: context.mutedText),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'No Matching Tasks' : 'Clear Horizon',
            style: AppTypography.titleMedium(context.primaryText),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter
                ? 'No tasks match the active filter or search.'
                : 'No tasks scheduled for today. Add a task above or plan your day.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(context.mutedText),
          ),
          if (hasFilter && onClearFilters != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(LucideIcons.rotateCcw, size: 14),
              label: const Text('Reset Filters'),
            ),
          ],
        ],
      ),
    );
  }
}
