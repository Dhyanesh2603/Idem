import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/app_typography.dart';
import '../../features/focus/widgets/ambient_audio_dock.dart';
import '../../features/tasks/providers/task_providers.dart';
import 'quick_scratchpad_sheet.dart';
import 'command_palette.dart';

class WorkstationTopHeader extends ConsumerStatefulWidget {
  const WorkstationTopHeader({super.key});

  @override
  ConsumerState<WorkstationTopHeader> createState() => _WorkstationTopHeaderState();
}

class _WorkstationTopHeaderState extends ConsumerState<WorkstationTopHeader> {
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayTasksAsync = ref.watch(todayTasksStreamProvider);
    final todayTasks = todayTasksAsync.asData?.value ?? [];
    final total = todayTasks.length;
    final completed = todayTasks.where((t) => t.isCompleted).length;
    final progress = total > 0 ? (completed / total) : 0.0;

    final timeStr = DateFormat('h:mm a').format(_currentTime);
    final dateStr = DateFormat('EEE, MMM d').format(_currentTime);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 580;
        final showProgress = constraints.maxWidth > 500 && total > 0;

        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.surface,
            border: Border(bottom: BorderSide(color: context.border, width: 0.8)),
          ),
          child: Row(
            children: [
              // Live Clock & Date
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.clock, size: 13, color: context.mutedText),
                  const SizedBox(width: 7),
                  Text(
                    timeStr,
                    style: AppTypography.code(context.primaryText, fontSize: 11).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isWide) ...[
                    const SizedBox(width: 6),
                    Text(
                      '•  $dateStr',
                      style: AppTypography.code(context.mutedText, fontSize: 11),
                    ),
                  ],
                ],
              ),

              const Spacer(),

              // Daily Horizon Progress Pill
              if (showProgress) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.secondarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.border, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2.2,
                          backgroundColor: context.border,
                          valueColor: AlwaysStoppedAnimation<Color>(context.accent),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$completed/$total done',
                        style: AppTypography.code(context.primaryText, fontSize: 10).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Flow Soundscapes Synthesizer Pill
              const AmbientAudioDock(compact: true),
              const SizedBox(width: 6),

              // Quick Scratchpad (⌘J)
              IconButton(
                icon: const Icon(LucideIcons.feather, size: 15),
                tooltip: 'Quick Scratchpad (⌘J)',
                onPressed: () => QuickScratchpadSheet.show(context),
                visualDensity: VisualDensity.compact,
                color: context.mutedText,
              ),

              // Deep Focus Mode (⌘F)
              IconButton(
                icon: const Icon(LucideIcons.target, size: 15),
                tooltip: 'Focus Workstation (⌘F)',
                onPressed: () => context.push('/focus'),
                visualDensity: VisualDensity.compact,
                color: context.accent,
              ),

              // Command Palette (⌘K)
              IconButton(
                icon: const Icon(LucideIcons.command, size: 15),
                tooltip: 'Command Palette (⌘K)',
                onPressed: () => CommandPalette.show(context),
                visualDensity: VisualDensity.compact,
                color: context.mutedText,
              ),
            ],
          ),
        );
      },
    );
  }
}
