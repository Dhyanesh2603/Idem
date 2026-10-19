import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obsidian_slate/features/focus/services/soundscape_service.dart';

void main() {
  group('Soundscape & Acoustic Station Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial soundscape state is silent and inactive', () {
      final state = container.read(soundscapeProvider);
      expect(state.activeType, SoundscapeType.none);
      expect(state.isPlaying, isFalse);
      expect(state.volume, 0.5);
      expect(state.isBreathingActive, isFalse);
    });

    test('Selecting track updates activeType and starts playback state', () {
      final notifier = container.read(soundscapeProvider.notifier);

      notifier.play(SoundscapeType.brownNoise);
      var state = container.read(soundscapeProvider);
      expect(state.activeType, SoundscapeType.brownNoise);
      expect(state.isPlaying, isTrue);

      notifier.play(SoundscapeType.binaural40);
      state = container.read(soundscapeProvider);
      expect(state.activeType, SoundscapeType.binaural40);
      expect(state.isPlaying, isTrue);

      notifier.stop();
      state = container.read(soundscapeProvider);
      expect(state.isPlaying, isFalse);
    });

    test('Volume clamping maintains values between 0.0 and 1.0', () {
      final notifier = container.read(soundscapeProvider.notifier);

      notifier.setVolume(0.8);
      expect(container.read(soundscapeProvider).volume, 0.8);

      notifier.setVolume(1.5);
      expect(container.read(soundscapeProvider).volume, 1.0);

      notifier.setVolume(-0.2);
      expect(container.read(soundscapeProvider).volume, 0.0);
    });

    test('Box breathing toggle activates 4-4-4-4 rhythm state', () {
      final notifier = container.read(soundscapeProvider.notifier);

      expect(container.read(soundscapeProvider).isBreathingActive, isFalse);
      notifier.toggleBreathing();
      expect(container.read(soundscapeProvider).isBreathingActive, isTrue);
      expect(container.read(soundscapeProvider).breathingPhase, BreathingPhase.inhale);
      expect(container.read(soundscapeProvider).breathingCountdown, 4);

      notifier.toggleBreathing();
      expect(container.read(soundscapeProvider).isBreathingActive, isFalse);
    });
  });
}
