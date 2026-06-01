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
            // Image area — gradient placeholder karena tidak ada imageUrl di DB
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Container(
                height: 170,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getCategoryGradient(gym.categoryName),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Pattern overlay
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
                    // Main icon
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
                          color: const Color(0xFF2979FF).withAlpha(36),
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
                            Text('${gym.rating}'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (gym.reviewCount > 0)
                        Text(
                          '(${gym.reviewCount} review)',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      const Spacer(),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          gym.openingHours,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          gym.address,
                          style: const TextStyle(color: Colors.white70),
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

  /// Gradient warna berdasarkan kategori gym
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

  /// Ikon berdasarkan kategori gym
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
