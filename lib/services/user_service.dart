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
}
