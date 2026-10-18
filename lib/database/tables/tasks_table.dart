import 'package:drift/drift.dart';

/// Table schema for Tasks.
@DataClassName('TaskEntry')
class Tasks extends Table {
  /// Unique client-generated UUID
  TextColumn get id => text()();

  /// Task title
  TextColumn get title => text().withLength(min: 1, max: 500)();

  /// Extended notes or markdown description
  TextColumn get description => text().withDefault(const Constant(''))();

  /// Completion status
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// Timestamp when completed
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Priority level: 'urgent', 'high', 'medium', 'low', 'none'
  TextColumn get priority => text().withDefault(const Constant('none'))();

  /// Optional deadline or scheduled date
  DateTimeColumn get deadline => dateTime().nullable()();

  /// Category / Tag foreign reference
  TextColumn get categoryId => text().nullable()();

  /// Sort order index for drag & drop
  RealColumn get orderIndex => real().withDefault(const Constant(0.0))();

  /// Flag indicating this is part of today's focused tasks
  BoolColumn get isFocus => boolean().withDefault(const Constant(false))();

  /// Recurring rule: 'none', 'daily', 'weekdays', 'weekly', 'monthly'
  TextColumn get recurringRule => text().withDefault(const Constant('none'))();

  /// Parent task id for subtasks
  TextColumn get parentTaskId => text().nullable()();

  /// Estimated time in minutes
  IntColumn get estimatedMinutes => integer().withDefault(const Constant(0))();

  /// Actual time logged in minutes
  IntColumn get timeSpentMinutes => integer().withDefault(const Constant(0))();

  /// Timestamps for synchronization & conflict resolution
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Server version number for Last-Write-Wins and optimistic concurrency
  IntColumn get serverVersion => integer().withDefault(const Constant(1))();

  /// Soft deletion flag to support distributed sync deletion propagation
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// Sync state: 'synced', 'pending', 'failed'
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
