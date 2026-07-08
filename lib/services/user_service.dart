import '../models/user_model.dart';
import 'api_client.dart';

class UserService {
  /// Mengambil profil pengguna dari tabel users
  static Future<UserModel?> fetchUserProfile(String id) async {
    final response = await ApiClient.client
        .from('users')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  /// Memperbarui preferensi kategori minat pengguna
  static Future<void> updateUserInterests(String userId, List<int> categoryIds) async {
    await ApiClient.client
        .from('users')
        .update({
          'interest_category_ids': categoryIds,
        })
        .eq('id', userId);
  }
}
