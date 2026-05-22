import 'package:flutter/material.dart';
import '../core/utils/formatters.dart';
import '../data/models/conversation_model.dart';
import 'app_avatar.dart';

class ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback? onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasUnread = conversation.unreadCount > 0;
    final lastMsg = conversation.lastMessage;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AppAvatar(
              fallbackText: conversation.participantId,
              size: AvatarSize.lg,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '用户 ${conversation.participantId?.substring(0, 8) ?? ''}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMsg != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          Formatters.formatChatTime(lastMsg.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread
                                ? theme.colorScheme.primary
                                : (isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg?.content ?? '暂无消息',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: hasUnread
                                ? theme.colorScheme.onSurface.withAlpha(220)
                                : (isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA)),
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          height: 20,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              conversation.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
