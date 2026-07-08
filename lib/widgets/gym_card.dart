import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/gym_model.dart';

class GymCard extends StatelessWidget {
  final Gym gym;
  final VoidCallback onTap;

  const GymCard({super.key, required this.gym, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // MENAMPILKAN GAMBAR
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: SizedBox(
                height: 170,
                // Jika gym punya gambar, tampilkan gambar pertama [0]
                child: gym.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: gym.imageUrls[0],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        // Jika URL error/putus, tampilkan warna default
                        errorWidget: (context, url, error) =>
                            _buildFallbackGradient(),
                      )
                    // Jika gym TIDAK punya gambar, tampilkan warna default
                    : _buildFallbackGradient(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gym.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withAlpha(36),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Color(0xFFFFD700),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              gym.totalReviewCount > 0
                                  ? gym.cumulativeRating.toStringAsFixed(1)
                                  : '-',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (gym.totalReviewCount > 0)
                        Text(
                          '(${gym.totalReviewCount} ulasan)',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        )
                      else
                        Text(
                          'Belum ada ulasan',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _getShortHours(gym.openingHours),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          gym.address,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      child: const Text('Lihat Detail'),
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

  // Jika tidak ada gambar, tampilkan warna warni bawaan Anda
  Widget _buildFallbackGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getCategoryGradient(gym.categoryName),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Icon(
                _getCategoryIcon(gym.categoryName),
                size: 180,
                color: Colors.white,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getCategoryIcon(gym.categoryName),
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                if (gym.categoryName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      gym.categoryName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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
        return [const Color(0xFF3F72AF), const Color(0xFF5E8BBA)];
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

  String _getShortHours(String rawHours) {
    if (rawHours.isEmpty ||
        rawHours.toLowerCase() == 'tidak tersedia' ||
        rawHours == '-') {
      return 'Tidak tersedia';
    }
    if (rawHours.toLowerCase().contains('24 jam')) return 'Buka 24 Jam';

    // Cari angka jam pertama (contoh: 06.0022.00 -> 06.00 - 22.00)
    final match = RegExp(r'(\d{2}\.\d{2})(\d{2}\.\d{2})').firstMatch(rawHours);
    if (match != null) {
      return '${match.group(1)} - ${match.group(2)}';
    }

    return 'Lihat Detail';
  }
}
