import '../models/gym_model.dart';
import 'api_client.dart';

class FavoriteService {
  /// Ambil favorit berdasarkan user_id, lengkap dengan cumulative rating
  static Future<List<Gym>> fetchFavorites(String userId) async {
    final response = await ApiClient.client
        .from('favorites')
        .select('gym_id, gyms(*, categories(name, icon), gym_images(image_url))')
        .eq('user_id', userId);

    final gyms = (response as List)
        .where((item) => item['gyms'] != null)
        .map((item) => Gym.fromJson(item['gyms']))
        .toList();

    if (gyms.isEmpty) return gyms;

    // Ambil gym_id untuk fetch reviews
    final gymIds = gyms.map((g) => g.gymId).toList();

    List reviewsResponse = [];
    try {
      reviewsResponse = await ApiClient.client
          .from('reviews')
          .select('gym_id, rating')
          .inFilter('gym_id', gymIds);
    } catch (_) {
      // Jika query reviews gagal, tampilkan dengan rating Google saja
    }

    // Kelompokkan review per gym_id
    final Map<int, List<int>> reviewsByGym = {};
    for (final r in reviewsResponse) {
      final gymId = r['gym_id'] as int;
      final rating = (r['rating'] as num).toInt();
      reviewsByGym.putIfAbsent(gymId, () => []).add(rating);
    }

    // Merge: attach app review stats ke setiap gym
    return gyms.map((gym) {
      final ratings = reviewsByGym[gym.gymId] ?? [];
      return gym.copyWithAppStats(
        appReviewSum: ratings.fold<int>(0, (sum, r) => sum + r),
        appReviewCount: ratings.length,
      );
    }).toList();
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
