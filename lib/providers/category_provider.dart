import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class CategoryNotifier extends StateNotifier<List<Category>> {
  CategoryNotifier() : super([]) {
    loadCategories();
  }

  final _dbService = DatabaseService();

  Future<void> loadCategories() async {
    state = await _dbService.getCategories();
  }

  Future<void> addCategory(Category category) async {
    await _dbService.insertCategory(category);
    await loadCategories();
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  return CategoryNotifier();
});
