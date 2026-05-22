import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/formatters.dart';
import '../data/models/post_model.dart';
import 'app_avatar.dart';
import 'app_divider.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onReply;
  final VoidCallback? onRepost;
  final VoidCallback? onShare;
  final VoidCallback? onMore;
  final String? authorName;
  final String? authorAvatarUrl;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onReply,
    this.onRepost,
    this.onShare,
    this.onMore,
    this.authorName,
    this.authorAvatarUrl,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likeCount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likeCount;
  }

  Future<void> _handleLike() async {
    if (_isLoading) return;

    final newIsLiked = !_isLiked;
    final newCount = newIsLiked ? _likeCount + 1 : _likeCount - 1;

    setState(() {
      _isLiked = newIsLiked;
      _likeCount = newCount;
      _isLoading = true;
    });

    try {
      widget.onLike?.call();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF0F0F0),
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme, isDark),
                const SizedBox(height: 10),
                _buildContent(theme),
                if (widget.post.mediaUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildMediaGrid(),
                ],
                const SizedBox(height: 12),
                _buildActions(theme, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppAvatar(
          url: widget.authorAvatarUrl,
          fallbackText: widget.authorName ?? widget.post.userId,
          size: AvatarSize.md,
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
                      widget.authorName ?? widget.post.userId.substring(0, 8),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Formatters.formatShortTime(widget.post.createdAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA),
                    ),
                  ),
                  if (widget.onMore != null)
                    GestureDetector(
                      onTap: widget.onMore,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.more_horiz,
                          size: 18,
                          color: isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '@${widget.post.userId.substring(0, 8)}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Text(
      widget.post.content,
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildMediaGrid() {
    final media = widget.post.mediaUrls;

    if (media.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFF5F5F5),
            child: const Center(
              child: Icon(Icons.image_outlined, size: 40, color: Color(0xFF71717A)),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFF5F5F5),
            child: const Center(
              child: Icon(Icons.image_outlined, color: Color(0xFF71717A)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionItem(
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
          count: widget.post.replyCount,
          onTap: widget.onReply,
        ),
        _ActionItem(
          icon: Icons.repeat,
          activeIcon: Icons.repeat,
          count: widget.post.repostCount,
          onTap: widget.onRepost,
        ),
        _LikeAction(
          isLiked: _isLiked,
          count: _likeCount,
          isLoading: _isLoading,
          onTap: _handleLike,
        ),
        _ActionItem(
          icon: Icons.bookmark_outline,
          activeIcon: Icons.bookmark,
          count: widget.post.bookmarkCount,
          onTap: () {},
        ),
        _ActionItem(
          icon: Icons.share_outlined,
          activeIcon: Icons.share,
          onTap: widget.onShare,
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int? count;
  final VoidCallback? onTap;
  final Color? activeColor;

  const _ActionItem({
    required this.icon,
    required this.activeIcon,
    this.count,
    this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 32,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 4),
              Text(
                Formatters.formatCount(count!),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LikeAction extends StatelessWidget {
  final bool isLiked;
  final int count;
  final bool isLoading;
  final VoidCallback? onTap;

  const _LikeAction({
    required this.isLiked,
    required this.count,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 32,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isLiked
                      ? (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626))
                      : (isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA)),
                ),
              )
            else
              Icon(
                isLiked ? Icons.favorite : Icons.favorite_outline,
                size: 18,
                color: isLiked
                    ? (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626))
                    : (isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA)),
              ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                Formatters.formatCount(count),
                style: TextStyle(
                  fontSize: 12,
                  color: isLiked
                      ? (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626))
                      : (isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
