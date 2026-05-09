import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/hive_service.dart';
import '../models/category.dart';

final categoryProvider = StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  return CategoryNotifier();
});

class CategoryNotifier extends StateNotifier<List<Category>> {
  CategoryNotifier() : super([]) {
    _loadCategories();
  }

  void _loadCategories() {
    state = HiveService.categoryBox.values.toList();
  }

  Future<void> addCategory(Category category) async {
    await HiveService.categoryBox.put(category.id, category);
    state = [...state, category];
  }
}
