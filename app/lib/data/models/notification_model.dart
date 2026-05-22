class NotificationModel {
  final String id;
  final String userId;
  final String? actorId;
  final String type;
  final String? postId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.actorId,
    required this.type,
    this.postId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      actorId: json['actor_id'] as String?,
      type: json['type'] as String,
      postId: json['post_id'] as String?,
      content: json['content'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class NotificationListResponse {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final String? nextCursor;
  final bool hasMore;

  NotificationListResponse({
    required this.notifications,
    this.unreadCount = 0,
    this.nextCursor,
    required this.hasMore,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      notifications: (json['notifications'] as List<dynamic>?)
              ?.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      unreadCount: json['unread_count'] as int? ?? 0,
      nextCursor: json['next_cursor'] as String?,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}
