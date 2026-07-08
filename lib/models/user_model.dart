class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final DateTime createdAt;
  final List<int> interestCategoryIds;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    required this.createdAt,
    this.interestCategoryIds = const [],
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      interestCategoryIds: (json['interest_category_ids'] as List?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'created_at': createdAt.toIso8601String(),
      'interest_category_ids': interestCategoryIds,
      'avatar_url': avatarUrl,
    };
  }
}
