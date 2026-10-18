import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../../../database/database_provider.dart';

/// Stream provider for all categories
final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchCategories();
});

/// Notifier for currently selected category filter
class SelectedCategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectCategory(String? categoryId) {
    state = categoryId;
  }
}

/// Currently selected category filter provider
final selectedCategoryFilterProvider =
    NotifierProvider<SelectedCategoryFilterNotifier, String?>(
  SelectedCategoryFilterNotifier.new,
);
