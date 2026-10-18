import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Provides an isolated in-memory SQLite database instance for unit tests.
QueryExecutor constructInMemoryDatabase() {
  return NativeDatabase.memory();
}
