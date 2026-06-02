import '../models/category_model.dart';
import 'api_client.dart';

class CategoryService {
  /// Ambil semua kategori
  static Future<List<Category>> fetchCategories() async {
    final response = await ApiClient.client
        .from('categories')
        .select()
        .order('id', ascending: true);

    return (response as List)
        .map((json) => Category.fromJson(json))
        .toList();
  }
}
