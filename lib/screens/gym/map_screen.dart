import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../models/gym_model.dart';
import '../../services/gym_service.dart';
import 'detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  List<Gym> _allGyms = [];
  bool _isLoading = true;
  final MapController _mapController = MapController();
  Gym? _selectedGym;
  Position? _userPosition;
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

  // Real-time location stream and routing variables
  StreamSubscription<Position>? _positionSubscription;
  bool _shouldCenterOnUser = false;
  List<LatLng> _routePoints = [];
  bool _isFetchingRoute = false;
  double? _routeDistanceKm;
  double? _routeDurationMin;
  bool _isRoutingActive = false;

  // Map Tile Style ('dark', 'voyager', 'positron')
  String _currentMapStyle = 'positron';
  final Map<String, String> _tileUrls = {
    'dark': 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
    'voyager': 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
    'positron': 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
  };

  // Search Filtering
  String _mapSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserLocationAndLoadGyms();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapMoveController?.dispose();
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Gym> get _filteredGyms {
    if (_isRoutingActive && _selectedGym != null) {
      return [_selectedGym!];
    }
    List<Gym> gymsList = _allGyms;
    if (_mapSearchQuery.isNotEmpty) {
      final query = _mapSearchQuery.toLowerCase();
      gymsList = _allGyms
          .where((gym) =>
              gym.name.toLowerCase().contains(query) ||
              gym.address.toLowerCase().contains(query))
          .toList();
    }
    if (gymsList.length > 15) {
      return gymsList.sublist(0, 15);
    }
    return gymsList;
  }

  String _userPosDistText(Gym gym) {
    if (_userPosition != null) {
      double dist = Geolocator.distanceBetween(
        _userPosition!.latitude,
        _userPosition!.longitude,
        gym.latitude,
        gym.longitude,
      );
      if (dist > 1000) {
        return '${(dist / 1000).toStringAsFixed(1)} km dari Anda';
      } else {
        return '${dist.toStringAsFixed(0)} m dari Anda';
      }
    }
    return '${gym.latitude.toStringAsFixed(4)}, ${gym.longitude.toStringAsFixed(4)}';
  }

  Future<void> _getUserLocationAndLoadGyms() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (mounted) {
          setState(() {
            _userPosition = position;
          });
        }
        await _loadGyms(position);
        _startLocationStream();
      } else {
        await _loadGyms(null);
      }
    } catch (e) {
      debugPrint('Gagal mendapatkan lokasi: $e');
      await _loadGyms(null);
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

        if (_selectedGym != null && _isRoutingActive) {
          _fetchRoute(
            position,
            LatLng(_selectedGym!.latitude, _selectedGym!.longitude),
          );
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

  void _selectGym(Gym gym, double zoom) {
    setState(() {
      _selectedGym = gym;
      _isRoutingActive = false;
      _routePoints.clear();
      _routeDistanceKm = null;
      _routeDurationMin = null;
      _shouldCenterOnUser = false;
    });
    _animatedMapMove(LatLng(gym.latitude, gym.longitude), zoom);
  }

  void _clearRoute() {
    setState(() {
      _selectedGym = null;
      _routePoints.clear();
      _routeDistanceKm = null;
      _routeDurationMin = null;
      _isRoutingActive = false;
      _shouldCenterOnUser = false;
    });
  }

  Future<void> _loadGyms(Position? userPos) async {
    try {
      final gyms = await GymService.fetchGyms();
      var validGyms =
          gyms.where((g) => g.latitude != 0.0 && g.longitude != 0.0).toList();

      if (userPos != null) {
        validGyms.sort((a, b) {
          double distA = Geolocator.distanceBetween(
              userPos.latitude, userPos.longitude, a.latitude, a.longitude);
          double distB = Geolocator.distanceBetween(
              userPos.latitude, userPos.longitude, b.latitude, b.longitude);
          return distA.compareTo(distB);
        });
      }

      setState(() {
        _allGyms = validGyms;
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

  Color _getGymThemeColor(Gym gym) {
    switch (gym.categoryName?.toLowerCase()) {
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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // 1. Full Screen Map Layer
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(-7.2575, 112.7521), // Default Surabaya
                    initialZoom: 12.0,
                    onTap: (position, point) {
                      _clearRoute();
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
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 8.0,
                            color: const Color(0xFF3F72AF).withValues(alpha: 0.3),
                          ),
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
                        // User Location Radar Pulse
                        if (_userPosition != null)
                          Marker(
                            point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                            width: 70,
                            height: 70,
                            child: const PulseRadarMarker(),
                          ),

                        // Gym Markers
                        ..._filteredGyms.map((gym) {
                          final isSelected = _selectedGym?.gymId == gym.gymId;
                          final gymColor = _getGymThemeColor(gym);

                          return Marker(
                            point: LatLng(gym.latitude, gym.longitude),
                            width: 55,
                            height: 55,
                            child: GestureDetector(
                              onTap: () => _selectGym(gym, 15.5),
                              child: AnimatedScale(
                                scale: isSelected ? 1.3 : 1.0,
                                duration: const Duration(milliseconds: 250),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (isSelected)
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: gymColor.withValues(alpha: 0.25),
                                        ),
                                      ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: gymColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: gymColor.withValues(alpha: 0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              )
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.fitness_center,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          color: gymColor,
                                          size: 12,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),

          // 2. Floating Top Bar: Search Field
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 72,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _mapSearchQuery = value;
                      });
                    },
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Cari gym...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      suffixIcon: _mapSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _mapSearchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Floating Right Control Panel (Pill-shaped Control Deck)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 46,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                      width: 1,
                    ),
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
                      Divider(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15), height: 12),
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
                      Divider(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15), height: 12),
                      // Theme Switcher
                      _buildDeckButton(
                        icon: Icons.layers_outlined,
                        onTap: _toggleMapStyle,
                      ),
                      Divider(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15), height: 12),
                      // Recenter User Location
                      _buildDeckButton(
                        icon: _shouldCenterOnUser ? Icons.gps_fixed : Icons.gps_not_fixed,
                        iconColor: _shouldCenterOnUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
          if (_selectedGym != null)
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
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _getGymThemeColor(_selectedGym!).withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Gym details
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Category badge
                                        if (_selectedGym!.categoryName != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            margin: const EdgeInsets.only(bottom: 6),
                                            decoration: BoxDecoration(
                                              color: _getGymThemeColor(_selectedGym!).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: _getGymThemeColor(_selectedGym!).withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              _selectedGym!.categoryName!,
                                              style: TextStyle(
                                                color: _getGymThemeColor(_selectedGym!),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        Text(
                                          _selectedGym!.name,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star,
                                            color: Color(0xFFFFD700), size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_selectedGym!.rating}',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface,
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

                              // Address
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _selectedGym!.address,
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Distance indicator
                              Row(
                                children: [
                                  Icon(Icons.directions_walk,
                                      color: _getGymThemeColor(_selectedGym!),
                                      size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    _userPosDistText(_selectedGym!),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                              // Route details
                              if (_isRoutingActive &&
                                  _routeDistanceKm != null &&
                                  _routeDurationMin != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2), width: 1),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          Text('JARAK RUTE',
                                              style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_routeDistanceKm!.toStringAsFixed(1)} km',
                                            style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      Container(
                                          height: 24,
                                          width: 1,
                                          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2)),
                                      Column(
                                        children: [
                                          Text('ESTIMASI WAKTU',
                                              style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_routeDurationMin!.toStringAsFixed(0)} menit',
                                            style: const TextStyle(
                                                color: Color(0xFF2E7D32),
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),

                              // Action Row
                              Row(
                                children: [
                                  if (_isRoutingActive)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _isRoutingActive = false;
                                            _routePoints.clear();
                                            _routeDistanceKm = null;
                                            _routeDurationMin = null;
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                          side: BorderSide(
                                              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        icon: const Icon(Icons.close, size: 16),
                                        label: const Text('Batal Rute',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13)),
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
                                            _fetchRoute(
                                              _userPosition!,
                                              LatLng(_selectedGym!.latitude,
                                                  _selectedGym!.longitude),
                                            );
                                            _animatedMapMove(
                                              LatLng(_selectedGym!.latitude,
                                                  _selectedGym!.longitude),
                                              15.5,
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Lokasi Anda belum siap untuk navigasi'),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 13),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                _getGymThemeColor(_selectedGym!),
                                                _getGymThemeColor(_selectedGym!)
                                                    .withValues(alpha: 0.7)
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    _getGymThemeColor(_selectedGym!)
                                                        .withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.navigation,
                                                  size: 16, color: Colors.white),
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
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              DetailScreen(gym: _selectedGym!),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF252525),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: const BorderSide(
                                          color: Colors.white12,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'Detail',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: InkWell(
                            onTap: _clearRoute,
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                color: Colors.white60,
                                size: 18,
                              ),
                            ),
                          ),
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
    Color? iconColor,
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
          child: Icon(icon, size: 20, color: iconColor ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
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

class _PulseRadarMarkerState extends State<PulseRadarMarker>
    with SingleTickerProviderStateMixin {
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
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromRGBO(41, 121, 255, 0.15),
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
