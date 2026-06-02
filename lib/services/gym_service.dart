import '../models/gym_model.dart';
import 'api_client.dart';

class GymService {
  static Future<List<Gym>> fetchGyms() async {
    final response = await ApiClient.client
        .from('gyms')
        .select('*, categories(name, icon)')
        .order('name', ascending: true);

    return (response as List)
        .map((json) => Gym.fromJson(json))
        .toList();
  }

  /// Ambil gym berdasarkan category_id
  static Future<List<Gym>> fetchGymsByCategory(int categoryId) async {
    final response = await ApiClient.client
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
    final response = await ApiClient.client
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
    final response = await ApiClient.client
        .from('gyms')
        .select('*, categories(name, icon)')
        .eq('gym_id', gymId)
        .maybeSingle();

    if (response == null) return null;
    return Gym.fromJson(response);
  }
}
