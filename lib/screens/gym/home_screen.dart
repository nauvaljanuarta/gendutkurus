import 'package:flutter/material.dart';
import '../../models/gym_model.dart';
import '../../models/category_model.dart';
import '../../services/gym_service.dart';
import '../../services/category_service.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/gym_card.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  int? _selectedCategoryId;
  List<Gym> _gyms = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        GymService.fetchGyms(),
        CategoryService.fetchCategories(),
      ]);

      setState(() {
        _gyms = results[0] as List<Gym>;
        _categories = results[1] as List<Category>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Gym> get _filteredGyms {
    return _gyms.where((gym) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          gym.name.toLowerCase().contains(query) ||
          gym.address.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategoryId == null || gym.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              AppSearchBar(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildPromoBanner(),
              const SizedBox(height: 16),
              _buildCategoryChips(),
              const SizedBox(height: 16),
              ..._buildGymItems(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Gym & Fitness Surabaya',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.notifications_none, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2979FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Promo Fitness',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          SizedBox(height: 8),
          Text(
            'Diskon keanggotaan bulan ini',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Paket latihan lengkap dengan trainer profesional.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return CategoryChip(
              label: 'Semua',
              isSelected: _selectedCategoryId == null,
              onTap: () {
                setState(() {
                  _selectedCategoryId = null;
                });
              },
            );
          }

          final category = _categories[index - 1];
          return CategoryChip(
            label: category.name,
            isSelected: _selectedCategoryId == category.id,
            onTap: () {
              setState(() {
                _selectedCategoryId = category.id;
              });
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildGymItems() {
    if (_isLoading) {
      return const [
        SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_error != null) {
      return [
        SizedBox(
          height: 260,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white38,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Gagal memuat data',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    final gyms = _filteredGyms;

    if (gyms.isEmpty) {
      return const [
        SizedBox(
          height: 180,
          child: Center(
            child: Text(
              'Tidak ada gym yang sesuai.',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ];
    }

    return gyms
        .map(
          (gym) => GymCard(
            gym: gym,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailScreen(gym: gym)),
              );
            },
          ),
        )
        .toList();
  }
}
