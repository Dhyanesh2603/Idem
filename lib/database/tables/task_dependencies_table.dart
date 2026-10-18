import 'package:drift/drift.dart';

/// Table schema for Task Dependencies.
///
/// Models a directed relationship where [blockedTaskId] depends on [blockerTaskId]
/// to be completed first.
@DataClassName('TaskDependencyEntry')
class TaskDependencies extends Table {
  /// Unique client-generated UUID
  TextColumn get id => text()();

  /// ID of the prerequisite task that must be completed
  TextColumn get blockerTaskId => text()();

  /// ID of the task that is blocked
  TextColumn get blockedTaskId => text()();

  /// Timestamp created
  DateTimeColumn get createdAt => dateTime()();

  /// Soft deletion
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
