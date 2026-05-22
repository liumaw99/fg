import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/interaction_api.dart';
import '../../data/models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../ui/molecules/notification_tile_view.dart';

/// 通知行业务包装：点击 → mark as read + 跳转。
class NotificationTile extends ConsumerWidget {
  final NotificationModel notification;

  const NotificationTile({super.key, required this.notification});

  NotificationKind get _kind {
    switch (notification.type) {
      case 'like':
        return NotificationKind.like;
      case 'reply':
        return NotificationKind.reply;
      case 'follow':
        return NotificationKind.follow;
      case 'repost':
        return NotificationKind.repost;
      case 'mention':
        return NotificationKind.mention;
      default:
        return NotificationKind.reply;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationTileView(
      kind: _kind,
      actorName: notification.actorId?.substring(0, 6) ?? '用户',
      isRead: notification.isRead,
      createdAt: notification.createdAt,
      snippet: notification.content,
      onTap: () async {
        // Mark as read
        if (!notification.isRead) {
          await InteractionApi().markNotificationAsRead(notification.id);
          ref.invalidate(notificationsProvider);
        }
        // Navigate
        if (notification.postId != null && context.mounted) {
          context.push('/post/${notification.postId}');
        }
      },
    );
  }
}
