import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../atoms/app_avatar.dart';
import '../atoms/app_tap.dart';

enum NotificationKind { like, reply, follow, repost, mention }

extension NotificationKindUI on NotificationKind {
  IconData get icon {
    switch (this) {
      case NotificationKind.like:
        return Icons.favorite;
      case NotificationKind.reply:
        return Icons.chat_bubble;
      case NotificationKind.follow:
        return Icons.person_add_alt_1;
      case NotificationKind.repost:
        return Icons.repeat;
      case NotificationKind.mention:
        return Icons.alternate_email;
    }
  }

  Color get color {
    switch (this) {
      case NotificationKind.like:
        return AppColors.like;
      case NotificationKind.repost:
        return AppColors.repost;
      default:
        return const Color(0xFF1D9BF0); // 信息蓝（仅图标点缀，不进入主题）
    }
  }

  String get verb {
    switch (this) {
      case NotificationKind.like:
        return '赞了你的动态';
      case NotificationKind.reply:
        return '回复了你的动态';
      case NotificationKind.follow:
        return '关注了你';
      case NotificationKind.repost:
        return '转发了你的动态';
      case NotificationKind.mention:
        return '提到了你';
    }
  }
}

/// 通知行（纯展示）。
class NotificationTileView extends StatelessWidget {
  final NotificationKind kind;
  final String actorName;
  final String? actorAvatarUrl;
  final String? snippet; // 关联内容预览
  final bool isRead;
  final DateTime createdAt;
  final VoidCallback? onTap;

  const NotificationTileView({
    super.key,
    required this.kind,
    required this.actorName,
    this.actorAvatarUrl,
    this.snippet,
    required this.isRead,
    required this.createdAt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppTap(
      onTap: onTap,
      haptic: false,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      overlayColor: theme.appTextPrimary,
      child: Container(
        color: isRead ? Colors.transparent : theme.appAccent.withAlpha(8),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(kind.icon, size: 24, color: kind.color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppAvatar(
                    imageUrl: actorAvatarUrl,
                    fallbackText: actorName,
                    size: AvatarSize.sm,
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.appTextPrimary,
                        height: 1.4,
                        letterSpacing: -0.05,
                      ),
                      children: [
                        TextSpan(
                          text: actorName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' ${kind.verb}'),
                      ],
                    ),
                  ),
                  if (snippet != null && snippet!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      snippet!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.appTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatShortTime(createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.appTextSecondary,
                    ),
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
