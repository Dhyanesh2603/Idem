import 'package:drift/drift.dart';

/// Table schema for Categories / Projects.
@DataClassName('CategoryEntry')
class Categories extends Table {
  /// Unique client-generated UUID
  TextColumn get id => text()();

  /// Category name
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Hex representation of category color, e.g. '#34D399'
  TextColumn get colorHex => text().withDefault(const Constant('#94A3B8'))();

  /// Lucide icon identifier string
  TextColumn get iconName => text().withDefault(const Constant('tag'))();

  /// Timestamps
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Soft deletion
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// Sync state: 'synced', 'pending', 'failed'
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
