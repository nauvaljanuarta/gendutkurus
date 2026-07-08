import 'dart:typed_data';
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

  /// Mengunggah gambar profil ke Supabase Storage (bucket: avatars) dan menyimpan URL di database
  static Future<String> uploadAvatar({
    required String userId,
    required Uint8List fileBytes,
    required String fileExtension,
  }) async {
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

    // 1. Upload file ke storage avatars
    await ApiClient.client.storage.from('avatars').uploadBinary(
          fileName,
          fileBytes,
        );

    // 2. Dapatkan URL public dari file yang diunggah
    final publicUrl = ApiClient.client.storage.from('avatars').getPublicUrl(fileName);

    // 3. Update data users.avatar_url di database
    await ApiClient.client
        .from('users')
        .update({
          'avatar_url': publicUrl,
        })
        .eq('id', userId);

    return publicUrl;
  }
}
