import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../database/database_provider.dart';

class CreateCategorySheet extends ConsumerStatefulWidget {
  const CreateCategorySheet({super.key});

  @override
  ConsumerState<CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends ConsumerState<CreateCategorySheet> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _selectedColor = '#3B82F6';
  bool _isSubmitting = false;

  static const List<Map<String, String>> _colors = [
    {'name': 'Ocean', 'hex': '#3B82F6'},
    {'name': 'Emerald', 'hex': '#10B981'},
    {'name': 'Amber', 'hex': '#F59E0B'},
    {'name': 'Lavender', 'hex': '#8B5CF6'},
    {'name': 'Crimson', 'hex': '#EF4444'},
    {'name': 'Slate', 'hex': '#64748B'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(categoryRepositoryProvider);
      await repo.createCategory(
        name: name,
        colorHex: _selectedColor,
        iconName: 'tag',
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New Category',
                style: AppTypography.titleMedium(context.primaryText),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name Input
          TextField(
            controller: _nameController,
            focusNode: _focusNode,
            style: AppTypography.bodyMedium(context.primaryText),
            decoration: InputDecoration(
              hintText: 'Category name (e.g., Deep Work, Research)...',
              hintStyle: AppTypography.bodyMedium(context.mutedText),
              filled: true,
              fillColor: context.secondarySurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.border, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.border, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.accent, width: 1.2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),

          // Color Swatches
          Text(
            'COLOR PALETTE',
            style: AppTypography.labelSmall(context.mutedText).copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _colors.map((c) {
              final color = Color(int.parse(c['hex']!.replaceFirst('#', '0xFF')));
              final isSelected = _selectedColor == c['hex'];

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedColor = c['hex']!),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? context.accent : color,
                        width: isSelected ? 2.5 : 1.2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: AppTypography.bodySmall(context.mutedText)),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: context.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  _isSubmitting ? 'Creating...' : 'Create Category',
                  style: AppTypography.labelMedium(Colors.black).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
