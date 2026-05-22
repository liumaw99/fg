import 'package:flutter/material.dart';
import '../core/utils/formatters.dart';
import '../data/models/notification_model.dart';
import 'app_avatar.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  IconData get _icon {
    switch (notification.type) {
      case 'like':
        return Icons.favorite;
      case 'reply':
        return Icons.chat_bubble;
      case 'follow':
        return Icons.person_add;
      case 'repost':
        return Icons.repeat;
      default:
        return Icons.notifications;
    }
  }

  Color _iconColor(bool isDark) {
    switch (notification.type) {
      case 'like':
        return isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
      case 'reply':
        return isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);
      case 'follow':
        return isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
      case 'repost':
        return isDark ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED);
      default:
        return isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: notification.isRead
            ? null
            : (isDark
                ? theme.colorScheme.primary.withAlpha(8)
                : theme.colorScheme.primary.withAlpha(5)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _iconColor(isDark).withAlpha(15),
              ),
              child: Center(
                child: Icon(
                  _icon,
                  size: 18,
                  color: _iconColor(isDark),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatTimeAgo(notification.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA),
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, left: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
