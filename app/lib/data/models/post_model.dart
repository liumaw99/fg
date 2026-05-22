class PostAuthor {
  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;

  const PostAuthor({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
    );
  }

  String get effectiveDisplayName => displayName.isNotEmpty
      ? displayName
      : (username.isNotEmpty ? username : '用户');

  String get effectiveUsername => username.isNotEmpty
      ? username
      : (id.isNotEmpty ? 'user_${id.substring(0, 6)}' : 'unknown');
}

class PostModel {
  final String id;
  final String userId;
  final PostAuthor? author;
  final String content;
  final String? replyToId;
  final String? repostOfId;
  final PostModel? repostOf;
  final String status;
  final String visibility;
  final int likeCount;
  final int replyCount;
  final int repostCount;
  final int bookmarkCount;
  final int viewCount;
  final List<PostMedia> mediaUrls;
  final List<PostModel> replies;
  final String? replyToAuthorName;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostModel({
    required this.id,
    required this.userId,
    this.author,
    required this.content,
    this.replyToId,
    this.repostOfId,
    this.repostOf,
    required this.status,
    required this.visibility,
    this.likeCount = 0,
    this.replyCount = 0,
    this.repostCount = 0,
    this.bookmarkCount = 0,
    this.viewCount = 0,
    this.mediaUrls = const [],
    this.replies = const [],
    this.replyToAuthorName,
    this.isLiked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      author: json['author'] == null
          ? null
          : PostAuthor.fromJson(json['author'] as Map<String, dynamic>),
      content: json['content'] as String,
      replyToId: json['reply_to_id'] as String?,
      repostOfId: json['repost_of_id'] as String?,
      repostOf: json['repost_of'] == null
          ? null
          : PostModel.fromJson(json['repost_of'] as Map<String, dynamic>),
      status: json['status'] as String,
      visibility: json['visibility'] as String,
      likeCount: json['like_count'] as int? ?? 0,
      replyCount: json['reply_count'] as int? ?? 0,
      repostCount: json['repost_count'] as int? ?? 0,
      bookmarkCount: json['bookmark_count'] as int? ?? 0,
      viewCount: json['view_count'] as int? ?? 0,
      mediaUrls:
          (json['media_urls'] as List<dynamic>?)
              ?.map((e) => PostMedia.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      replies:
          (json['replies'] as List<dynamic>?)
              ?.map((e) => PostModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      replyToAuthorName: json['reply_to_author_name'] as String?,
      isLiked: json['is_liked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  PostModel copyWith({
    bool? isLiked,
    int? likeCount,
    int? replyCount,
    int? repostCount,
    List<PostModel>? replies,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      author: author,
      content: content,
      replyToId: replyToId,
      repostOfId: repostOfId,
      repostOf: repostOf,
      status: status,
      visibility: visibility,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount ?? this.replyCount,
      repostCount: repostCount ?? this.repostCount,
      bookmarkCount: bookmarkCount,
      viewCount: viewCount,
      mediaUrls: mediaUrls,
      replies: replies ?? this.replies,
      replyToAuthorName: replyToAuthorName,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
      updatedAt: updatedAt,
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

  const PostMedia({
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

  const PostListResponse({
    required this.posts,
    this.nextCursor,
    required this.hasMore,
  });

  factory PostListResponse.fromJson(Map<String, dynamic> json) {
    return PostListResponse(
      posts: (json['posts'] as List<dynamic>? ?? const [])
          .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['next_cursor'] as String?,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}
