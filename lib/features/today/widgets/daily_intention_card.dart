import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_motion.dart';

class DailyIntentionCard extends StatefulWidget {
  const DailyIntentionCard({super.key});

  @override
  State<DailyIntentionCard> createState() => _DailyIntentionCardState();
}

class _DailyIntentionCardState extends State<DailyIntentionCard> {
  String? _intention;
  bool _isAchieved = false;
  bool _isLoading = true;

  String get _dateKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadIntention();
  }

  Future<void> _loadIntention() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text = prefs.getString('daily_intention_$_dateKey');
      final done = prefs.getBool('daily_intention_done_$_dateKey') ?? false;
      if (mounted) {
        setState(() {
          _intention = text;
          _isAchieved = done;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveIntention(String text) async {
    final clean = text.trim();
    final prefs = await SharedPreferences.getInstance();
    if (clean.isEmpty) {
      await prefs.remove('daily_intention_$_dateKey');
      await prefs.remove('daily_intention_done_$_dateKey');
      setState(() {
        _intention = null;
        _isAchieved = false;
      });
    } else {
      await prefs.setString('daily_intention_$_dateKey', clean);
      setState(() {
        _intention = clean;
      });
    }
  }

  Future<void> _toggleAchieved() async {
    final prefs = await SharedPreferences.getInstance();
    final newVal = !_isAchieved;
    await prefs.setBool('daily_intention_done_$_dateKey', newVal);
    setState(() => _isAchieved = newVal);
  }

  void _showEditDialog() {
    final controller = TextEditingController(text: _intention ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: context.border, width: 1),
        ),
        title: Row(
          children: [
            Icon(LucideIcons.sparkles, size: 18, color: context.accent),
            const SizedBox(width: 8),
            Text('Today’s Core Intention', style: AppTypography.titleMedium(context.primaryText)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What is the single most important outcome you must achieve today?',
              style: AppTypography.bodySmall(context.mutedText),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              style: AppTypography.bodyMedium(context.primaryText),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g., Ship offline sync & verify conflict recovery',
                hintStyle: AppTypography.bodySmall(context.mutedText),
                filled: true,
                fillColor: context.secondarySurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: context.border, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: context.accent, width: 1.2),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTypography.bodySmall(context.mutedText)),
          ),
          FilledButton(
            onPressed: () {
              _saveIntention(controller.text);
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: context.accent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Set Intention'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    if (_intention == null || _intention!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: InkWell(
          onTap: _showEditDialog,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: context.border,
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.compass, size: 16, color: context.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Define today’s core focus or primary intention...',
                    style: AppTypography.bodySmall(context.mutedText).copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
                Text(
                  'Set',
                  style: AppTypography.code(context.accent, fontSize: 11).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isAchieved ? context.accent : context.border,
            width: _isAchieved ? 1.2 : 0.8,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: context.accent,
                  width: 3.5,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Achievement Checkbox
                GestureDetector(
                  onTap: _toggleAchieved,
                  child: AnimatedContainer(
                    duration: AppMotion.checkboxCheck,
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _isAchieved ? context.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: _isAchieved ? context.accent : context.border,
                        width: 1.5,
                      ),
                    ),
                    child: _isAchieved
                        ? const Center(child: Icon(LucideIcons.check, size: 13, color: Colors.black))
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Core Intention Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'PRIMARY INTENTION',
                            style: AppTypography.code(context.accent, fontSize: 9).copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_isAchieved) ...[
                            const SizedBox(width: 6),
                            Text(
                              '• COMPLETED',
                              style: AppTypography.code(context.mutedText, fontSize: 9),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _intention!,
                        style: AppTypography.bodyMedium(context.primaryText).copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: _isAchieved ? TextDecoration.lineThrough : null,
                          decorationColor: context.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit & Clear Actions
                IconButton(
                  tooltip: 'Edit Intention',
                  icon: Icon(LucideIcons.pencil, size: 14, color: context.mutedText),
                  onPressed: _showEditDialog,
                ),
                IconButton(
                  tooltip: 'Clear',
                  icon: Icon(LucideIcons.x, size: 14, color: context.mutedText),
                  onPressed: () => _saveIntention(''),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
