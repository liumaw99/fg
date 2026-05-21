class PostModel {
  final String id;
  final String userId;
  final String content;
  final String? replyToId;
  final String? repostOfId;
  final String status;
  final String visibility;
  final int likeCount;
  final int replyCount;
  final int repostCount;
  final int bookmarkCount;
  final int viewCount;
  final List<PostMedia> mediaUrls;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    this.replyToId,
    this.repostOfId,
    required this.status,
    required this.visibility,
    this.likeCount = 0,
    this.replyCount = 0,
    this.repostCount = 0,
    this.bookmarkCount = 0,
    this.viewCount = 0,
    this.mediaUrls = const [],
    this.isLiked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      replyToId: json['reply_to_id'] as String?,
      repostOfId: json['repost_of_id'] as String?,
      status: json['status'] as String,
      visibility: json['visibility'] as String,
      likeCount: json['like_count'] as int? ?? 0,
      replyCount: json['reply_count'] as int? ?? 0,
      repostCount: json['repost_count'] as int? ?? 0,
      bookmarkCount: json['bookmark_count'] as int? ?? 0,
      viewCount: json['view_count'] as int? ?? 0,
      mediaUrls: (json['media_urls'] as List<dynamic>?)
              ?.map((e) => PostMedia.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isLiked: json['is_liked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

class PostMedia {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final String mimeType;

  PostMedia({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.mimeType,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    return PostMedia(
      id: json['id'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      mimeType: json['mime_type'] as String,
    );
  }
}

class PostListResponse {
  final List<PostModel> posts;
  final String? nextCursor;
  final bool hasMore;

  PostListResponse({
    required this.posts,
    this.nextCursor,
    required this.hasMore,
  });

  factory PostListResponse.fromJson(Map<String, dynamic> json) {
    return PostListResponse(
      posts: (json['posts'] as List<dynamic>)
          .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['next_cursor'] as String?,
      hasMore: json['has_more'] as bool,
    );
  }
}
