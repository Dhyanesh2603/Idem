import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:obsidian_slate/features/habits/models/habit_model.dart';

void main() {
  group('Habits & Rituals Model Tests', () {
    test('HabitModel serialization and deserialization roundtrip', () {
      const habit = HabitModel(
        id: 'h1',
        title: 'Morning Deep Work',
        description: 'Single-task immersion',
        iconName: 'zap',
        timeOfDay: 'morning',
        streakCount: 5,
        completedDates: ['2026-10-18', '2026-10-19'],
      );

      final json = habit.toJson();
      final roundtrip = HabitModel.fromJson(json);

      expect(roundtrip.id, 'h1');
      expect(roundtrip.title, 'Morning Deep Work');
      expect(roundtrip.streakCount, 5);
      expect(roundtrip.completedDates.length, 2);
      expect(roundtrip.timeOfDay, 'morning');
    });

    test('isCompletedToday reflects current day match', () {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final yesterdayStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));

      final habitDone = HabitModel(
        id: 'h2',
        title: 'Workout',
        description: '',
        iconName: 'activity',
        timeOfDay: 'afternoon',
        completedDates: [todayStr, yesterdayStr],
      );

      final habitPending = HabitModel(
        id: 'h3',
        title: 'Shutdown',
        description: '',
        iconName: 'sunset',
        timeOfDay: 'evening',
        completedDates: [yesterdayStr],
      );

      expect(habitDone.isCompletedToday, isTrue);
      expect(habitPending.isCompletedToday, isFalse);
    });
  });
}
