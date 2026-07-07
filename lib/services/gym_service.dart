import '../models/gym_model.dart';
import 'api_client.dart';

class GymService {
  /// Ambil semua gym beserta rating rata-rata dari ulasan pengguna
  static Future<List<Gym>> fetchGyms() async {
    final gymsResponse = await ApiClient.client
        .from('gyms')
        .select('*, categories(name, icon), gym_images(image_url)')
        .order('name', ascending: true);

    List reviewsResponse = [];
    try {
      reviewsResponse = await ApiClient.client
          .from('reviews')
          .select('gym_id, rating');
    } catch (_) {
      // Jika query reviews gagal (mis. RLS), lanjutkan dengan data Google saja
    }

    return _mergeGymWithReviews(gymsResponse as List, reviewsResponse);
  }

  /// Ambil gym berdasarkan category_id
  static Future<List<Gym>> fetchGymsByCategory(int categoryId) async {
    final gymsResponse = await ApiClient.client
        .from('gyms')
        .select('*, categories(name, icon), gym_images(image_url)')
        .eq('category_id', categoryId)
        .order('name', ascending: true);

    List reviewsResponse = [];
    try {
      reviewsResponse = await ApiClient.client
          .from('reviews')
          .select('gym_id, rating');
    } catch (_) {}

    return _mergeGymWithReviews(gymsResponse as List, reviewsResponse);
  }

  /// Cari gym berdasarkan nama atau alamat
  static Future<List<Gym>> searchGyms(String query) async {
    final gymsResponse = await ApiClient.client
        .from('gyms')
        .select('*, categories(name, icon), gym_images(image_url)')
        .or('name.ilike.%$query%,address.ilike.%$query%')
        .order('name', ascending: true);

    List reviewsResponse = [];
    try {
      reviewsResponse = await ApiClient.client
          .from('reviews')
          .select('gym_id, rating');
    } catch (_) {}

    return _mergeGymWithReviews(gymsResponse as List, reviewsResponse);
  }

  /// Ambil detail gym berdasarkan ID
  static Future<Gym?> fetchGymById(int gymId) async {
    final response = await ApiClient.client
        .from('gyms')
        .select('*, categories(name, icon), gym_images(image_url)')
        .eq('gym_id', gymId)
        .maybeSingle();

    if (response == null) return null;

    List reviewsResponse = [];
    try {
      reviewsResponse = await ApiClient.client
          .from('reviews')
          .select('gym_id, rating')
          .eq('gym_id', gymId);
    } catch (_) {}

    final merged = _mergeGymWithReviews([response], reviewsResponse);
    return merged.isNotEmpty ? merged.first : null;
  }

  /// Hitung statistik review app per gym, lalu attach ke model via copyWithAppStats.
  /// Rating & reviewCount Google TIDAK diubah — cumulativeRating dihitung di model.
  static List<Gym> _mergeGymWithReviews(
    List gymJsonList,
    List reviewJsonList,
  ) {
    // Kelompokkan rating review per gym_id
    final Map<int, List<int>> reviewsByGym = {};
    for (final r in reviewJsonList) {
      final gymId = r['gym_id'] as int;
      final rating = (r['rating'] as num).toInt();
      reviewsByGym.putIfAbsent(gymId, () => []).add(rating);
    }

    return gymJsonList.map((json) {
      // Parse dari JSON Supabase asli — gym_images tetap aman
      final gym = Gym.fromJson(json as Map<String, dynamic>);

      final ratings = reviewsByGym[gym.gymId] ?? [];
      final appCount = ratings.length;
      final appSum = ratings.fold<int>(0, (sum, r) => sum + r);

      // Attach data app review; rating Google tetap utuh di model
      return gym.copyWithAppStats(appReviewSum: appSum, appReviewCount: appCount);
    }).toList();
  }
}

