// ignore_for_file: deprecated_member_use
import 'package:drift/drift.dart';
import 'package:drift/web.dart';

abstract final class DatabaseConnectionFactory {
  static QueryExecutor connect({String dbName = 'obsidian_slate.sqlite'}) {
    return WebDatabase(dbName);
  }

  static QueryExecutor inMemory() {
    return WebDatabase.withStorage(DriftWebStorage.volatile());
  }
}
