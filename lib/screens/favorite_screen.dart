import 'package:flutter/material.dart';
import '../data/dummy_gyms.dart';
import '../widgets/gym_card.dart';
import 'detail_screen.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = dummyGyms.where((gym) => gym.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite'), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: favorites.isEmpty
            ? const Center(
                child: Text(
                  'Belum ada gym favorit.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : ListView.builder(
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final gym = favorites[index];
                  return GymCard(
                    gym: gym,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(gym: gym),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
