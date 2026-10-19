import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian_slate/features/tasks/models/task_priority.dart';
import 'package:obsidian_slate/features/tasks/services/smart_task_parser.dart';

void main() {
  group('SmartTaskParser Tests', () {
    test('Parses priority, category, duration, and tomorrow deadline', () {
      final refTime = DateTime(2026, 10, 19, 10, 0);
      final res = SmartTaskParser.parse(
        'Deploy release to staging tomorrow at 5pm !high #DevOps ~45m',
        referenceTime: refTime,
      );

      expect(res.title, 'Deploy release to staging');
      expect(res.priority, TaskPriority.high);
      expect(res.categoryName, 'DevOps');
      expect(res.estimatedMinutes, 45);
      expect(res.deadline, isNotNull);
      expect(res.deadline!.day, 20);
      expect(res.deadline!.hour, 17);
      expect(res.deadline!.minute, 0);
    });

    test('Parses plain task without altering simple title', () {
      final res = SmartTaskParser.parse('Buy groceries');
      expect(res.title, 'Buy groceries');
      expect(res.priority, TaskPriority.none);
      expect(res.categoryName, isNull);
      expect(res.deadline, isNull);
    });

    test('Parses priority alias !urgent and duration in hours ~2h', () {
      final res = SmartTaskParser.parse('Refactor sync engine !urgent ~2h');
      expect(res.title, 'Refactor sync engine');
      expect(res.priority, TaskPriority.high);
      expect(res.estimatedMinutes, 120);
    });
  });
}
