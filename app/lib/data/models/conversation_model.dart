import 'message_model.dart';

class ConversationModel {
  final String id;
  final String type;
  final String? title;
  final String? participantId;
  final MessageModel? lastMessage;
  final int unreadCount;
  final DateTime createdAt;

  ConversationModel({
    required this.id,
    required this.type,
    this.title,
    this.participantId,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String?,
      participantId: json['participant_id'] as String?,
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ConversationListResponse {
  final List<ConversationModel> conversations;
  final String? nextCursor;
  final bool hasMore;

  ConversationListResponse({
    required this.conversations,
    this.nextCursor,
    required this.hasMore,
  });

  factory ConversationListResponse.fromJson(Map<String, dynamic> json) {
    return ConversationListResponse(
      conversations:
          (json['conversations'] as List<dynamic>?)
              ?.map(
                (e) => ConversationModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      nextCursor: json['next_cursor'] as String?,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}
