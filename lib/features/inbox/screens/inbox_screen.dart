import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/sync_status_badge.dart';
import '../../today/widgets/quick_add_bar.dart';
import '../../today/widgets/today_task_item.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/providers/task_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../../database/database_provider.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inboxTasksAsync = ref.watch(inboxTasksStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final categories = categoriesAsync.asData?.value ?? [];

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Sync Badge and Search Toggle
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
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
                  Row(
                    children: [
                      const SyncStatusBadge(compact: true),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Search inbox',
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
                    ],
                  ),
                ],
              ),
            ),

            // Optional Search Input
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
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
                      hintText: 'Search inbox tasks...',
                      hintStyle: AppTypography.bodySmall(context.mutedText),
                      prefixIcon: Icon(LucideIcons.search, size: 16, color: context.mutedText),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                ),
              ),

            // Category Filter Pills
            if (categories.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Row(
                  children: [
                    _InboxCategoryFilterPill(
                      label: 'All',
                      isSelected: _selectedCategoryId == null,
                      onTap: () => setState(() => _selectedCategoryId = null),
                    ),
                    ...categories.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _InboxCategoryFilterPill(
                          label: cat.name,
                          isSelected: _selectedCategoryId == cat.id,
                          onTap: () => setState(() {
                            _selectedCategoryId = (_selectedCategoryId == cat.id) ? null : cat.id;
                          }),
                        ),
                      );
                    }),
                  ],
                ),
              ),

            // Quick capture bar (captures unscheduled to inbox)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: QuickAddBar(isTodayDefault: false),
            ),

            const SizedBox(height: 4),

            // Reorderable Task List
            Expanded(
              child: inboxTasksAsync.when(
                data: (tasks) {
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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.inbox, size: 36, color: context.mutedText),
                          const SizedBox(height: 16),
                          Text(
                            _selectedCategoryId != null || _searchQuery.isNotEmpty
                                ? 'No Matching Tasks'
                                : 'Inbox Zero',
                            style: AppTypography.titleMedium(context.primaryText),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedCategoryId != null || _searchQuery.isNotEmpty
                                ? 'No inbox items match your active filters.'
                                : 'All thoughts and capture items have been organized.',
                            style: AppTypography.bodyMedium(context.mutedText),
                          ),
                        ],
                      ),
                    );
                  }

                  return ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: filtered.length,
                    buildDefaultDragHandles: false,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final reordered = List<TaskModel>.from(filtered);
                      final item = reordered.removeAt(oldIndex);
                      reordered.insert(newIndex, item);
                      ref.read(taskRepositoryProvider).reorderTasks(
                            reordered.map((t) => t.id).toList(),
                          );
                    },
                    itemBuilder: (ctx, i) {
                      final task = filtered[i];
                      return TodayTaskItem(
                        key: ValueKey(task.id),
                        task: task,
                        dragIndex: i,
                      );
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

class _InboxCategoryFilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _InboxCategoryFilterPill({
    required this.label,
    required this.isSelected,
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
        child: Text(
          label,
          style: AppTypography.labelSmall(isSelected ? context.accent : context.mutedText).copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
