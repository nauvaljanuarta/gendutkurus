class Favorite {
  final int id;
  final int gymId;
  final String userId;
  final DateTime createdAt;

  const Favorite({
    required this.id,
    required this.gymId,
    required this.userId,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] as int,
      gymId: json['gym_id'] as int,
      userId: json['user_id'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gym_id': gymId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
