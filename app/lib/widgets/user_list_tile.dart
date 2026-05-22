import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import 'app_avatar.dart';
import 'app_button.dart';

class UserListTile extends StatelessWidget {
  final UserModel user;
  final bool isFollowing;
  final bool showFollowButton;
  final VoidCallback? onTap;
  final VoidCallback? onFollowToggle;

  const UserListTile({
    super.key,
    required this.user,
    this.isFollowing = false,
    this.showFollowButton = true,
    this.onTap,
    this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AppAvatar(
              url: user.avatarUrl,
              fallbackText: user.displayNameOrUsername,
              size: AvatarSize.lg,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayNameOrUsername,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA),
                    ),
                  ),
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.bio,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (showFollowButton) ...[
              const SizedBox(width: 12),
              SizedBox(
                height: 32,
                child: AppButton(
                  label: isFollowing ? '已关注' : '关注',
                  onPressed: onFollowToggle,
                  variant: isFollowing ? AppButtonVariant.secondary : AppButtonVariant.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
