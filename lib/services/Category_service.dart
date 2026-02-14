import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/CategoryModel.dart';

class CategoryService {
  final ApiService _api = ApiService();

  // Get all categories
  Future<List<CategoryModel>> getAllCategories() async {
    final response = await _api.get('/categories');
    return (response as List)
        .map((json) => CategoryModel.fromJson(json))
        .toList();
  }

  // Get categories by type (expense or income)
  Future<List<CategoryModel>> getCategoriesByType(String type) async {
    final response = await _api.get('/categories/type/$type');
    return (response as List)
        .map((json) => CategoryModel.fromJson(json))
        .toList();
  }

  // Get single category by name
  Future<CategoryModel> getCategoryByName(String name) async {
    final response = await _api.get('/categories/name/$name');
    return CategoryModel.fromJson(response);
  }
}