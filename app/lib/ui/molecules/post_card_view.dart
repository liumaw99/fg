import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../atoms/app_tap.dart';
import 'action_icon.dart';
import 'like_icon.dart';
import 'media_grid.dart';
import 'user_header.dart';

/// 纯展示型 PostCard。**无任何 Provider 依赖**。
///
/// 所有交互通过回调暴露给业务层（features/post/post_card.dart）。
class PostCardView extends StatelessWidget {
  final String displayName;
  final String username;
  final String? avatarUrl;
  final DateTime createdAt;
  final String content;
  final List<String> mediaUrls;
  final int likeCount;
  final int replyCount;
  final int repostCount;
  final bool isLiked;
  final Object? avatarHeroTag;
  final VoidCallback? onTap;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onReply;
  final VoidCallback? onRepost;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onMore;
  final void Function(int index)? onMediaTap;

  const PostCardView({
    super.key,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    required this.createdAt,
    required this.content,
    this.mediaUrls = const [],
    this.likeCount = 0,
    this.replyCount = 0,
    this.repostCount = 0,
    this.isLiked = false,
    this.avatarHeroTag,
    this.onTap,
    this.onAuthorTap,
    this.onReply,
    this.onRepost,
    this.onLike,
    this.onShare,
    this.onMore,
    this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppTap(
      onTap: onTap,
      haptic: false,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.appBorder, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: UserHeader(
                    displayName: displayName,
                    username: username,
                    avatarUrl: avatarUrl,
                    time: createdAt,
                    onAvatarTap: onAuthorTap,
                    avatarHeroTag: avatarHeroTag,
                  ),
                ),
                if (onMore != null)
                  IconButton(
                    onPressed: onMore,
                    icon: Icon(
                      Icons.more_horiz,
                      size: 18,
                      color: theme.appTextSecondary,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: theme.appTextPrimary,
                    letterSpacing: -0.05,
                  ),
                ),
              ),
            ],
            if (mediaUrls.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: MediaGrid(imageUrls: mediaUrls, onTap: onMediaTap),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ActionIcon(
                    icon: Icons.chat_bubble_outline,
                    count: replyCount,
                    onTap: onReply,
                    semanticLabel: '回复',
                  ),
                  ActionIcon(
                    icon: Icons.repeat,
                    count: repostCount,
                    onTap: onRepost,
                    activeColor: AppColors.repost,
                    semanticLabel: '转发',
                  ),
                  LikeIcon(isLiked: isLiked, count: likeCount, onTap: onLike),
                  ActionIcon(
                    icon: Icons.share_outlined,
                    onTap: onShare,
                    semanticLabel: '分享',
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
