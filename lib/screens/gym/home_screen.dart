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
  int? _selectedCategoryId; // null = Semua
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

      // DEBUG: cek isi imageUrls dari Supabase
      final loadedGyms = results[0] as List<Gym>;
      for (final g in loadedGyms) {
        print('GYM: ${g.name} | imageUrls: ${g.imageUrls}');
      }

      setState(() {
        _gyms = loadedGyms;
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
      final matchesSearch = gym.name.toLowerCase().contains(query) ||
          gym.address.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategoryId == null || gym.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildGymList() // shows error state
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Collapsible Header ──
                    SliverAppBar(
                      expandedHeight: 300,
                      collapsedHeight: 64,
                      toolbarHeight: 64,
                      pinned: true,
                      floating: false,
                      backgroundColor: const Color(0xFF121212),
                      surfaceTintColor: Colors.transparent,
                      title: const Text(
                        'Gym & Fitness',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF252525),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.notifications_none,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 20, right: 20, top: 64, bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppSearchBar(
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    clipBehavior: Clip.hardEdge,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF2979FF),
                                          Color(0xFF00B0FF)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Text(
                                          'Promo Fitness',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Diskon keanggotaan bulan ini',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Gabung sekarang dan dapatkan paket latihan lengkap.',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Pinned Category Chips ──
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _CategoryHeaderDelegate(
                        categories: _categories,
                        selectedCategoryId: _selectedCategoryId,
                        onCategorySelected: (id) {
                          setState(() {
                            _selectedCategoryId = id;
                          });
                        },
                      ),
                    ),

                    // ── Gym List ──
                    _filteredGyms.isEmpty
                        ? const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                'Tidak ada gym yang sesuai.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final gym = _filteredGyms[index];
                                  return GymCard(
                                    gym: gym,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              DetailScreen(gym: gym),
                                        ),
                                      );
                                    },
                                  );
                                },
                                childCount: _filteredGyms.length,
                              ),
                            ),
                          ),
                  ],
                ),
    );
  }

  Widget _buildGymList() {
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
            Text(
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
      );
    }

    final gyms = _filteredGyms;

    if (gyms.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada gym yang sesuai.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: gyms.length,
        itemBuilder: (context, index) {
          final gym = gyms[index];
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
    );
  }
}

// ── Pinned Category Header Delegate ──
class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<Category> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategorySelected;

  _CategoryHeaderDelegate({
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  double get minExtent => 58;
  @override
  double get maxExtent => 58;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: categories.isEmpty
          ? const SizedBox.shrink()
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return CategoryChip(
                    label: 'Semua',
                    isSelected: selectedCategoryId == null,
                    onTap: () => onCategorySelected(null),
                  );
                }
                final category = categories[index - 1];
                return CategoryChip(
                  label: category.name,
                  isSelected: selectedCategoryId == category.id,
                  onTap: () => onCategorySelected(category.id),
                );
              },
            ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return oldDelegate.selectedCategoryId != selectedCategoryId ||
        oldDelegate.categories != categories;
  }
}
