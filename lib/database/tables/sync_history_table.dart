import 'package:drift/drift.dart';

/// Table schema for Sync Execution History.
@DataClassName('SyncHistoryEntry')
class SyncHistory extends Table {
  /// Unique entry UUID
  TextColumn get id => text()();

  /// Execution timestamp
  DateTimeColumn get timestamp => dateTime()();

  /// Overall run status: 'success', 'failure'
  TextColumn get status => text()();

  /// Number of operations successfully pushed or pulled
  IntColumn get changesCount => integer().withDefault(const Constant(0))();

  /// Error summary if failed
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
