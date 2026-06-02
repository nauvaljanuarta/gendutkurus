import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/gym_model.dart';
import '../../services/gym_service.dart';
import 'detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Gym> _gyms = [];
  bool _isLoading = true;
  final MapController _mapController = MapController();
  Gym? _selectedGym;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _getUserLocationAndLoadGyms();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  String userPosDistText(Gym gym) {
    if (_userPosition != null) {
      double dist = Geolocator.distanceBetween(_userPosition!.latitude, _userPosition!.longitude, gym.latitude, gym.longitude);
      if (dist > 1000) {
        return '📍 ${(dist / 1000).toStringAsFixed(1)} km dari Anda';
      } else {
        return '📍 ${dist.toStringAsFixed(0)} m dari Anda';
      }
    }
    return '📍 ${gym.latitude.toStringAsFixed(4)}, ${gym.longitude.toStringAsFixed(4)}';
  }

  Future<void> _getUserLocationAndLoadGyms() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _userPosition = position;
        });
        await _loadGyms(position);
      } else {
        await _loadGyms(null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendapatkan lokasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      await _loadGyms(null);
    }
  }

  Future<void> _loadGyms(Position? userPos) async {
    try {
      final gyms = await GymService.fetchGyms();
      var validGyms = gyms.where((g) => g.latitude != 0.0 && g.longitude != 0.0).toList();

      if (userPos != null) {
        validGyms.sort((a, b) {
          double distA = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, a.latitude, a.longitude);
          double distB = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, b.latitude, b.longitude);
          return distA.compareTo(distB);
        });
        if (validGyms.length > 10) {
          validGyms = validGyms.sublist(0, 10);
        }
      }

      setState(() {
        _gyms = validGyms;
        _isLoading = false;
      });

      // Move map to the center of the user or first gym if available
      if (userPos != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(
            LatLng(userPos.latitude, userPos.longitude),
            13.0,
          );
        });
      } else if (validGyms.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(
            LatLng(validGyms[0].latitude, validGyms[0].longitude),
            13.0,
          );
        });
      }
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
            // Kontainer Peta
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: const LatLng(-7.2575, 112.7521), // Default Surabaya
                              initialZoom: 12.0,
                              onTap: (_, __) {
                                setState(() {
                                  _selectedGym = null;
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                                userAgentPackageName: 'com.example.gendutkurus',
                              ),
                              MarkerLayer(
                                markers: [
                                  if (_userPosition != null)
                                    Marker(
                                      point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                                      width: 60,
                                      height: 60,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.green.withValues(alpha: 0.3),
                                          border: Border.all(color: Colors.green, width: 2),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.my_location, color: Colors.green, size: 30),
                                        ),
                                      ),
                                    ),
                                  ..._gyms.map((gym) {
                                    final isSelected = _selectedGym?.gymId == gym.gymId;
                                  return Marker(
                                    point: LatLng(gym.latitude, gym.longitude),
                                    width: 50,
                                    height: 50,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedGym = gym;
                                        });
                                        _mapController.move(
                                          LatLng(gym.latitude, gym.longitude),
                                          14.5,
                                        );
                                      },
                                      child: AnimatedScale(
                                        scale: isSelected ? 1.25 : 1.0,
                                        duration: const Duration(milliseconds: 250),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                color: isSelected ? const Color(0xFFFF2D55) : const Color(0xFF2979FF),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: (isSelected ? const Color(0xFFFF2D55) : const Color(0xFF2979FF)).withOpacity(0.4),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  )
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.fitness_center,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              child: Icon(
                                                Icons.arrow_drop_down,
                                                color: isSelected ? const Color(0xFFFF2D55) : const Color(0xFF2979FF),
                                                size: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                  }).toList(),
                                ],
                              ),
                            ],
                          ),
                    // Badge Jumlah Gym
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2979FF),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Text(
                          '${_gyms.length} Gym Terdekat',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Detail Overlay untuk Gym yang Terpilih
                    if (_selectedGym != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF2979FF).withOpacity(0.5), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _selectedGym!.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_selectedGym!.rating}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _selectedGym!.address,
                                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DetailScreen(gym: _selectedGym!),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2979FF),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Detail',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Daftar Lokasi Gym',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 12),
            // Daftar gym dari Supabase
            Expanded(
              flex: 2,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _gyms.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada data gym koordinat.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _gyms.length,
                          itemBuilder: (context, index) {
                            final gym = _gyms[index];
                            final isSelected = _selectedGym?.gymId == gym.gymId;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedGym = gym;
                                });
                                _mapController.move(
                                  LatLng(gym.latitude, gym.longitude),
                                  15.0,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF252535) : const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF2979FF) : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            gym.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: isSelected ? const Color(0xFF2979FF) : Colors.white,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2979FF).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.star, size: 12, color: Color(0xFFFFD700)),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${gym.rating}',
                                                style: const TextStyle(fontSize: 12, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      gym.address,
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          userPosDistText(gym),
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const Text(
                                          'Ketuk untuk melihat di peta 🗺️',
                                          style: TextStyle(
                                            color: Color(0xFF2979FF),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
