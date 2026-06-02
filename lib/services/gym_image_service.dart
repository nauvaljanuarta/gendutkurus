import '../models/gym_image_model.dart';
import 'api_client.dart';

class GymImageService {
  /// Mengambil daftar gambar untuk suatu gym
  static Future<List<GymImage>> fetchImagesForGym(int gymId) async {
    final response = await ApiClient.client
        .from('gym_images')
        .select()
        .eq('gym_id', gymId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => GymImage.fromJson(json))
        .toList();
  }
}
