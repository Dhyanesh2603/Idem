/// Recurrence pattern for recurring tasks.
enum RecurringRule {
  none('Does not repeat'),
  daily('Daily'),
  weekdays('Every Weekday (Mon–Fri)'),
  weekly('Weekly'),
  monthly('Monthly');

  const RecurringRule(this.displayName);

  final String displayName;

  static RecurringRule fromString(String? value) {
    if (value == null) return RecurringRule.none;
    return RecurringRule.values.firstWhere(
      (r) => r.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RecurringRule.none,
    );
  }

  /// Calculates the next deadline based on the recurring pattern.
  DateTime? computeNextDeadline(DateTime from) {
    switch (this) {
      case RecurringRule.none:
        return null;
      case RecurringRule.daily:
        return from.add(const Duration(days: 1));
      case RecurringRule.weekdays:
        DateTime next = from.add(const Duration(days: 1));
        while (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case RecurringRule.weekly:
        return from.add(const Duration(days: 7));
      case RecurringRule.monthly:
        return DateTime(from.year, from.month + 1, from.day, from.hour, from.minute);
    }
  }
}
