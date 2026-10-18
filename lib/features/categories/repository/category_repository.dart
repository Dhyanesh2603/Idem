import '../models/category_model.dart';

/// Clean repository interface for Category operations.
abstract class CategoryRepository {
  /// Watches all active non-deleted categories
  Stream<List<CategoryModel>> watchCategories();

  /// Retrieves list of all categories
  Future<List<CategoryModel>> getCategories();

  /// Retrieves single category by ID
  Future<CategoryModel?> getCategoryById(String id);

  /// Creates a category, writes locally, enqueues sync op
  Future<CategoryModel> createCategory({
    required String name,
    String colorHex = '#94A3B8',
    String iconName = 'tag',
  });

  /// Updates existing category
  Future<CategoryModel> updateCategory(CategoryModel category);

  /// Soft deletes category
  Future<void> deleteCategory(String id);
}
