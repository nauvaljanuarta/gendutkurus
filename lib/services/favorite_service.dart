import '../models/gym_model.dart';
import 'api_client.dart';

class FavoriteService {
  /// Ambil favorit berdasarkan user_id
  static Future<List<Gym>> fetchFavorites(String userId) async {
    final response = await ApiClient.client
        .from('favorites')
        .select('gym_id, gyms(*, categories(name, icon))')
        .eq('user_id', userId);

    return (response as List)
        .where((item) => item['gyms'] != null)
        .map((item) => Gym.fromJson(item['gyms']))
        .toList();
  }

  /// Cek apakah gym sudah difavoritkan oleh user
  static Future<bool> isFavorite(String userId, int gymId) async {
    final response = await ApiClient.client
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('gym_id', gymId)
        .maybeSingle();

    return response != null;
  }

  /// Toggle favorit — tambah jika belum, hapus jika sudah
  static Future<bool> toggleFavorite(String userId, int gymId) async {
    final existing = await ApiClient.client
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('gym_id', gymId)
        .maybeSingle();

    if (existing != null) {
      await ApiClient.client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('gym_id', gymId);
      return false; // Dihapus dari favorit
    } else {
      await ApiClient.client.from('favorites').insert({
        'user_id': userId,
        'gym_id': gymId,
      });
      return true; // Ditambahkan ke favorit
    }
  }
}
