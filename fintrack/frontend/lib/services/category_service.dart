import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/category_model.dart';

class CategoryService {
  final ApiClient apiClient;

  CategoryService({required this.apiClient});

  Future<List<CategoryModel>> getCategories({String? type}) async {
    final queryParams = <String, dynamic>{};
    if (type != null && type.isNotEmpty && type.toLowerCase() != 'all') {
      queryParams['type'] = type.toLowerCase();
    }

    final response = await apiClient.get(
      ApiConstants.categories,
      queryParams: queryParams,
    );

    final list = (response as List<dynamic>)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<CategoryModel> createCategory(CategoryModel category) async {
    final response = await apiClient.post(
      ApiConstants.categories,
      body: category.toJson(),
    );
    return CategoryModel.fromJson(response as Map<String, dynamic>);
  }
}
