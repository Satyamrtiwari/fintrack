import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import 'api_providers.dart';

final categoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final service = ref.watch(categoryServiceProvider);
  return await service.getCategories();
});

final incomeCategoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final service = ref.watch(categoryServiceProvider);
  return await service.getCategories(type: 'income');
});

final expenseCategoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final service = ref.watch(categoryServiceProvider);
  return await service.getCategories(type: 'expense');
});
