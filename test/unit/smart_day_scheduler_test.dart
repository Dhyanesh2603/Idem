import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian_slate/features/tasks/models/task_model.dart';
import 'package:obsidian_slate/features/tasks/models/task_priority.dart';
import 'package:obsidian_slate/features/today/services/smart_day_scheduler.dart';

void main() {
  group('SmartDayScheduler Tests', () {
    test('generatePlan chronologically packs tasks and prioritizes urgent items', () {
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day, 9, 0);

      final taskLow = TaskModel(
        id: '1',
        title: 'Check release notes',
        priority: TaskPriority.low,
        estimatedMinutes: 30,
        createdAt: now,
        updatedAt: now,
      );

      final taskUrgent = TaskModel(
        id: '2',
        title: 'Fix critical auth vulnerability',
        priority: TaskPriority.urgent,
        estimatedMinutes: 60,
        createdAt: now,
        updatedAt: now,
      );

      final taskHigh = TaskModel(
        id: '3',
        title: 'Code review PR #405',
        priority: TaskPriority.high,
        estimatedMinutes: 45,
        createdAt: now,
        updatedAt: now,
      );

      final plan = SmartDayScheduler.generatePlan(
        tasks: [taskLow, taskUrgent, taskHigh],
        dayStart: dayStart,
      );

      expect(plan.slots.length, 3);
      // Urgent task should be first
      expect(plan.slots[0].task.id, '2');
      expect(plan.slots[0].startTime, dayStart);
      expect(plan.slots[0].endTime, dayStart.add(const Duration(minutes: 60)));

      // High priority task should be second (starts 10 min buffer after urgent)
      expect(plan.slots[1].task.id, '3');
      expect(plan.slots[1].startTime, dayStart.add(const Duration(minutes: 70)));

      // Total minutes calculation
      expect(plan.totalMinutes, 135);
      expect(plan.cognitiveLoadLevel, 'Light');
    });

    test('generatePlan avoids scheduling during lunch break', () {
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day, 12, 0);

      final longTask = TaskModel(
        id: 'long',
        title: 'Long architecture writeup',
        priority: TaskPriority.urgent,
        estimatedMinutes: 60, // 12:00 -> 13:00 would cross 12:30 lunch!
        createdAt: now,
        updatedAt: now,
      );

      final plan = SmartDayScheduler.generatePlan(
        tasks: [longTask],
        dayStart: dayStart,
      );

      // Should be bumped to start at 13:15
      expect(plan.slots.first.startTime.hour, 13);
      expect(plan.slots.first.startTime.minute, 15);
    });
  });
}
