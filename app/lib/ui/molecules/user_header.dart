import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../atoms/app_avatar.dart';

/// 通用「头像 + 名字 + @username + 时间 + trailing」横向头部。
///
/// 纯展示组件，被 PostCard / UserTile / NotificationTile / ConversationTile 复用。
class UserHeader extends StatelessWidget {
  final String displayName;
  final String username;
  final String? avatarUrl;
  final DateTime? time;
  final Widget? trailing;
  final VoidCallback? onAvatarTap;
  final Object? avatarHeroTag;
  final AvatarSize avatarSize;
  final bool dense;

  const UserHeader({
    super.key,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.time,
    this.trailing,
    this.onAvatarTap,
    this.avatarHeroTag,
    this.avatarSize = AvatarSize.md,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppAvatar(
          imageUrl: avatarUrl,
          fallbackText: displayName,
          size: avatarSize,
          onTap: onAvatarTap,
          heroTag: avatarHeroTag,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: dense ? _buildDenseInline(theme) : _buildStacked(theme),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }

  Widget _buildStacked(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.appTextPrimary,
                  letterSpacing: -0.1,
                  height: 1.3,
                ),
              ),
            ),
            if (time != null) ...[
              Text(
                '  ·  ',
                style: TextStyle(color: theme.appTextSecondary, fontSize: 14),
              ),
              Text(
                Formatters.formatShortTime(time!),
                style: TextStyle(fontSize: 14, color: theme.appTextSecondary),
              ),
            ],
          ],
        ),
        Text(
          '@$username',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: theme.appTextSecondary,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildDenseInline(ThemeData theme) {
    return Row(
      children: [
        Flexible(
          child: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.appTextPrimary,
              letterSpacing: -0.1,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '@$username',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: theme.appTextSecondary),
          ),
        ),
        if (time != null) ...[
          Text(
            '  ·  ',
            style: TextStyle(color: theme.appTextSecondary, fontSize: 14),
          ),
          Text(
            Formatters.formatShortTime(time!),
            style: TextStyle(fontSize: 14, color: theme.appTextSecondary),
          ),
        ],
      ],
    );
  }
}
