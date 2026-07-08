import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/gym_model.dart';
import '../../services/api_client.dart';
import '../../services/favorite_service.dart';
import 'detail_map_screen.dart';
import '../../services/review_service.dart';
import '../../models/review_model.dart';

class DetailScreen extends StatefulWidget {
  final Gym gym;

  const DetailScreen({super.key, required this.gym});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Gym get gym => widget.gym;
  List<Review> _reviews = [];
  bool _isLoadingReviews = true;
  bool _isFavorite = false;
  bool _isCheckingFavorite = true;
  
  // Variabel baru untuk melacak gambar yang sedang dilihat
  int _currentImageIndex = 0;

  // Rate limiting untuk website button
  bool _isWebsiteOnCooldown = false;

  /// Rating kumulatif: (googleRating × googleCount + appSum) / (googleCount + appCount)
  double get _cumulativeRating {
    final appSum = _reviews.fold<int>(0, (sum, r) => sum + r.rating);
    final appCount = _reviews.length;
    final totalCount = gym.reviewCount + appCount;
    if (totalCount == 0) return 0.0;
    return (gym.rating * gym.reviewCount + appSum) / totalCount;
  }

  /// Total review: Google + app
  int get _totalReviewCount => gym.reviewCount + _reviews.length;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    if (!mounted) return;
    setState(() => _isLoadingReviews = true);
    try {
      final reviews = await ReviewService.fetchReviews(gym.gymId);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  Future<void> _checkIfFavorite() async {
    final user = ApiClient.client.auth.currentUser;
    if (user != null) {
      try {
        final isFav = await FavoriteService.isFavorite(user.id, gym.gymId);
        if (mounted) {
          setState(() {
            _isFavorite = isFav;
            _isCheckingFavorite = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isCheckingFavorite = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isCheckingFavorite = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final user = ApiClient.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu untuk menyukai gym ini'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final newFavState = await FavoriteService.toggleFavorite(user.id, gym.gymId);
      if (mounted) {
        setState(() {
          _isFavorite = newFavState;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newFavState
                ? 'Gym berhasil ditambahkan ke favorit'
                : 'Gym berhasil dihapus dari favorit'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui favorit: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Gym'), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // BAGIAN YANG DIUBAH: MENAMPILKAN SLIDER GAMBAR
            _buildImageSlider(),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          gym.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isCheckingFavorite
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: _isFavorite ? Colors.redAccent : Colors.white60,
                                size: 28,
                              ),
                              onPressed: _toggleFavorite,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFFD700),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      _isLoadingReviews
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFFD700)),
                              ),
                            )
                          : Text(
                              _totalReviewCount == 0
                                  ? 'Belum ada ulasan'
                                  : _cumulativeRating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 16),
                            ),
                      if (!_isLoadingReviews && _totalReviewCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '($_totalReviewCount ulasan)',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  const SizedBox(height: 20),
                  const Text(
                    'Alamat Lengkap',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 18, color: Colors.white54),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          gym.address,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (gym.phone != null || (gym.website != null && gym.website!.isNotEmpty && gym.website!.toLowerCase() != 'tidak tersedia' && gym.website! != '-')) ...[
                    const Text(
                      'Kontak',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (gym.phone != null)
                          _InfoChip(
                              icon: Icons.phone, label: gym.phone!),
                        if (gym.website != null &&
                            gym.website!.isNotEmpty &&
                            gym.website!.toLowerCase() != 'tidak tersedia' &&
                            gym.website! != '-')
                          InkWell(
                            onTap: _isWebsiteOnCooldown ? null : () => _openWebsite(context),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2979FF), Color(0xFF00B0FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2979FF).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.language, size: 16, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Info GYM',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gym.description.isEmpty
                        ? 'Tidak ada deskripsi tersedia.'
                        : gym.description,
                    style: const TextStyle(
                        color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  _buildElegantOpeningHours(gym.openingHours),
                  const SizedBox(height: 12),
                  if (gym.latitude != 0.0 && gym.longitude != 0.0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map_outlined,
                              color: Color(0xFF2979FF), size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Koordinat: ${gym.latitude.toStringAsFixed(4)}, ${gym.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailMapScreen(gym: gym),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2979FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.navigation),
                      label: const Text('Rute di Aplikasi'),
                    ),
                  ),
                  // const SizedBox(height: 12),
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: OutlinedButton.icon(
                  //     onPressed: () => _openGoogleMaps(context),
                  //     style: OutlinedButton.styleFrom(
                  //       foregroundColor: Colors.white70,
                  //       side: const BorderSide(color: Colors.white24),
                  //       padding: const EdgeInsets.symmetric(vertical: 14),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(16),
                  //       ),
                  //     ),
                  //     icon: const Icon(Icons.location_on),
                  //     label: const Text('Lihat Lokasi di Google Maps'),
                  //   ), 
                  // ),
                  const SizedBox(height: 16),
                      // 1. TOMBOL GOOGLE MAPS
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openGoogleMaps(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.location_on),
                      label: const Text('Lihat Lokasi di Google Maps'),
                    ), // <-- Perhatikan tutup kurung ini
                  ),

                  // 2. JARAK ANTARA KEDUA TOMBOL
                  const SizedBox(height: 16),

                  // 3. TOMBOL TULIS ULASAN
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF2979FF), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _showAddReviewDialog(context),
                      icon: const Icon(Icons.rate_review, color: Color(0xFF2979FF)),
                      label: const Text(
                        'Tulis Ulasan Anda',
                        style: TextStyle(color: Color(0xFF2979FF), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // =====================================
                  // TAMBAHKAN BAGIAN INI DI SINI
                  // =====================================
                  const SizedBox(height: 32),
                  const Text(
                    'Ulasan Pengunjung',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  _buildReviewList(), // <--- MEMANGGIL DAFTAR REVIEW
                  // =====================================

                  // JARAK BAWAH
                  const SizedBox(height: 40),
                ],
                
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET JADWAL BUKA (ANTI-MENYAMBUNG 100%)
  // ==========================================
  Widget _buildElegantOpeningHours(String rawHours) {
    if (rawHours.isEmpty || rawHours.toLowerCase() == 'tidak tersedia' || rawHours == '-') {
      return const SizedBox.shrink(); // Sembunyikan kotak jika tidak ada data
    }

    // 1. Trik: Beri pemisah '|' sebelum setiap nama hari agar mudah dipotong
    String formattedText = rawHours;
    final List<String> days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    
    for (String day in days) {
      formattedText = formattedText.replaceAll(day, '|$day');
    }

    // 2. Potong berdasarkan tanda '|'
    final List<String> scheduleParts = formattedText.split('|').where((s) => s.isNotEmpty).toList();

    if (scheduleParts.isEmpty) {
      return Text(rawHours, style: const TextStyle(color: Colors.white70));
    }

    List<Widget> scheduleWidgets = [];
    for (String part in scheduleParts) {
      // Cari tau ini hari apa
      String currentDay = days.firstWhere((d) => part.startsWith(d), orElse: () => '');
      if (currentDay.isEmpty) continue;

      // Ambil sisa teks setelah nama hari sebagai jam
      String time = part.substring(currentDay.length).trim();

      bool isClosed = time.toLowerCase().contains('tutup');
      bool is24Hours = time.toLowerCase().contains('24 jam');

      if (isClosed) {
        time = 'Tutup';
      } else if (is24Hours) {
        time = 'Buka 24 Jam';
      } else {
        // Trik Jitu: Ambil SEMUA format jam (contoh: 08.00) dari teks
        final timeRegex = RegExp(r'\d{2}\.\d{2}');
        final times = timeRegex.allMatches(time).map((m) => m.group(0)!).toList();
        
        // Jika jumlah angka genap (contoh: 4 angka = 2 sesi buka)
        if (times.isNotEmpty && times.length % 2 == 0) {
          List<String> ranges = [];
          for (int i = 0; i < times.length; i += 2) {
            ranges.add('${times[i]} - ${times[i+1]}');
          }
          // Gabungkan dengan koma (contoh: 08.00 - 12.00, 16.00 - 21.00)
          time = ranges.join(', '); 
        }
      }

      scheduleWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentDay,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                time.isEmpty ? 'Tidak ada data' : time,
                style: TextStyle(
                  color: isClosed ? Colors.redAccent : Colors.white70,
                  fontSize: 14,
                  fontWeight: isClosed ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Tampilan Kotak Kartu (Card) Elegan
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Warna kotak senada dengan background gelap
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.calendar_month, color: Color(0xFF2979FF), size: 20),
              SizedBox(width: 8),
              Text(
                'Jadwal Operasional',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          ...scheduleWidgets,
        ],
      ),
    );
  }

  // WIDGET BARU UNTUK SLIDER GAMBAR
  Widget _buildImageSlider() {
    // Jika tidak ada gambar di database, tampilkan warna warni bawaan Anda
    if (gym.imageUrls.isEmpty) {
      return _buildFallbackGradient();
    }

    // Jika ada gambar, buat Slider yang bisa digeser
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 250, // Tinggi slider gambar
          width: double.infinity,
          child: PageView.builder(
            itemCount: gym.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                gym.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallbackGradient(),
              );
            },
          ),
        ),
        
        // Titik-titik indikator (Dots) di atas gambar
        if (gym.imageUrls.length > 1)
          Positioned(
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                gym.imageUrls.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index ? const Color(0xFF2979FF) : Colors.white70,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Menampilkan warna warni 
  Widget _buildFallbackGradient() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getCategoryGradient(gym.categoryName),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(gym.categoryName),
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            if (gym.categoryName != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  gym.categoryName!,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWebsite(BuildContext context) async {
    // Rate limit: prevent rapid-fire taps
    if (_isWebsiteOnCooldown) return;
    setState(() {
      _isWebsiteOnCooldown = true;
    });

    String urlString = gym.website!;
    if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
      urlString = 'https://$urlString';
    }
    final url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka website: $e')),
        );
      }
    }

    // Cooldown 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isWebsiteOnCooldown = false;
        });
      }
    });
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    if (gym.latitude == 0.0 && gym.longitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Koordinat gym tidak tersedia')));
      return;
    }
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${gym.latitude},${gym.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka Google Maps')));
      }
    }
  }

  List<Color> _getCategoryGradient(String? category) {
    switch (category?.toLowerCase()) {
      case 'gym premium': return [const Color(0xFF6A11CB), const Color(0xFF2575FC)];
      case 'gym murah': return [const Color(0xFF11998E), const Color(0xFF38EF7D)];
      case 'gym 24 jam': return [const Color(0xFFFC466B), const Color(0xFF3F5EFB)];
      case 'fitness wanita': return [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)];
      case 'crossfit': return [const Color(0xFFF7971E), const Color(0xFFFFD200)];
      default: return [const Color(0xFF2979FF), const Color(0xFF00BCD4)];
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'gym premium': return Icons.fitness_center;
      case 'gym murah': return Icons.attach_money;
      case 'gym 24 jam': return Icons.schedule;
      case 'fitness wanita': return Icons.female;
      case 'crossfit': return Icons.sports_gymnastics;
      default: return Icons.fitness_center;
    }
  }

  // Fungsi untuk menampilkan Pop-up form review
  void _showAddReviewDialog(BuildContext context) {
    final user = ApiClient.client.auth.currentUser;
    
    // Cek apakah user sudah login
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu untuk memberi ulasan!')),
      );
      return;
    }

    int selectedRating = 5;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder digunakan agar bintang bisa diklik dan berubah warna di dalam dialog
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Tulis Ulasan', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Barisan Bintang Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  // Kolom Teks Komentar
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Bagaimana pengalaman Anda di gym ini?',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2979FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (commentController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Komentar tidak boleh kosong')),
                            );
                            return;
                          }

                          setStateDialog(() => isSubmitting = true);

                          // Tangkap nama user yang sedang login
                          String currentUserName = user.userMetadata?['full_name'] as String? ?? 'Pengguna';

                          bool success = false;
                          try {
                            // Kirim ke database
                            await ReviewService.addReview(
                              gymId: gym.gymId, 
                              userId: user.id,
                              userName: currentUserName, // <-- JANGAN LUPA TAMBAHKAN INI
                              rating: selectedRating,
                              comment: commentController.text.trim(),
                            );
                            success = true;
                          } catch (e) {
                            success = false;
                          }

                          setStateDialog(() => isSubmitting = false);

                          if (success) {
                            Navigator.pop(context); // Tutup dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ulasan berhasil dikirim!')),
                            );
                            _fetchReviews(); // Refresh daftar review
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Gagal mengirim ulasan')),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16, height: 16, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Kirim', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // WIDGET UNTUK MENAMPILKAN DAFTAR REVIEW
  // ==========================================
  Widget _buildReviewList() {
    // Jika masih loading
    if (_isLoadingReviews) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2979FF)));
    }

    // Jika belum ada review sama sekali
    if (_reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: const Text(
          'Belum ada ulasan. Jadilah yang pertama mengulas gym ini!',
          style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Jika ada review, tampilkan daftarnya
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _reviews.map((review) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    review.userName, 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Spacer(),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < review.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 14,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                review.comment ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2979FF)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}