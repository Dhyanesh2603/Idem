import 'package:drift/drift.dart';

/// Table schema for Daily Planning Sessions.
@DataClassName('DailyPlanEntry')
class DailyPlans extends Table {
  /// Unique plan UUID
  TextColumn get id => text()();

  /// Normalized date string (e.g. '2026-10-18')
  TextColumn get planDate => text()();

  /// Recommended or user-chosen focus target count (typically 3 to 5)
  IntColumn get targetTaskCount => integer().withDefault(const Constant(3))();

  /// End-of-day reflection or notes
  TextColumn get reflectionNotes => text().nullable()();

  /// Completed planning milestone
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// Timestamps
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
