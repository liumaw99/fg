import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../atoms/app_avatar.dart';
import '../atoms/app_tap.dart';

/// 用户行（搜索结果、粉丝/关注列表使用）。
class UserTileView extends StatelessWidget {
  final String displayName;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final Widget? trailing; // 通常是 FollowButton（业务层注入）
  final VoidCallback? onTap;

  const UserTileView({
    super.key,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.trailing,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            imageUrl: avatarUrl,
            fallbackText: displayName,
            size: AvatarSize.md,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
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
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
                if (bio != null && bio!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    bio!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.appTextPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
