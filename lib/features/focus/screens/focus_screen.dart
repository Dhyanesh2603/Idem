import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../tasks/providers/task_providers.dart';
import '../../../database/database_provider.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  int _secondsElapsed = 0;
  Timer? _timer;
  bool _isRunning = true;
  int _currentTaskIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isRunning && mounted) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  void _toggleTimer() {
    setState(() => _isRunning = !_isRunning);
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

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Bar with Close button
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
                        'FOCUS MODE',
                        style: AppTypography.labelSmall(context.mutedText).copyWith(
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const Spacer(flex: 2),

              if (focusTasks.isEmpty) ...[
                Text(
                  'No Active Focus Tasks',
                  style: AppTypography.titleLarge(context.primaryText),
                ),
                const SizedBox(height: 12),
                Text(
                  'Star tasks in Today or open the Planning Session to choose your focus.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium(context.mutedText),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Today'),
                ),
              ] else ...[
                // Active task
                Builder(
                  builder: (context) {
                    final index = _currentTaskIndex.clamp(0, focusTasks.length - 1);
                    final task = focusTasks[index];

                    return Column(
                      children: [
                        // Task Counter
                        Text(
                          'TASK ${index + 1} OF ${focusTasks.length}',
                          style: AppTypography.code(context.mutedText, fontSize: 12).copyWith(
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Large Focused Title
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Text(
                            task.title,
                            textAlign: TextAlign.center,
                            style: AppTypography.displayMedium(context.primaryText).copyWith(
                              height: 1.3,
                            ),
                          ),
                        ),

                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Text(
                              task.description,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium(context.secondaryText),
                            ),
                          ),
                        ],

                        const SizedBox(height: 48),

                        // Minimalist Timer
                        GestureDetector(
                          onTap: _toggleTimer,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: context.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.border, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isRunning ? LucideIcons.pause : LucideIcons.play,
                                  size: 16,
                                  color: context.mutedText,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _formatTime(_secondsElapsed),
                                  style: AppTypography.code(context.primaryText, fontSize: 24).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Action Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (focusTasks.length > 1) ...[
                              IconButton(
                                icon: const Icon(LucideIcons.chevronLeft, size: 20),
                                onPressed: index > 0
                                    ? () => setState(() => _currentTaskIndex--)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                            ],
                            ElevatedButton.icon(
                              onPressed: () async {
                                await ref.read(taskRepositoryProvider).toggleTaskCompletion(task.id);
                                if (focusTasks.length <= 1 && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              icon: const Icon(LucideIcons.check, size: 16, color: Colors.black),
                              label: const Text('Complete Task'),
                            ),
                            if (focusTasks.length > 1) ...[
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(LucideIcons.chevronRight, size: 20),
                                onPressed: index < focusTasks.length - 1
                                    ? () => setState(() => _currentTaskIndex++)
                                    : null,
                              ),
                            ],
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
