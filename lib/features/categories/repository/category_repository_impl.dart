import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../database/app_database.dart';
import '../models/category_model.dart';
import '../../sync/models/sync_operation.dart';
import '../../sync/repository/sync_queue_repository.dart';
import 'category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final AppDatabase _db;
  final SyncQueueRepository _syncQueue;
  final Uuid _uuid;

  CategoryRepositoryImpl(
    this._db,
    this._syncQueue, [
    Uuid? uuid,
  ]) : _uuid = uuid ?? const Uuid();

  @override
  Stream<List<CategoryModel>> watchCategories() {
    final query = _db.select(_db.categories)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc)]);

    return query.watch().map((entries) => entries.map(CategoryModel.fromEntry).toList());
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final entries = await (_db.select(_db.categories)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc)]))
        .get();

    return entries.map(CategoryModel.fromEntry).toList();
  }

  @override
  Future<CategoryModel?> getCategoryById(String id) async {
    final entry = await (_db.select(_db.categories)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return entry != null ? CategoryModel.fromEntry(entry) : null;
  }

  @override
  Future<CategoryModel> createCategory({
    required String name,
    String colorHex = '#94A3B8',
    String iconName = 'tag',
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    final entry = CategoriesCompanion.insert(
      id: id,
      name: name.trim(),
      colorHex: Value(colorHex),
      iconName: Value(iconName),
      createdAt: now,
      updatedAt: now,
      syncStatus: const Value('pending'),
    );

    await _db.into(_db.categories).insert(entry);

    final model = CategoryModel(
      id: id,
      name: name.trim(),
      colorHex: colorHex,
      iconName: iconName,
      createdAt: now,
      updatedAt: now,
      syncStatus: 'pending',
    );

    await _syncQueue.enqueue(
      entityType: 'category',
      entityId: id,
      operationType: SyncOperationType.create,
      payload: jsonEncode(model.toJson()),
    );

    return model;
  }

  @override
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    final now = DateTime.now();
    final updated = category.copyWith(updatedAt: now, syncStatus: 'pending');

    await (_db.update(_db.categories)..where((tbl) => tbl.id.equals(category.id))).write(
      CategoriesCompanion(
        name: Value(updated.name),
        colorHex: Value(updated.colorHex),
        iconName: Value(updated.iconName),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );

    await _syncQueue.enqueue(
      entityType: 'category',
      entityId: category.id,
      operationType: SyncOperationType.update,
      payload: jsonEncode(updated.toJson()),
    );

    return updated;
  }

  @override
  Future<void> deleteCategory(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.categories)..where((tbl) => tbl.id.equals(id))).write(
      CategoriesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );

    await _syncQueue.enqueue(
      entityType: 'category',
      entityId: id,
      operationType: SyncOperationType.delete,
      payload: jsonEncode({'id': id, 'is_deleted': true, 'updated_at': now.toIso8601String()}),
    );
  }
}
