class Gym {
  final int gymId;
  final String name;

  /// Rating asli dari Google Maps (tidak pernah diubah)
  final double rating;

  /// Jumlah review asli dari Google Maps (tidak pernah diubah)
  final int reviewCount;

  /// Jumlah review dari pengguna Gendut Kurus
  final int appReviewCount;

  /// Total nilai (sum) rating dari pengguna Gendut Kurus
  final int appReviewSum;

  final String address;
  final String? phone;
  final String? website;
  final String openingHours;
  final double latitude;
  final double longitude;
  final int categoryId;
  final String description;
  final List<String> imageUrls;

  // Dari join tabel categories
  final String? categoryName;
  final String? categoryIcon;

  const Gym({
    required this.gymId,
    required this.name,
    required this.rating,
    required this.reviewCount,
    this.appReviewCount = 0,
    this.appReviewSum = 0,
    required this.address,
    this.phone,
    this.website,
    required this.openingHours,
    required this.latitude,
    required this.longitude,
    required this.categoryId,
    required this.description,
    required this.imageUrls,
    this.categoryName,
    this.categoryIcon,
  });

  /// Rating kumulatif (Google + App) menggunakan weighted average:
  /// (googleRating × googleReviewCount + appReviewSum) / (googleReviewCount + appReviewCount)
  double get cumulativeRating {
    final totalCount = reviewCount + appReviewCount;
    if (totalCount == 0) return 0.0;
    return (rating * reviewCount + appReviewSum) / totalCount;
  }

  /// Total jumlah review (Google + App)
  int get totalReviewCount => reviewCount + appReviewCount;

  factory Gym.fromJson(Map<String, dynamic> json) {
    var imageList = json['gym_images'] as List<dynamic>? ?? [];
    List<String> parsedImages = imageList.map((img) {
      String url = (img['image_url'] as String? ?? '')
          .replaceAll(RegExp(r'\s+'), '')// Hapus spasi & newline
          .replaceAll(RegExp(r'[\[\]]'), ''); // Hapus karakter [ dan ]
      // Otomatis ubah http ke https agar tidak diblokir Android
      if (url.startsWith('http://')) {
        url = url.replaceFirst('http://', 'https://');
      }
      return url;
    }).toList();

    return Gym(
      gymId: json['gym_id'] as int,
      name: json['name'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      openingHours: json['opening_hours'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      categoryId: json['category_id'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      imageUrls: parsedImages,
      categoryName: json['categories'] != null
          ? json['categories']['name'] as String?
          : null,
      categoryIcon: json['categories'] != null
          ? json['categories']['icon'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gym_id': gymId,
      'name': name,
      'rating': rating,
      'review_count': reviewCount,
      'address': address,
      'phone': phone,
      'website': website,
      'opening_hours': openingHours,
      'latitude': latitude,
      'longitude': longitude,
      'category_id': categoryId,
      'description': description,
      'gym_images': imageUrls.map((url) => {'image_url': url}).toList(),
    };
  }

  /// Salinan Gym dengan data review app yang sudah dihitung
  Gym copyWithAppStats({
    required int appReviewSum,
    required int appReviewCount,
  }) {
    return Gym(
      gymId: gymId,
      name: name,
      rating: rating,           // Google rating tetap tidak berubah
      reviewCount: reviewCount, // Google review count tetap tidak berubah
      appReviewSum: appReviewSum,
      appReviewCount: appReviewCount,
      address: address,
      phone: phone,
      website: website,
      openingHours: openingHours,
      latitude: latitude,
      longitude: longitude,
      categoryId: categoryId,
      description: description,
      imageUrls: imageUrls,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
    );
  }
}
