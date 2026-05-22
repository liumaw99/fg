import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/conversation_model.dart';
import '../../ui/molecules/conversation_tile_view.dart';

/// 会话行业务包装：跳转聊天页。
class ConversationTile extends ConsumerWidget {
  final ConversationModel conversation;

  const ConversationTile({super.key, required this.conversation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = conversation.title ??
        (conversation.participantId != null
            ? conversation.participantId!.substring(0, 6)
            : '对话');
    return ConversationTileView(
      participantName: name,
      lastMessage: conversation.lastMessage?.content ?? '开始聊天',
      lastMessageAt: conversation.lastMessage?.createdAt,
      unreadCount: conversation.unreadCount,
      onTap: () => context.push(
        '/chat/${conversation.id}',
        extra: conversation.participantId,
      ),
    );
  }
}
