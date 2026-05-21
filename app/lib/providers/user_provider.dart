import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api/auth_api.dart';
import '../data/api/post_api.dart';
import '../data/models/post_model.dart';

class UserProfile {
  final String id;
  final String username;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final int followerCount;
  final int followingCount;
  final int postCount;

  UserProfile({
    required this.id,
    required this.username,
    this.displayName = '',
    this.bio = '',
    this.avatarUrl = '',
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      followerCount: json['follower_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      postCount: json['post_count'] as int? ?? 0,
    );
  }
}

final currentUserProvider = FutureProvider<UserProfile?>((ref) async {
  final authApi = AuthApi();
  try {
    final data = await authApi.getMe();
    return UserProfile.fromJson(data);
  } catch (_) {
    return null;
  }
});

final userPostsProvider = FutureProvider.family<List<PostModel>, String>((ref, userId) async {
  final api = PostApi();
  final response = await api.getUserPosts(userId);
  return response.posts;
});
