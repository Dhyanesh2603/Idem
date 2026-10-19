import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_interop.dart';

enum SoundscapeType {
  none('Silent', 'No audio playing', 'mute'),
  brownNoise('Deep Brown Noise', 'ADHD focus & deep distraction blocking', 'brown'),
  pinkNoise('Calm Pink Noise', 'Natural balanced spectrum for cognitive flow', 'pink'),
  binaural40('40Hz Gamma Focus', 'Scientific binaural beat for working memory', 'binaural40'),
  rain('Rain on Glass', 'Procedural soothing raindrops with ambient filter', 'rain'),
  whiteNoise('Pure White Noise', 'High-frequency speech masking', 'white');

  final String title;
  final String description;
  final String audioCode;
  const SoundscapeType(this.title, this.description, this.audioCode);
}

enum BreathingPhase {
  inhale('Inhale deeply (4s)'),
  holdIn('Hold breath (4s)'),
  exhale('Exhale slowly (4s)'),
  holdOut('Rest (4s)');

  final String prompt;
  const BreathingPhase(this.prompt);
}

class SoundscapeState {
  final SoundscapeType activeType;
  final bool isPlaying;
  final double volume;
  final bool isBreathingActive;
  final BreathingPhase breathingPhase;
  final int breathingCountdown;

  const SoundscapeState({
    this.activeType = SoundscapeType.none,
    this.isPlaying = false,
    this.volume = 0.5,
    this.isBreathingActive = false,
    this.breathingPhase = BreathingPhase.inhale,
    this.breathingCountdown = 4,
  });

  SoundscapeState copyWith({
    SoundscapeType? activeType,
    bool? isPlaying,
    double? volume,
    bool? isBreathingActive,
    BreathingPhase? breathingPhase,
    int? breathingCountdown,
  }) {
    return SoundscapeState(
      activeType: activeType ?? this.activeType,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
      isBreathingActive: isBreathingActive ?? this.isBreathingActive,
      breathingPhase: breathingPhase ?? this.breathingPhase,
      breathingCountdown: breathingCountdown ?? this.breathingCountdown,
    );
  }
}

class SoundscapeNotifier extends Notifier<SoundscapeState> {
  Timer? _breathingTimer;

  @override
  SoundscapeState build() {
    ref.onDispose(() {
      _breathingTimer?.cancel();
      platformStopAudio();
    });
    return const SoundscapeState();
  }

  void play(SoundscapeType type) {
    if (type == SoundscapeType.none) {
      stop();
      return;
    }
    platformPlayAudio(type.audioCode, state.volume);
    state = state.copyWith(activeType: type, isPlaying: true);
  }

  void toggle() {
    if (state.isPlaying) {
      platformStopAudio();
      state = state.copyWith(isPlaying: false);
    } else {
      final target = state.activeType == SoundscapeType.none
          ? SoundscapeType.brownNoise
          : state.activeType;
      play(target);
    }
  }

  void setVolume(double volume) {
    final clamped = volume.clamp(0.0, 1.0);
    platformSetVolume(clamped);
    state = state.copyWith(volume: clamped);
  }

  void stop() {
    platformStopAudio();
    state = state.copyWith(activeType: SoundscapeType.none, isPlaying: false);
  }

  void toggleBreathing() {
    if (state.isBreathingActive) {
      _breathingTimer?.cancel();
      state = state.copyWith(isBreathingActive: false);
    } else {
      state = state.copyWith(
        isBreathingActive: true,
        breathingPhase: BreathingPhase.inhale,
        breathingCountdown: 4,
      );
      _breathingTimer?.cancel();
      _breathingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _tickBreathing();
      });
    }
  }

  void _tickBreathing() {
    if (state.breathingCountdown > 1) {
      state = state.copyWith(breathingCountdown: state.breathingCountdown - 1);
    } else {
      BreathingPhase nextPhase;
      switch (state.breathingPhase) {
        case BreathingPhase.inhale:
          nextPhase = BreathingPhase.holdIn;
          break;
        case BreathingPhase.holdIn:
          nextPhase = BreathingPhase.exhale;
          break;
        case BreathingPhase.exhale:
          nextPhase = BreathingPhase.holdOut;
          break;
        case BreathingPhase.holdOut:
          nextPhase = BreathingPhase.inhale;
          break;
      }
      state = state.copyWith(
        breathingPhase: nextPhase,
        breathingCountdown: 4,
      );
    }
  }
}

final soundscapeProvider =
    NotifierProvider<SoundscapeNotifier, SoundscapeState>(() {
  return SoundscapeNotifier();
});
