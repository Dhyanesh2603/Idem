import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../tasks/models/task_priority.dart';
import '../../../database/database_provider.dart';

/// Sub-3-second quick task capture input.
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
  bool _isSubmitting = false;

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
      final now = DateTime.now();
      await repo.createTask(
        title: text,
        priority: _selectedPriority,
        deadline: widget.isTodayDefault ? now : null,
      );
      _controller.clear();
      setState(() {
        _selectedPriority = TaskPriority.none;
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Row(
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
          // Priority Selector Dropdown / Menu
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
          IconButton(
            icon: Icon(LucideIcons.arrowRight, size: 16, color: context.accent),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
