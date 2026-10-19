import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../services/soundscape_service.dart';

class SoundscapeSelectorSheet extends ConsumerWidget {
  const SoundscapeSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SoundscapeSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundscape = ref.watch(soundscapeProvider);
    final notifier = ref.read(soundscapeProvider.notifier);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 580,
      ),
      margin: EdgeInsets.only(
        left: (MediaQuery.of(context).size.width > 600)
            ? (MediaQuery.of(context).size.width - 580) / 2
            : 0,
        right: (MediaQuery.of(context).size.width > 600)
            ? (MediaQuery.of(context).size.width - 580) / 2
            : 0,
      ),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Icon(LucideIcons.headphones, size: 20, color: context.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FLOW SOUNDSCAPES',
                        style: AppTypography.labelSmall(context.mutedText).copyWith(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Ambient Focus Synthesizer',
                        style: AppTypography.titleMedium(context.primaryText),
                      ),
                    ],
                  ),
                ),
                if (soundscape.isPlaying)
                  TextButton.icon(
                    onPressed: () => notifier.stop(),
                    icon: const Icon(LucideIcons.square, size: 14),
                    label: const Text('Mute'),
                    style: TextButton.styleFrom(foregroundColor: context.mutedText),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Box Breathing Practice Widget
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.secondarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: soundscape.isBreathingActive ? context.accent : context.border,
                      width: soundscape.isBreathingActive ? 1.2 : 0.8,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.wind,
                                size: 16,
                                color: soundscape.isBreathingActive ? context.accent : context.mutedText,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Box Breathing Reset (4-4-4-4)',
                                style: AppTypography.labelMedium(context.primaryText).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () => notifier.toggleBreathing(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: soundscape.isBreathingActive
                                    ? context.accent.withValues(alpha: 0.15)
                                    : context.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: soundscape.isBreathingActive ? context.accent : context.border,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                soundscape.isBreathingActive ? 'Stop Exercise' : 'Start (1 min)',
                                style: AppTypography.code(
                                  soundscape.isBreathingActive ? context.accent : context.primaryText,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (soundscape.isBreathingActive) ...[
                        const SizedBox(height: 16),
                        AnimatedContainer(
                          duration: const Duration(seconds: 4),
                          width: soundscape.breathingPhase == BreathingPhase.inhale ||
                                  soundscape.breathingPhase == BreathingPhase.holdIn
                              ? 72
                              : 44,
                          height: soundscape.breathingPhase == BreathingPhase.inhale ||
                                  soundscape.breathingPhase == BreathingPhase.holdIn
                              ? 72
                              : 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.accent.withValues(alpha: 0.18),
                            border: Border.all(color: context.accent, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '${soundscape.breathingCountdown}s',
                              style: AppTypography.displayMedium(context.accent).copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          soundscape.breathingPhase.prompt,
                          style: AppTypography.bodyMedium(context.primaryText).copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Volume Slider
                Row(
                  children: [
                    Icon(LucideIcons.volume2, size: 16, color: context.mutedText),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: context.accent,
                          inactiveTrackColor: context.secondarySurface,
                          thumbColor: context.accent,
                          overlayColor: context.accent.withValues(alpha: 0.2),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: soundscape.volume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (val) => notifier.setVolume(val),
                        ),
                      ),
                    ),
                    Text(
                      '${(soundscape.volume * 100).toInt()}%',
                      style: AppTypography.code(context.mutedText, fontSize: 11),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Soundscape Options Cards
                Text(
                  'SELECT ACOUSTIC AMBIENCE',
                  style: AppTypography.labelSmall(context.mutedText).copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(height: 10),

                ...SoundscapeType.values.where((t) => t != SoundscapeType.none).map((type) {
                  final isCurrent = soundscape.activeType == type && soundscape.isPlaying;
                  IconData icon;
                  switch (type) {
                    case SoundscapeType.brownNoise:
                      icon = LucideIcons.activity;
                      break;
                    case SoundscapeType.pinkNoise:
                      icon = LucideIcons.waves;
                      break;
                    case SoundscapeType.binaural40:
                      icon = LucideIcons.zap;
                      break;
                    case SoundscapeType.rain:
                      icon = LucideIcons.cloudRain;
                      break;
                    case SoundscapeType.whiteNoise:
                      icon = LucideIcons.radio;
                      break;
                    default:
                      icon = LucideIcons.volumeX;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        if (isCurrent) {
                          notifier.stop();
                        } else {
                          notifier.play(type);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? context.accent.withValues(alpha: 0.12)
                              : context.secondarySurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrent ? context.accent : context.border,
                            width: isCurrent ? 1.2 : 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isCurrent ? context.accent : context.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                icon,
                                size: 18,
                                color: isCurrent ? Colors.black : context.primaryText,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type.title,
                                    style: AppTypography.labelLarge(context.primaryText).copyWith(
                                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    type.description,
                                    style: AppTypography.bodySmall(context.mutedText),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isCurrent ? LucideIcons.pauseCircle : LucideIcons.playCircle,
                              size: 22,
                              color: isCurrent ? context.accent : context.mutedText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
