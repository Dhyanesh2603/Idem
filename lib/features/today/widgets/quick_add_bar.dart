import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../tasks/models/task_priority.dart';
import '../../categories/providers/category_providers.dart';
import '../../../database/database_provider.dart';

/// Sub-3-second quick task capture input with category and priority selectors.
class QuickAddBar extends ConsumerStatefulWidget {
  final bool isTodayDefault;

  const QuickAddBar({
    super.key,
    this.isTodayDefault = false,
  });

  @override
  ConsumerState<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends ConsumerState<QuickAddBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  TaskPriority _selectedPriority = TaskPriority.none;
  String? _selectedCategoryId;
  DateTime? _selectedDeadline;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isTodayDefault) {
      _selectedDeadline = DateTime.now();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final repo = ref.read(taskRepositoryProvider);

    try {
      await repo.createTask(
        title: text,
        priority: _selectedPriority,
        categoryId: _selectedCategoryId,
        deadline: _selectedDeadline ?? (widget.isTodayDefault ? DateTime.now() : null),
      );
      _controller.clear();
      setState(() {
        _selectedPriority = TaskPriority.none;
        _selectedCategoryId = null;
        if (!widget.isTodayDefault) {
          _selectedDeadline = null;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final categories = categoriesAsync.asData?.value ?? [];
    final selectedCategory = categories.where((c) => c.id == _selectedCategoryId).firstOrNull;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(LucideIcons.plus, size: 18, color: context.mutedText),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: AppTypography.bodyMedium(context.primaryText),
                  decoration: InputDecoration(
                    hintText: widget.isTodayDefault ? 'Add task to Today...' : 'Quick capture thought or task...',
                    hintStyle: AppTypography.bodyMedium(context.mutedText),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: false,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),

              // Category Selector Menu
              if (categories.isNotEmpty)
                PopupMenuButton<String?>(
                  tooltip: 'Assign Category',
                  icon: Icon(
                    LucideIcons.tag,
                    size: 16,
                    color: selectedCategory != null
                        ? Color(int.parse(selectedCategory.colorHex.replaceFirst('#', '0xFF')))
                        : context.mutedText,
                  ),
                  onSelected: (catId) => setState(() => _selectedCategoryId = catId),
                  itemBuilder: (_) => [
                    PopupMenuItem<String?>(
                      value: null,
                      child: Text('No Category', style: AppTypography.bodySmall(context.mutedText)),
                    ),
                    ...categories.map((cat) {
                      final cColor = Color(int.parse(cat.colorHex.replaceFirst('#', '0xFF')));
                      return PopupMenuItem<String?>(
                        value: cat.id,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: cColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(cat.name, style: AppTypography.bodySmall(context.primaryText)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),

              // Priority Selector Menu
              PopupMenuButton<TaskPriority>(
                tooltip: 'Set Priority',
                icon: Icon(
                  LucideIcons.flag,
                  size: 16,
                  color: _selectedPriority != TaskPriority.none
                      ? _selectedPriority.color
                      : context.mutedText,
                ),
                onSelected: (p) => setState(() => _selectedPriority = p),
                itemBuilder: (_) => TaskPriority.values.map((p) {
                  return PopupMenuItem(
                    value: p,
                    child: Row(
                      children: [
                        Icon(LucideIcons.flag, size: 14, color: p.color),
                        const SizedBox(width: 8),
                        Text(p.displayName, style: AppTypography.bodySmall(context.primaryText)),
                      ],
                    ),
                  );
                }).toList(),
              ),

              // Submit Button
              IconButton(
                icon: Icon(LucideIcons.arrowRight, size: 16, color: context.accent),
                onPressed: _submit,
              ),
            ],
          ),

          // Active Tags Strip (if category or priority selected)
          if (_selectedPriority != TaskPriority.none || selectedCategory != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 30),
              child: Row(
                children: [
                  if (_selectedPriority != TaskPriority.none)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _selectedPriority.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _selectedPriority.color.withValues(alpha: 0.3), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.flag, size: 10, color: _selectedPriority.color),
                          const SizedBox(width: 4),
                          Text(
                            _selectedPriority.displayName,
                            style: AppTypography.code(_selectedPriority.color, fontSize: 10),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setState(() => _selectedPriority = TaskPriority.none),
                            child: Icon(LucideIcons.x, size: 10, color: _selectedPriority.color),
                          ),
                        ],
                      ),
                    ),
                  if (selectedCategory != null)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(int.parse(selectedCategory.colorHex.replaceFirst('#', '0xFF'))).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Color(int.parse(selectedCategory.colorHex.replaceFirst('#', '0xFF'))).withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '# ${selectedCategory.name}',
                            style: AppTypography.code(
                              Color(int.parse(selectedCategory.colorHex.replaceFirst('#', '0xFF'))),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setState(() => _selectedCategoryId = null),
                            child: Icon(LucideIcons.x, size: 10, color: context.mutedText),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
