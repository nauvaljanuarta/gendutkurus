import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../models/gym_model.dart';

class DetailMapScreen extends StatefulWidget {
  final Gym gym;
  const DetailMapScreen({super.key, required this.gym});

  @override
  State<DetailMapScreen> createState() => _DetailMapScreenState();
}

class _DetailMapScreenState extends State<DetailMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  Position? _userPosition;
  StreamSubscription<Position>? _positionSubscription;
  bool _shouldCenterOnUser = false;
  AnimationController? _mapMoveController;

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    _mapMoveController?.dispose();

    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude,
        end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude,
        end: destLocation.longitude);
    final zoomTween = Tween<double>(
        begin: _mapController.camera.zoom,
        end: destZoom);

    _mapMoveController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    final Animation<double> animation = CurvedAnimation(
        parent: _mapMoveController!, curve: Curves.fastOutSlowIn);

    _mapMoveController!.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    _mapMoveController!.forward();
  }
  
  // Routing variables
  List<LatLng> _routePoints = [];
  bool _isFetchingRoute = false;
  double? _routeDistanceKm;
  double? _routeDurationMin;
  bool _isRoutingActive = false;

  // Map Tile Style ('dark', 'voyager', 'positron')
  String _currentMapStyle = 'dark';

  final Map<String, String> _tileUrls = {
    'dark': 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
    'voyager': 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
    'positron': 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
  };

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    
    // Focus on gym coordinates after map builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(LatLng(widget.gym.latitude, widget.gym.longitude), 14.5);
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapMoveController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (mounted) {
          setState(() {
            _userPosition = position;
          });
        }
        _startLocationStream();
      }
    } catch (e) {
      debugPrint('Gagal mendapatkan lokasi user: $e');
    }
  }

  void _startLocationStream() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _userPosition = position;
        });

        if (_shouldCenterOnUser) {
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            _mapController.camera.zoom,
          );
        }

        if (_isRoutingActive) {
          _fetchRoute(position, LatLng(widget.gym.latitude, widget.gym.longitude));
        }
      }
    });
  }

  Future<void> _fetchRoute(Position start, LatLng end) async {
    if (_isFetchingRoute) return;
    setState(() {
      _isFetchingRoute = true;
    });

    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final List<dynamic> coords = geometry['coordinates'];
          
          final List<LatLng> points = coords.map((c) {
            return LatLng(c[1] as double, c[0] as double);
          }).toList();

          final distanceMeters = route['distance'] as num;
          final durationSeconds = route['duration'] as num;

          if (mounted) {
            setState(() {
              _routePoints = points;
              _routeDistanceKm = distanceMeters / 1000.0;
              _routeDurationMin = durationSeconds / 60.0;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingRoute = false;
        });
      }
    }
  }

  void _clearRoute() {
    setState(() {
      _routePoints.clear();
      _routeDistanceKm = null;
      _routeDurationMin = null;
      _isRoutingActive = false;
      _shouldCenterOnUser = false;
    });
    // Re-center back on the gym
    _mapController.move(LatLng(widget.gym.latitude, widget.gym.longitude), 14.5);
  }

  String _getDistanceText() {
    if (_userPosition != null) {
      double dist = Geolocator.distanceBetween(
        _userPosition!.latitude,
        _userPosition!.longitude,
        widget.gym.latitude,
        widget.gym.longitude,
      );
      if (dist > 1000) {
        return '${(dist / 1000).toStringAsFixed(1)} km dari Anda';
      } else {
        return '${dist.toStringAsFixed(0)} m dari Anda';
      }
    }
    return '${widget.gym.latitude.toStringAsFixed(4)}, ${widget.gym.longitude.toStringAsFixed(4)}';
  }

  void _toggleMapStyle() {
    final styles = _tileUrls.keys.toList();
    final nextIndex = (styles.indexOf(_currentMapStyle) + 1) % styles.length;
    setState(() {
      _currentMapStyle = styles[nextIndex];
    });
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tema peta diubah ke: ${_currentMapStyle.toUpperCase()}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Color _getGymThemeColor() {
    switch (widget.gym.categoryName?.toLowerCase()) {
      case 'gym premium':
        return const Color(0xFFE040FB); // Violet/Purple
      case 'gym murah':
        return const Color(0xFF00E676); // Neon Green
      case 'gym 24 jam':
        return const Color(0xFFFF3D00); // Orange Red
      case 'fitness wanita':
        return const Color(0xFFFF4081); // Pink
      case 'crossfit':
        return const Color(0xFFFFD600); // Bright Yellow
      default:
        return const Color(0xFF3F72AF); // Steel Blue
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymColor = _getGymThemeColor();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Full Screen Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.gym.latitude, widget.gym.longitude),
              initialZoom: 14.5,
              onTap: (position, point) {
                // Tapping outer map cancels follow mode
                if (_shouldCenterOnUser) {
                  setState(() {
                    _shouldCenterOnUser = false;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrls[_currentMapStyle]!,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.gendutkurus',
              ),
              
              // Glowing Neon Route Polyline
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Outer glow layer
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 8.0,
                      color: const Color(0xFF3F72AF).withValues(alpha: 0.3),
                    ),
                    // Core line layer
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: const Color(0xFF00E5FF),
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(
                markers: [
                  // User Location (Radar Pulse)
                  if (_userPosition != null)
                    Marker(
                      point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                      width: 70,
                      height: 70,
                      child: const PulseRadarMarker(),
                    ),

                  // The Selected Gym Location
                  Marker(
                    point: LatLng(widget.gym.latitude, widget.gym.longitude),
                    width: 60,
                    height: 60,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulsing Ring for target gym
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: gymColor.withValues(alpha: 0.2),
                                ),
                              ),
                              // Core Pin marker
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: gymColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: gymColor.withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.fitness_center,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: gymColor,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Floating Top Header with Glassmorphic Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Floating Right Control Panel (Pill-shaped Control Deck)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 46,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Zoom In
                      _buildDeckButton(
                        icon: Icons.add,
                        onTap: () {
                          _animatedMapMove(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 0.5,
                          );
                        },
                      ),
                      const Divider(color: Colors.white10, height: 12),
                      // Zoom Out
                      _buildDeckButton(
                        icon: Icons.remove,
                        onTap: () {
                          _animatedMapMove(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 0.5,
                          );
                        },
                      ),
                      const Divider(color: Colors.white10, height: 12),
                      // Theme Switcher
                      _buildDeckButton(
                        icon: Icons.layers_outlined,
                        onTap: _toggleMapStyle,
                      ),
                      const Divider(color: Colors.white10, height: 12),
                      // Recenter User Location
                      _buildDeckButton(
                        icon: _shouldCenterOnUser ? Icons.gps_fixed : Icons.gps_not_fixed,
                        iconColor: _shouldCenterOnUser ? Theme.of(context).colorScheme.primary : Colors.white70,
                        onTap: () {
                          if (_userPosition != null) {
                            setState(() {
                              _shouldCenterOnUser = !_shouldCenterOnUser;
                            });
                            _animatedMapMove(
                              LatLng(_userPosition!.latitude, _userPosition!.longitude),
                              _mapController.camera.zoom,
                            );
                            if (_shouldCenterOnUser) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Mengikuti lokasi Anda secara real-time'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lokasi Anda tidak terdeteksi'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Bottom Detail Overlay Card (Glassmorphic)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: gymColor.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row: Gym name & Rating
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category badge
                                if (widget.gym.categoryName != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      color: gymColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: gymColor.withValues(alpha: 0.3), width: 1),
                                    ),
                                    child: Text(
                                      widget.gym.categoryName!,
                                      style: TextStyle(
                                        color: gymColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Text(
                                  widget.gym.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.gym.rating}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      // Address Row
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.white54, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.gym.address,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Distance and User position indicator
                      Row(
                        children: [
                          Icon(Icons.directions_walk, color: gymColor, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _getDistanceText(),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      // Route Details (Only if route is loaded)
                      if (_isRoutingActive && _routeDistanceKm != null && _routeDurationMin != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('JARAK RUTE', style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_routeDistanceKm!.toStringAsFixed(1)} km',
                                    style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(height: 24, width: 1, color: Colors.white10),
                              Column(
                                children: [
                                  const Text('ESTIMASI WAKTU', style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_routeDurationMin!.toStringAsFixed(0)} menit',
                                    style: const TextStyle(color: Color(0xFF00E676), fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Action Buttons Row
                      Row(
                        children: [
                          if (_isRoutingActive)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _clearRoute,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: const BorderSide(color: Colors.white24),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Batal Rute', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            )
                          else
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (_userPosition != null) {
                                    setState(() {
                                      _isRoutingActive = true;
                                    });
                                    _fetchRoute(_userPosition!, LatLng(widget.gym.latitude, widget.gym.longitude));
                                    _animatedMapMove(LatLng(widget.gym.latitude, widget.gym.longitude), 15.5);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Lokasi Anda belum siap untuk navigasi'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [gymColor, gymColor.withValues(alpha: 0.7)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: gymColor.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.navigation, size: 16, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Mulai Navigasi',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white70,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}

// Multi-Ripple Pulsing Radar Location Marker
class PulseRadarMarker extends StatefulWidget {
  const PulseRadarMarker({super.key});

  @override
  State<PulseRadarMarker> createState() => _PulseRadarMarkerState();
}

class _PulseRadarMarkerState extends State<PulseRadarMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Wave 1
            Transform.scale(
              scale: 1.0 + (progress * 1.5),
              child: Opacity(
                opacity: (1.0 - progress).clamp(0.0, 1.0),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromRGBO(41, 121, 255, 0.25),
                  ),
                ),
              ),
            ),
            // Wave 2
            Transform.scale(
              scale: 1.0 + (((progress + 0.5) % 1.0) * 1.5),
              child: Opacity(
                opacity: (1.0 - ((progress + 0.5) % 1.0)).clamp(0.0, 1.0),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3F72AF).withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
            // Solid center core
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3F72AF).withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF3F72AF),
              ),
            ),
          ],
        );
      },
    );
  }
}
