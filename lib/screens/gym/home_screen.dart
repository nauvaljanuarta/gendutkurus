import 'package:flutter/material.dart';
import '../../models/gym_model.dart';
import '../../models/category_model.dart';
import '../../models/user_model.dart';
import '../../services/gym_service.dart';
import '../../services/category_service.dart';
import '../../services/user_service.dart';
import '../../services/api_client.dart';
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
  UserModel? _userModel;
  bool _isLoading = true;
  String? _error;

  final PageController _pageController = PageController();
  int _activePage = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = ApiClient.client.auth.currentUser;
      
      final List<Future<dynamic>> futures = [
        GymService.fetchGyms(),
        CategoryService.fetchCategories(),
      ];
      if (user != null) {
        futures.add(UserService.fetchUserProfile(user.id));
      }

      final results = await Future.wait(futures);

      setState(() {
        _gyms = results[0] as List<Gym>;
        _categories = results[1] as List<Category>;
        if (user != null && results.length > 2) {
          _userModel = results[2] as UserModel?;
        } else {
          _userModel = null;
        }
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

  List<Gym> get _featuredGyms {
    if (_userModel != null && _userModel!.interestCategoryIds.isNotEmpty) {
      final matched = _gyms.where((gym) {
        return _userModel!.interestCategoryIds.contains(gym.categoryId);
      }).toList();

      if (matched.isNotEmpty) {
        matched.sort((a, b) => b.rating.compareTo(a.rating));
        return matched;
      }
    }

    final fallback = List<Gym>.from(_gyms);
    fallback.sort((a, b) => b.rating.compareTo(a.rating));
    return fallback.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: Theme.of(context).colorScheme.primary,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // ── Collapsible Header ──
                      SliverAppBar(
                        expandedHeight: 300,
                        collapsedHeight: 64,
                        toolbarHeight: 64,
                        pinned: true,
                        floating: false,
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        surfaceTintColor: Colors.transparent,
                        title: Text(
                          'Gym & Fitness',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
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
                                    child: _buildFeaturedCarousel(),
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
                                            builder: (_) => DetailScreen(gym: gym),
                                          ),
                                        ).then((_) => _loadData());
                                      },
                                    );
                                  },
                                  childCount: _filteredGyms.length,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFeaturedCarousel() {
    final list = _featuredGyms;
    if (list.isEmpty) {
      return _buildGreetingCard();
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: list.length,
          onPageChanged: (index) {
            setState(() {
              _activePage = index;
            });
          },
          itemBuilder: (context, index) {
            final gym = list[index];
            final isRecommended = _userModel != null &&
                _userModel!.interestCategoryIds.contains(gym.categoryId);

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailScreen(gym: gym)),
                ).then((_) => _loadData());
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      gym.imageUrls.isNotEmpty
                          ? Image.network(
                              gym.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildFallbackGradient(gym),
                            )
                          : _buildFallbackGradient(gym),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.75),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isRecommended
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.amber,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isRecommended ? '✨ REKOMENDASI UNTUKMU' : '🔥 TERPOPULER',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              gym.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (gym.categoryName != null) ...[
                                  Text(
                                    gym.categoryName!,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  '${gym.rating}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${gym.reviewCount})',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.white70, size: 12),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    gym.address,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (list.length > 1)
          Positioned(
            bottom: 12,
            right: 20,
            child: Row(
              children: List.generate(
                list.length,
                (index) => Container(
                  width: _activePage == index ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: _activePage == index
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackGradient(Gym gym) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getCategoryGradient(gym.categoryName),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(gym.categoryName),
          size: 48,
          color: Colors.white.withOpacity(0.4),
        ),
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Selamat Pagi';
    if (hour >= 12 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  Widget _buildGreetingCard() {
    final user = ApiClient.client.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String? ??
        user?.email?.split('@').first ??
        'Pengguna';
    final firstName = fullName.split(' ').first;
    final greeting = _getGreeting();

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            greeting,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            firstName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          const Text(
            'Temukan gym terbaik di Surabaya untukmu 💪',
            style: TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 48),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat data',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 12),
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
    );
  }
}

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
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
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
