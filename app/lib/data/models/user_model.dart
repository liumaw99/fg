class UserModel {
  final String id;
  final String username;
  final String email;
  final String status;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final String coverUrl;
  final String location;
  final String website;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.status = 'active',
    this.displayName = '',
    this.bio = '',
    this.avatarUrl = '',
    this.coverUrl = '',
    this.location = '',
    this.website = '',
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      displayName: json['display_name'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      coverUrl: json['cover_url'] as String? ?? '',
      location: json['location'] as String? ?? '',
      website: json['website'] as String? ?? '',
      followerCount: json['follower_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      postCount: json['post_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  String get displayNameOrUsername =>
      displayName.isNotEmpty ? displayName : username;
}

class UserListResponse {
  final List<UserModel> users;
  final String? nextCursor;
  final bool hasMore;

  UserListResponse({
    required this.users,
    this.nextCursor,
    required this.hasMore,
  });

  factory UserListResponse.fromJson(Map<String, dynamic> json) {
    return UserListResponse(
      users:
          (json['users'] as List<dynamic>?)
              ?.map((e) => UserModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nextCursor: json['next_cursor'] as String?,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}
