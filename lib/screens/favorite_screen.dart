import 'package:flutter/material.dart';
import '../models/gym_model.dart';
import '../services/supabase_service.dart';
import '../widgets/gym_card.dart';
import 'detail_screen.dart';
import 'login_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<Gym> _favorites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        _favorites = await SupabaseService.fetchFavorites(user.id);
      } else {
        // Jika belum login, tampilkan pesan
        _favorites = [];
      }
    } catch (e) {
      _error = e.toString();
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite'), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: _buildBody(user),
      ),
    );
  }

  Widget _buildBody(dynamic user) {
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Login untuk melihat gym favorit',
              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ).then((_) => _loadFavorites());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2979FF),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Masuk Sekarang',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text('Gagal memuat favorit',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadFavorites,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.favorite_border, color: Colors.white24, size: 64),
            SizedBox(height: 16),
            Text(
              'Belum ada gym favorit.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final gym = _favorites[index];
          return GymCard(
            gym: gym,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailScreen(gym: gym),
                ),
              ).then((_) => _loadFavorites());
            },
          );
        },
      ),
    );
  }
}
