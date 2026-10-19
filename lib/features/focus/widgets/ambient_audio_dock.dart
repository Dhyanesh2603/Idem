import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../services/soundscape_service.dart';
import 'soundscape_selector_sheet.dart';

class AmbientAudioDock extends ConsumerStatefulWidget {
  final bool compact;
  const AmbientAudioDock({super.key, this.compact = false});

  @override
  ConsumerState<AmbientAudioDock> createState() => _AmbientAudioDockState();
}

class _AmbientAudioDockState extends ConsumerState<AmbientAudioDock>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final soundscape = ref.watch(soundscapeProvider);
    final notifier = ref.read(soundscapeProvider.notifier);

    final isPlaying = soundscape.isPlaying;
    if (isPlaying) {
      if (!_animController.isAnimating) {
        _animController.repeat(reverse: true);
      }
    } else {
      if (_animController.isAnimating) {
        _animController.stop();
      }
    }
    final trackName = soundscape.activeType == SoundscapeType.none
        ? 'Acoustic Ambience'
        : soundscape.activeType.title;

    if (widget.compact) {
      return InkWell(
        onTap: () => SoundscapeSelectorSheet.show(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isPlaying
                ? context.accent.withValues(alpha: 0.12)
                : context.secondarySurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPlaying ? context.accent : context.border,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWaveformBars(isPlaying, context.accent),
              const SizedBox(width: 6),
              Text(
                isPlaying ? soundscape.activeType.title : 'Soundscapes',
                style: AppTypography.code(
                  isPlaying ? context.accent : context.mutedText,
                  fontSize: 10,
                ).copyWith(fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w400),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPlaying ? context.accent.withValues(alpha: 0.4) : context.border,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildWaveformBars(isPlaying, context.accent),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => SoundscapeSelectorSheet.show(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AMBIENT FLOW',
                  style: AppTypography.code(context.mutedText, fontSize: 8).copyWith(letterSpacing: 1.0),
                ),
                Text(
                  trackName,
                  style: AppTypography.labelSmall(context.primaryText).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(
              isPlaying ? LucideIcons.pause : LucideIcons.play,
              size: 15,
              color: isPlaying ? context.accent : context.mutedText,
            ),
            onPressed: () => notifier.toggle(),
            tooltip: isPlaying ? 'Pause soundscape' : 'Play soundscape',
          ),
          IconButton(
            icon: const Icon(LucideIcons.sliders, size: 14),
            onPressed: () => SoundscapeSelectorSheet.show(context),
            tooltip: 'Soundscape selector',
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformBars(bool isPlaying, Color accent) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final val = _animController.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _bar(isPlaying ? 6.0 + 8.0 * val : 4.0, accent, isPlaying),
            const SizedBox(width: 2),
            _bar(isPlaying ? 14.0 - 6.0 * val : 6.0, accent, isPlaying),
            const SizedBox(width: 2),
            _bar(isPlaying ? 8.0 + 10.0 * (1 - val) : 4.0, accent, isPlaying),
            const SizedBox(width: 2),
            _bar(isPlaying ? 5.0 + 9.0 * val : 5.0, accent, isPlaying),
          ],
        );
      },
    );
  }

  Widget _bar(double height, Color accent, bool isPlaying) {
    return Container(
      width: 2.5,
      height: height,
      decoration: BoxDecoration(
        color: isPlaying ? accent : Colors.grey.shade600,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
