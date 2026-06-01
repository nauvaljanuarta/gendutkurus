import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gym_model.dart';
import '../models/category_model.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // ==================== GYMS ====================

  /// Ambil semua gym, join dengan categories
  static Future<List<Gym>> fetchGyms() async {
    final response = await client
        .from('gyms')
        .select('*, categories(name, icon)')
        .order('name', ascending: true);

    return (response as List)
        .map((json) => Gym.fromJson(json))
        .toList();
  }

  /// Ambil gym berdasarkan category_id
  static Future<List<Gym>> fetchGymsByCategory(int categoryId) async {
    final response = await client
        .from('gyms')
        .select('*, categories(name, icon)')
        .eq('category_id', categoryId)
        .order('name', ascending: true);

    return (response as List)
        .map((json) => Gym.fromJson(json))
        .toList();
  }

  /// Cari gym berdasarkan nama atau alamat
  static Future<List<Gym>> searchGyms(String query) async {
    final response = await client
        .from('gyms')
        .select('*, categories(name, icon)')
        .or('name.ilike.%$query%,address.ilike.%$query%')
        .order('name', ascending: true);

    return (response as List)
        .map((json) => Gym.fromJson(json))
        .toList();
  }

  /// Ambil detail gym berdasarkan ID
  static Future<Gym?> fetchGymById(int gymId) async {
    final response = await client
        .from('gyms')
        .select('*, categories(name, icon)')
        .eq('gym_id', gymId)
        .maybeSingle();

    if (response == null) return null;
    return Gym.fromJson(response);
  }

  // ==================== CATEGORIES ====================

  /// Ambil semua kategori
  static Future<List<Category>> fetchCategories() async {
    final response = await client
        .from('categories')
        .select()
        .order('id', ascending: true);

    return (response as List)
        .map((json) => Category.fromJson(json))
        .toList();
  }

  // ==================== FAVORITES ====================

  /// Ambil favorit berdasarkan user_id
  static Future<List<Gym>> fetchFavorites(String userId) async {
    final response = await client
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
    final response = await client
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('gym_id', gymId)
        .maybeSingle();

    return response != null;
  }

  /// Toggle favorit — tambah jika belum, hapus jika sudah
  static Future<bool> toggleFavorite(String userId, int gymId) async {
    final existing = await client
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('gym_id', gymId)
        .maybeSingle();

    if (existing != null) {
      await client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('gym_id', gymId);
      return false; // Dihapus dari favorit
    } else {
      await client.from('favorites').insert({
        'user_id': userId,
        'gym_id': gymId,
      });
      return true; // Ditambahkan ke favorit
    }
  }

  // ==================== REVIEWS ====================

  /// Ambil review berdasarkan gym_id
  static Future<List<Map<String, dynamic>>> fetchReviews(int gymId) async {
    final response = await client
        .from('reviews')
        .select()
        .eq('gym_id', gymId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Tambah review
  static Future<void> addReview({
    required String userId,
    required int gymId,
    required int rating,
    required String comment,
  }) async {
    await client.from('reviews').insert({
      'user_id': userId,
      'gym_id': gymId,
      'rating': rating,
      'comment': comment,
    });
  }
}
