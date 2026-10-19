import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/habit_model.dart';

const String _kHabitsStorageKey = 'idem_habits_data_v1';

class HabitsNotifier extends Notifier<List<HabitModel>> {
  @override
  List<HabitModel> build() {
    _loadHabits();
    return _defaultHabits();
  }

  static List<HabitModel> _defaultHabits() {
    return const [
      HabitModel(
        id: 'habit_deep_work',
        title: '90m Deep Focus Block',
        description: 'Single-task immersion with no notifications',
        iconName: 'zap',
        timeOfDay: 'morning',
        streakCount: 5,
      ),
      HabitModel(
        id: 'habit_inbox_zero',
        title: 'Inbox Zero Triage',
        description: 'Process incoming captures into structured actions',
        iconName: 'inbox',
        timeOfDay: 'morning',
        streakCount: 3,
      ),
      HabitModel(
        id: 'habit_code_practice',
        title: 'Architecture & Skill Mastery',
        description: 'Daily algorithmic problem solving or technical reading',
        iconName: 'code',
        timeOfDay: 'afternoon',
        streakCount: 7,
      ),
      HabitModel(
        id: 'habit_movement',
        title: 'Physical Movement & Walk',
        description: 'Reset mental fatigue and improve circulation',
        iconName: 'activity',
        timeOfDay: 'afternoon',
        streakCount: 4,
      ),
      HabitModel(
        id: 'habit_shutdown',
        title: 'Daily Shutdown Ritual',
        description: 'Review accomplishments, clear slate, and plan tomorrow',
        iconName: 'sunset',
        timeOfDay: 'evening',
        streakCount: 6,
      ),
    ];
  }

  Future<void> _loadHabits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kHabitsStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final loaded = decoded.map((e) => HabitModel.fromJson(e as Map<String, dynamic>)).toList();
        state = loaded;
      } else {
        // Save defaults
        await _saveHabits(state);
      }
    } catch (_) {
      // Fallback to default
    }
  }

  Future<void> _saveHabits(List<HabitModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(list.map((h) => h.toJson()).toList());
      await prefs.setString(_kHabitsStorageKey, raw);
    } catch (_) {}
  }

  int _calculateStreak(List<String> completedDates) {
    if (completedDates.isEmpty) return 0;
    final now = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');

    final todayStr = fmt.format(now);
    final yesterdayStr = fmt.format(now.subtract(const Duration(days: 1)));

    // If neither today nor yesterday is completed, streak is broken
    if (!completedDates.contains(todayStr) && !completedDates.contains(yesterdayStr)) {
      return 0;
    }

    int streak = 0;
    var checkDate = completedDates.contains(todayStr) ? now : now.subtract(const Duration(days: 1));

    while (true) {
      final dateStr = fmt.format(checkDate);
      if (completedDates.contains(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> toggleHabit(String id) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final updated = state.map((h) {
      if (h.id != id) return h;
      final dates = List<String>.from(h.completedDates);
      if (dates.contains(todayStr)) {
        dates.remove(todayStr);
      } else {
        dates.add(todayStr);
      }
      final newStreak = _calculateStreak(dates);
      return h.copyWith(completedDates: dates, streakCount: newStreak);
    }).toList();

    state = updated;
    await _saveHabits(updated);
  }

  Future<void> addHabit({
    required String title,
    required String description,
    required String timeOfDay,
    required String iconName,
  }) async {
    final newHabit = HabitModel(
      id: const Uuid().v4(),
      title: title,
      description: description,
      timeOfDay: timeOfDay,
      iconName: iconName,
      streakCount: 0,
      completedDates: [],
    );

    final updated = [...state, newHabit];
    state = updated;
    await _saveHabits(updated);
  }

  Future<void> deleteHabit(String id) async {
    final updated = state.where((h) => h.id != id).toList();
    state = updated;
    await _saveHabits(updated);
  }
}

final habitsNotifierProvider =
    NotifierProvider<HabitsNotifier, List<HabitModel>>(() {
  return HabitsNotifier();
});
