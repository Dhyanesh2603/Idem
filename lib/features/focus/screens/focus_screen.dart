import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../tasks/providers/task_providers.dart';
import '../../../database/database_provider.dart';
import '../widgets/ambient_audio_dock.dart';

enum FocusTimerMode {
  pomodoro(25 * 60, '25m Focus'),
  deepWork(50 * 60, '50m Deep Work'),
  shortBreak(5 * 60, '5m Break'),
  stopwatch(0, 'Stopwatch');

  final int initialSeconds;
  final String label;
  const FocusTimerMode(this.initialSeconds, this.label);
}

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  FocusTimerMode _mode = FocusTimerMode.pomodoro;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  int _currentTaskIndex = 0;
  int _completedSessionsToday = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _mode.initialSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _switchMode(FocusTimerMode mode) {
    _timer?.cancel();
    setState(() {
      _mode = mode;
      _remainingSeconds = mode.initialSeconds;
      _isRunning = false;
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_mode == FocusTimerMode.stopwatch) {
          setState(() => _remainingSeconds++);
        } else {
          if (_remainingSeconds > 0) {
            setState(() => _remainingSeconds--);
          } else {
            _timer?.cancel();
            final minutesSpent = _mode.initialSeconds ~/ 60;
            if (minutesSpent > 0) {
              _logCompletedMinutes(minutesSpent);
            }
            setState(() {
              _isRunning = false;
              _completedSessionsToday++;
            });
            _showCompletionDialog();
          }
        }
      });
    }
  }

  void _logCompletedMinutes(int minutes) async {
    final todayTasksAsync = ref.read(todayTasksStreamProvider);
    final focusTasks = (todayTasksAsync.asData?.value ?? [])
        .where((t) => t.isFocus && !t.isCompleted)
        .toList();
    if (focusTasks.isNotEmpty && _currentTaskIndex < focusTasks.length) {
      final active = focusTasks[_currentTaskIndex];
      await ref.read(taskRepositoryProvider).updateTask(
        active.copyWith(timeSpentMinutes: active.timeSpentMinutes + minutes),
      );
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _mode.initialSeconds;
      _isRunning = false;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        title: Row(
          children: [
            Icon(LucideIcons.bellRing, color: context.accent, size: 20),
            const SizedBox(width: 8),
            Text('Session Completed', style: AppTypography.titleMedium(context.primaryText)),
          ],
        ),
        content: Text(
          'Great deep focus! Take a 5-minute breather or continue to the next task.',
          style: AppTypography.bodyMedium(context.secondaryText),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _switchMode(FocusTimerMode.shortBreak);
            },
            child: const Text('Take 5m Break'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _resetTimer();
            },
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final todayTasksAsync = ref.watch(todayTasksStreamProvider);
    final focusTasks = (todayTasksAsync.asData?.value ?? [])
        .where((t) => t.isFocus && !t.isCompleted)
        .toList();

    final task = focusTasks.isNotEmpty
        ? focusTasks[_currentTaskIndex.clamp(0, focusTasks.length - 1)]
        : null;

    final subtasksAsync = task != null
        ? ref.watch(taskSubtasksStreamProvider(task.id))
        : null;
    final subtasks = subtasksAsync?.asData?.value ?? [];

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Bar with presets & close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isRunning ? context.accent : context.mutedText,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'FOCUS WORKSTATION',
                        style: AppTypography.labelSmall(context.mutedText).copyWith(
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_completedSessionsToday > 0) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.secondarySurface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: context.border, width: 0.8),
                          ),
                          child: Text(
                            '$_completedSessionsToday session(s) completed',
                            style: AppTypography.code(context.accent, fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      const AmbientAudioDock(compact: true),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Timer Mode Selector Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: FocusTimerMode.values.map((m) {
                    final isSel = _mode == m;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => _switchMode(m),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? context.accent.withValues(alpha: 0.15) : context.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSel ? context.accent : context.border,
                              width: isSel ? 1.2 : 0.8,
                            ),
                          ),
                          child: Text(
                            m.label,
                            style: AppTypography.code(
                              isSel ? context.accent : context.mutedText,
                              fontSize: 11,
                            ).copyWith(fontWeight: isSel ? FontWeight.w600 : FontWeight.w400),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Spacer(flex: 1),

              if (task == null) ...[
                Text(
                  'No Active Focus Tasks',
                  style: AppTypography.titleLarge(context.primaryText),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select tasks in Today or open the Planning Session to choose your deep work target.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium(context.mutedText),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Today'),
                ),
              ] else ...[
                // Task Counter & Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (focusTasks.length > 1)
                      IconButton(
                        icon: const Icon(LucideIcons.chevronLeft, size: 16),
                        onPressed: _currentTaskIndex > 0
                            ? () => setState(() => _currentTaskIndex--)
                            : null,
                      ),
                    Text(
                      'FOCUS TARGET ${_currentTaskIndex + 1} OF ${focusTasks.length}',
                      style: AppTypography.code(context.mutedText, fontSize: 11).copyWith(letterSpacing: 1.5),
                    ),
                    if (focusTasks.length > 1)
                      IconButton(
                        icon: const Icon(LucideIcons.chevronRight, size: 16),
                        onPressed: _currentTaskIndex < focusTasks.length - 1
                            ? () => setState(() => _currentTaskIndex++)
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Large Focused Title
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Text(
                    task.title,
                    textAlign: TextAlign.center,
                    style: AppTypography.displayMedium(context.primaryText).copyWith(height: 1.3),
                  ),
                ),

                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Text(
                      task.description,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium(context.secondaryText),
                    ),
                  ),
                ],

                const SizedBox(height: 36),

                // Countdown Timer Display with Circular Pulse
                GestureDetector(
                  onTap: _toggleTimer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isRunning ? context.accent : context.border,
                        width: _isRunning ? 1.5 : 1.0,
                      ),
                      boxShadow: _isRunning
                          ? [
                              BoxShadow(
                                color: context.accent.withValues(alpha: 0.12),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isRunning ? LucideIcons.pause : LucideIcons.play,
                          size: 20,
                          color: _isRunning ? context.accent : context.mutedText,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _formatTime(_remainingSeconds),
                          style: AppTypography.code(context.primaryText, fontSize: 36).copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _resetTimer,
                      icon: const Icon(LucideIcons.rotateCcw, size: 13),
                      label: const Text('Reset Timer'),
                    ),
                  ],
                ),

                // Subtasks checklist (if any)
                if (subtasks.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.border, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ACTION STEPS',
                                style: AppTypography.code(context.mutedText, fontSize: 10).copyWith(letterSpacing: 1.2),
                              ),
                              Text(
                                '${subtasks.where((s) => s.isCompleted).length}/${subtasks.length} done',
                                style: AppTypography.code(context.accent, fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...subtasks.map((st) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      ref.read(taskRepositoryProvider).toggleTaskCompletion(st.id);
                                    },
                                    child: Icon(
                                      st.isCompleted ? LucideIcons.checkSquare : LucideIcons.square,
                                      size: 15,
                                      color: st.isCompleted ? context.accent : context.mutedText,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      st.title,
                                      style: AppTypography.bodySmall(context.primaryText).copyWith(
                                        decoration: st.isCompleted ? TextDecoration.lineThrough : null,
                                        decorationColor: context.mutedText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Complete Task Action Button
                FilledButton.icon(
                  onPressed: () async {
                    await ref.read(taskRepositoryProvider).toggleTaskCompletion(task.id);
                    if (focusTasks.length <= 1 && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: context.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(LucideIcons.check, size: 16, color: Colors.black),
                  label: Text('Mark Task Completed', style: AppTypography.labelMedium(Colors.black).copyWith(fontWeight: FontWeight.w600)),
                ),
              ],

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
