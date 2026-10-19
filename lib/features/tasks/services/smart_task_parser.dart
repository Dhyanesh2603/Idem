import '../models/task_priority.dart';

class ParsedTaskMetadata {
  final String title;
  final TaskPriority priority;
  final String? categoryName;
  final DateTime? deadline;
  final int? estimatedMinutes;

  const ParsedTaskMetadata({
    required this.title,
    this.priority = TaskPriority.none,
    this.categoryName,
    this.deadline,
    this.estimatedMinutes,
  });
}

class SmartTaskParser {
  /// Parses natural language text with inline tags:
  /// Priorities: !high, !med, !low, !urgent, !p1, !p2, !p3
  /// Categories: #Work, #Personal, #Dev
  /// Estimates: ~30m, ~1h, ~45min, ~2h
  /// Dates: today, tomorrow, tonight, next week, at 5pm, 17:00
  static ParsedTaskMetadata parse(String input, {DateTime? referenceTime}) {
    final now = referenceTime ?? DateTime.now();
    var workingText = input.trim();
    TaskPriority priority = TaskPriority.none;
    String? categoryName;
    DateTime? deadline;
    int? estimatedMinutes;

    if (workingText.isEmpty) {
      return const ParsedTaskMetadata(title: '');
    }

    // 1. Parse Priority (!high, !urgent, !p1, !med, !low)
    final priorityRegex = RegExp(r'(?:^|\s)!([a-zA-Z0-9]+)\b');
    final pMatch = priorityRegex.firstMatch(workingText);
    if (pMatch != null) {
      final tag = pMatch.group(1)!.toLowerCase();
      if (tag == 'high' || tag == 'urgent' || tag == 'p1') {
        priority = TaskPriority.high;
      } else if (tag == 'med' || tag == 'medium' || tag == 'p2') {
        priority = TaskPriority.medium;
      } else if (tag == 'low' || tag == 'p3') {
        priority = TaskPriority.low;
      }
      workingText = workingText.replaceFirst(pMatch.group(0)!, ' ');
    }

    // 2. Parse Category (#CategoryName)
    final categoryRegex = RegExp(r'(?:^|\s)#([a-zA-Z0-9_-]+)\b');
    final cMatch = categoryRegex.firstMatch(workingText);
    if (cMatch != null) {
      categoryName = cMatch.group(1);
      workingText = workingText.replaceFirst(cMatch.group(0)!, ' ');
    }

    // 3. Parse Estimated Time (~30m, ~1h, ~45min)
    final estimateRegex = RegExp(r'(?:^|\s)~([0-9]+)\s*(m|min|mins|h|hr|hrs|hours?)\b', caseSensitive: false);
    final eMatch = estimateRegex.firstMatch(workingText);
    if (eMatch != null) {
      final val = int.tryParse(eMatch.group(1)!) ?? 0;
      final unit = eMatch.group(2)!.toLowerCase();
      if (unit.startsWith('h')) {
        estimatedMinutes = val * 60;
      } else {
        estimatedMinutes = val;
      }
      workingText = workingText.replaceFirst(eMatch.group(0)!, ' ');
    }

    // 4. Parse Relative Dates & Times (today, tomorrow, tonight, at HH:mm)
    final lower = workingText.toLowerCase();

    // Check "tomorrow"
    if (lower.contains('tomorrow')) {
      final tm = now.add(const Duration(days: 1));
      deadline = DateTime(tm.year, tm.month, tm.day, 18, 0); // Default to 6 PM
      workingText = workingText.replaceAll(RegExp(r'\btomorrow\b', caseSensitive: false), ' ');
    } else if (lower.contains('tonight')) {
      deadline = DateTime(now.year, now.month, now.day, 21, 0); // 9 PM tonight
      workingText = workingText.replaceAll(RegExp(r'\btonight\b', caseSensitive: false), ' ');
    } else if (lower.contains('today')) {
      deadline = DateTime(now.year, now.month, now.day, 18, 0);
      workingText = workingText.replaceAll(RegExp(r'\btoday\b', caseSensitive: false), ' ');
    }

    // Check specific time format: "at 5pm", "at 17:00", "5pm", "3:30pm"
    final timeRegex = RegExp(r'(?:at\s+)?\b([0-1]?[0-9]|2[0-3])(?::([0-5][0-9]))?\s*(am|pm)\b', caseSensitive: false);
    final tMatch = timeRegex.firstMatch(workingText);
    if (tMatch != null) {
      var hour = int.parse(tMatch.group(1)!);
      final minute = tMatch.group(2) != null ? int.parse(tMatch.group(2)!) : 0;
      final period = tMatch.group(3)!.toLowerCase();

      if (period == 'pm' && hour < 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;

      final targetDate = deadline ?? DateTime(now.year, now.month, now.day);
      deadline = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
      workingText = workingText.replaceFirst(tMatch.group(0)!, ' ');
    }

    // Clean multiple whitespace
    final cleanTitle = workingText.replaceAll(RegExp(r'\s+'), ' ').trim();

    return ParsedTaskMetadata(
      title: cleanTitle.isEmpty ? input.trim() : cleanTitle,
      priority: priority,
      categoryName: categoryName,
      deadline: deadline,
      estimatedMinutes: estimatedMinutes,
    );
  }
}
