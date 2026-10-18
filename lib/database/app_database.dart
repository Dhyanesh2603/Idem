import 'package:drift/drift.dart';
import 'tables/tasks_table.dart';
import 'tables/categories_table.dart';
import 'tables/task_dependencies_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/sync_history_table.dart';
import 'tables/daily_plans_table.dart';
import 'connection/connection.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Tasks,
    Categories,
    TaskDependencies,
    SyncQueue,
    SyncHistory,
    DailyPlans,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? DatabaseConnectionFactory.connect());

  /// Factory for testing with an isolated in-memory database
  factory AppDatabase.forTesting(QueryExecutor executor) {
    return AppDatabase(executor);
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Future schema migrations are declared explicitly here
        },
        beforeOpen: (details) async {
          // Enable foreign keys and WAL mode if supported
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );
}
