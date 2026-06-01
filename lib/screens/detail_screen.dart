import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/gym_model.dart';

class DetailScreen extends StatelessWidget {
  final Gym gym;

  const DetailScreen({super.key, required this.gym});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Gym'), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header visual — gradient berdasarkan kategori
            Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getCategoryGradient(gym.categoryName),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(gym.categoryName),
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    if (gym.categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          gym.categoryName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gym.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFFD700),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${gym.rating}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (gym.reviewCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${gym.reviewCount} review)',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          gym.openingHours,
                          style: const TextStyle(color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Alamat
                  const Text(
                    'Alamat Lengkap',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 18, color: Colors.white54),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          gym.address,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Info kontak
                  if (gym.phone != null || gym.website != null) ...[
                    const Text(
                      'Kontak',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (gym.phone != null)
                          _InfoChip(
                              icon: Icons.phone, label: gym.phone!),
                        if (gym.website != null)
                          _InfoChip(
                              icon: Icons.language, label: gym.website!),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Deskripsi
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gym.description.isEmpty
                        ? 'Tidak ada deskripsi tersedia.'
                        : gym.description,
                    style: const TextStyle(
                        color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  // Koordinat info
                  if (gym.latitude != 0.0 && gym.longitude != 0.0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map_outlined,
                              color: Color(0xFF2979FF), size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Koordinat: ${gym.latitude.toStringAsFixed(4)}, ${gym.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),
                  // Tombol buka Google Maps — lihat lokasi
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openGoogleMaps(context),
                      icon: const Icon(Icons.location_on),
                      label: const Text('Lihat Lokasi di Google Maps'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tombol navigasi rute ke gym
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openGoogleMapsDirections(context),
                      icon: const Icon(Icons.directions, color: Color(0xFF2979FF)),
                      label: const Text(
                        'Navigasi Rute ke Gym',
                        style: TextStyle(color: Color(0xFF2979FF)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2979FF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Buka Google Maps di lokasi gym
  Future<void> _openGoogleMaps(BuildContext context) async {
    if (gym.latitude == 0.0 && gym.longitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koordinat gym tidak tersedia')),
      );
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${gym.latitude},${gym.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
        );
      }
    }
  }

  /// Buka Google Maps dengan navigasi rute dari lokasi user ke gym
  Future<void> _openGoogleMapsDirections(BuildContext context) async {
    if (gym.latitude == 0.0 && gym.longitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koordinat gym tidak tersedia')),
      );
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${gym.latitude},${gym.longitude}&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
        );
      }
    }
  }

  List<Color> _getCategoryGradient(String? category) {
    switch (category?.toLowerCase()) {
      case 'gym premium':
        return [const Color(0xFF6A11CB), const Color(0xFF2575FC)];
      case 'gym murah':
        return [const Color(0xFF11998E), const Color(0xFF38EF7D)];
      case 'gym 24 jam':
        return [const Color(0xFFFC466B), const Color(0xFF3F5EFB)];
      case 'fitness wanita':
        return [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)];
      case 'crossfit':
        return [const Color(0xFFF7971E), const Color(0xFFFFD200)];
      default:
        return [const Color(0xFF2979FF), const Color(0xFF00BCD4)];
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'gym premium':
        return Icons.fitness_center;
      case 'gym murah':
        return Icons.attach_money;
      case 'gym 24 jam':
        return Icons.schedule;
      case 'fitness wanita':
        return Icons.female;
      case 'crossfit':
        return Icons.sports_gymnastics;
      default:
        return Icons.fitness_center;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2979FF)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
