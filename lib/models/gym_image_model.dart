class GymImage {
  final int id;
  final int gymId;
  final String imageUrl;
  final DateTime createdAt;

  const GymImage({
    required this.id,
    required this.gymId,
    required this.imageUrl,
    required this.createdAt,
  });

  factory GymImage.fromJson(Map<String, dynamic> json) {
    return GymImage(
      id: json['id'] as int,
      gymId: json['gym_id'] as int,
      imageUrl: json['image_url'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gym_id': gymId,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
