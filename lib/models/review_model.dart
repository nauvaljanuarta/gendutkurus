class Review {
  final int id;
  final int gymId;
  final String userId;
  final String userName;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? userAvatarUrl;

  const Review({
    required this.id,
    required this.gymId,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.userAvatarUrl,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final usersMap = json['users'] as Map<String, dynamic>?;
    final avatarUrl = usersMap?['avatar_url'] as String?;

    return Review(
      id: json['id'] as int,
      gymId: json['gym_id'] as int,
      userId: json['user_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? 'Pengguna',
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      userAvatarUrl: avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gym_id': gymId,
      'user_id': userId,
      'user_name': userName,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'avatar_url': userAvatarUrl,
    };
  }
}

