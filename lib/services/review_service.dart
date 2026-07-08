import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import 'api_client.dart';

class ReviewService {
  /// Ambil review berdasarkan gym_id
  static Future<List<Review>> fetchReviews(int gymId) async {
    // 1. Ambil semua review dari tabel reviews
    final response = await ApiClient.client
        .from('reviews')
        .select()
        .eq('gym_id', gymId)
        .order('created_at', ascending: false);

    final reviewsList = (response as List)
        .map((json) => Review.fromJson(json))
        .toList();

    if (reviewsList.isEmpty) return [];

    // 2. Ambil avatar_url untuk masing-masing user secara aman
    try {
      final userIds = reviewsList.map((r) => r.userId).toSet().toList();
      final usersResponse = await ApiClient.client
          .from('users')
          .select('id, avatar_url')
          .inFilter('id', userIds);

      final Map<String, String?> userAvatars = {
        for (var u in usersResponse as List)
          u['id'] as String: u['avatar_url'] as String?
      };

      // 3. Pasangkan avatar_url ke dalam model Review
      return reviewsList.map((review) {
        return Review(
          id: review.id,
          gymId: review.gymId,
          userId: review.userId,
          userName: review.userName,
          rating: review.rating,
          comment: review.comment,
          createdAt: review.createdAt,
          userAvatarUrl: userAvatars[review.userId],
        );
      }).toList();
    } catch (e) {
      // Fallback: Jika gagal memuat foto profil, tetap tampilkan ulasan tanpa foto
      debugPrint('Error fetching review avatars: $e');
      return reviewsList;
    }
  }

  /// Tambah review
  static Future<void> addReview({
    required String userId,
    required String userName,
    required int gymId,
    required int rating,
    required String comment,
  }) async {
    await ApiClient.client.from('reviews').insert({
      'user_id': userId,
      'user_name': userName,
      'gym_id': gymId,
      'rating': rating,
      'comment': comment,
    });
  }
}
