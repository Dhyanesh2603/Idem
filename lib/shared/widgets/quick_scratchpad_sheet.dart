import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../features/tasks/services/smart_task_parser.dart';
import '../../../database/database_provider.dart';

class QuickScratchpadSheet extends ConsumerStatefulWidget {
  const QuickScratchpadSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickScratchpadSheet(),
    );
  }

  @override
  ConsumerState<QuickScratchpadSheet> createState() => _QuickScratchpadSheetState();
}

class _QuickScratchpadSheetState extends ConsumerState<QuickScratchpadSheet> {
  static const String _storageKey = 'idem_quick_scratchpad_content';
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _controller.addListener(_saveContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey) ?? '';
    if (mounted) {
      _controller.text = saved;
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    }
  }

  Future<void> _saveContent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _controller.text);
  }

  Future<void> _convertLinesToTasks() async {
    final text = _controller.text;
    final lines = text.split('\n');
    final repo = ref.read(taskRepositoryProvider);
    int createdCount = 0;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Strip bullet points or numbers (e.g. "- ", "* ", "1. ")
      var clean = trimmed;
      if (clean.startsWith('- ') || clean.startsWith('* ')) {
        clean = clean.substring(2).trim();
      } else if (RegExp(r'^\d+\.\s+').hasMatch(clean)) {
        clean = clean.replaceFirst(RegExp(r'^\d+\.\s+'), '').trim();
      }

      if (clean.isNotEmpty) {
        final parsed = SmartTaskParser.parse(clean);
        await repo.createTask(
          title: parsed.title,
          priority: parsed.priority,
          deadline: parsed.deadline ?? DateTime.now(),
          estimatedMinutes: parsed.estimatedMinutes ?? 0,
        );
        createdCount++;
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$createdCount task(s) created from scratchpad notes into Today.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: isDesktop ? 680 : double.infinity,
          height: MediaQuery.of(context).size.height * 0.75,
          margin: EdgeInsets.only(
            left: isDesktop ? 0 : 12,
            right: isDesktop ? 0 : 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 36,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.feather, size: 16, color: context.accent),
                      const SizedBox(width: 10),
                      Text(
                        'QUICK SCRATCHPAD (⌘J)',
                        style: AppTypography.titleSmall(context.primaryText).copyWith(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Copy all to clipboard',
                        icon: Icon(LucideIcons.copy, size: 15, color: context.mutedText),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _controller.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied notes to clipboard'), behavior: SnackBarBehavior.floating),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Clear scratchpad',
                        icon: Icon(LucideIcons.trash2, size: 15, color: context.mutedText),
                        onPressed: () => setState(() => _controller.clear()),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: Icon(LucideIcons.x, size: 16, color: context.mutedText),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Instant thought capture. Bullet lines (e.g. "- Buy milk tomorrow !high") can be auto-converted into tasks.',
                style: AppTypography.bodySmall(context.mutedText),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: context.border),

              // Notepad Editor
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        expands: true,
                        style: AppTypography.bodyMedium(context.primaryText).copyWith(height: 1.6),
                        decoration: InputDecoration(
                          hintText: 'Brain dump thoughts, code snippets, meeting bullets...\n\n- Draft architecture RFC\n- Run performance benchmarks tomorrow at 3pm !high #DevOps\n- Review pull request ~30m',
                          hintStyle: AppTypography.bodyMedium(context.mutedText.withValues(alpha: 0.5)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
              ),

              Divider(height: 1, color: context.border),
              const SizedBox(height: 12),

              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_controller.text.split('\n').where((l) => l.trim().isNotEmpty).length} lines • ${_controller.text.length} chars',
                    style: AppTypography.code(context.mutedText, fontSize: 10),
                  ),
                  FilledButton.icon(
                    onPressed: _controller.text.trim().isEmpty ? null : _convertLinesToTasks,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(LucideIcons.checkCheck, size: 14, color: Colors.black),
                    label: Text(
                      'Convert Lines to Tasks',
                      style: AppTypography.labelMedium(Colors.black).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
