import 'package:flutter/material.dart';
import '../models/gym_model.dart';
import '../services/supabase_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Gym> _gyms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGyms();
  }

  Future<void> _loadGyms() async {
    try {
      final gyms = await SupabaseService.fetchGyms();
      setState(() {
        _gyms = gyms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: const Text('Peta Gym'), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Placeholder peta
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.map_outlined,
                        size: 100,
                        color: Colors.white24,
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2979FF).withAlpha(41),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.location_pin,
                            size: 52,
                            color: Color(0xFF2979FF),
                          ),
                        ),
                      ),
                    ),
                    // Badge jumlah gym
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2979FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_gyms.length} Gym',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Daftar Gym (${_gyms.length})',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            // Daftar gym dari Supabase
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _gyms.isEmpty
                      ? const Center(
                          child: Text('Tidak ada data gym.',
                              style: TextStyle(color: Colors.white70)),
                        )
                      : ListView.builder(
                          itemCount: _gyms.length,
                          itemBuilder: (context, index) {
                            final gym = _gyms[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          gym.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2979FF)
                                              .withAlpha(36),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star,
                                                size: 12,
                                                color: Color(0xFFFFD700)),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${gym.rating}',
                                              style: const TextStyle(
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    gym.address,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                  if (gym.latitude != 0.0 &&
                                      gym.longitude != 0.0) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      '📍 ${gym.latitude.toStringAsFixed(4)}, ${gym.longitude.toStringAsFixed(4)}',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
