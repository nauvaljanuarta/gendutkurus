import '../models/review_model.dart';
import 'api_client.dart';

class ReviewService {
  /// Ambil review berdasarkan gym_id
  static Future<List<Review>> fetchReviews(int gymId) async {
    final response = await ApiClient.client
        .from('reviews')
        .select()
        .eq('gym_id', gymId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Review.fromJson(json))
        .toList();
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
