import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/api/interaction_api.dart';
import '../../data/models/post_model.dart';
import '../../providers/post_provider.dart';
import '../../router/route_names.dart';
import '../../screens/post/image_preview_screen.dart';
import '../../ui/atoms/app_haptic.dart';
import '../../ui/molecules/media_grid.dart';
import '../../ui/molecules/post_card_view.dart';
import 'post_actions_sheet.dart';

/// 业务包装的 PostCard：连接 InteractionApi、跳转路由、乐观更新。
///
/// 上层（timeline / profile）只需要传 [post]，并可选择性提供 [onUpdate]
/// 回调，让对应 Provider 同步乐观更新（不刷新整列）。
class PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  final void Function(PostModel updated)? onUpdate;

  const PostCard({super.key, required this.post, this.onUpdate});

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  final _api = InteractionApi();
  bool _busy = false;
  bool _reposting = false;

  Future<void> _toggleLike() async {
    if (_busy) return;
    final p = widget.post;
    final next = p.copyWith(
      isLiked: !p.isLiked,
      likeCount: p.isLiked ? p.likeCount - 1 : p.likeCount + 1,
    );
    widget.onUpdate?.call(next);

    setState(() => _busy = true);
    try {
      if (next.isLiked) {
        await _api.like(p.id);
      } else {
        await _api.unlike(p.id);
      }
    } catch (e) {
      // 回滚
      widget.onUpdate?.call(p);
      if (mounted) {
        AppHaptic.heavy();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showActions() {
    showPostActionsSheet(context, post: widget.post);
  }

  Future<void> _quickRepost() async {
    if (_reposting) return;
    final p = widget.post;
    final target = p.repostOf ?? p;
    if (target.id == p.id) {
      widget.onUpdate?.call(p.copyWith(repostCount: p.repostCount + 1));
    }
    setState(() => _reposting = true);
    try {
      await ref.read(createRepostProvider.notifier).createRepost(target.id);
      final state = ref.read(createRepostProvider);
      if (state.hasError) {
        throw state.error ?? 'unknown error';
      }
      ref.read(feedPostsProvider.notifier).refresh();
      ref.invalidate(postDetailProvider(target.id));
      if (target.id != p.id) {
        ref.invalidate(postDetailProvider(p.id));
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已转发')));
      }
    } catch (e) {
      widget.onUpdate?.call(p);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('转发失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _reposting = false);
    }
  }

  Future<void> _showRepostSheet() async {
    final action = await showModalBottomSheet<_RepostAction>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).appBackground,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.repeat_rounded),
              title: const Text('快速转发'),
              subtitle: const Text('不添加文字，直接转发到你的主页'),
              onTap: () => Navigator.pop(ctx, _RepostAction.quick),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded),
              title: const Text('引用转发'),
              subtitle: const Text('添加文字或图片再转发'),
              onTap: () => Navigator.pop(ctx, _RepostAction.quote),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _RepostAction.quick:
        await _quickRepost();
        break;
      case _RepostAction.quote:
        context.push(
          RouteNames.createPost,
          extra: widget.post.repostOf ?? widget.post,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final author = p.author;
    final mediaUrls = p.mediaUrls.map((m) => m.url).toList();
    return PostCardView(
      displayName: author?.effectiveDisplayName ?? '用户',
      username: author?.effectiveUsername ?? 'user_${p.userId.substring(0, 6)}',
      avatarUrl: author?.avatarUrl,
      createdAt: p.createdAt,
      content: p.content,
      mediaUrls: mediaUrls,
      repostPreview: p.repostOf == null
          ? null
          : _RepostPreviewCard(
              post: p.repostOf!,
              onTap: () => context.push('/post/${p.repostOf!.id}'),
            ),
      likeCount: p.likeCount,
      replyCount: p.replyCount,
      repostCount: p.repostCount,
      isLiked: p.isLiked,
      avatarHeroTag: 'avatar_${p.id}',
      onTap: () => context.push('/post/${p.id}'),
      onMediaTap: (index) {
        context.push(
          RouteNames.imagePreview,
          extra: ImagePreviewArgs(imageUrls: mediaUrls, initialIndex: index),
        );
      },
      onAuthorTap: () {
        final uname = author?.username;
        if (uname != null && uname.isNotEmpty) {
          context.push('/user/$uname');
        }
      },
      onReply: () => context.push('/post/${p.id}'),
      onRepost: _showRepostSheet,
      onLike: _toggleLike,
      onShare: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已复制动态链接')));
      },
      onMore: _showActions,
    );
  }
}

enum _RepostAction { quick, quote }

class _RepostPreviewCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const _RepostPreviewCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = post.author;
    final displayName = author?.effectiveDisplayName ?? '用户';
    final username =
        author?.effectiveUsername ?? 'user_${post.userId.substring(0, 6)}';
    final mediaUrls = post.mediaUrls.map((m) => m.url).toList();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$displayName @$username',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.appTextPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (post.content.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.appTextSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
            if (mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              MediaGrid(imageUrls: mediaUrls),
            ],
          ],
        ),
      ),
    );
  }
}

/// 时间线专用：把更新回写到 FeedPosts。
class FeedPostCard extends ConsumerWidget {
  final PostModel post;

  const FeedPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PostCard(
      post: post,
      onUpdate: (updated) =>
          ref.read(feedPostsProvider.notifier).updatePost(updated),
    );
  }
}

/// 用户主页专用：把更新回写到 UserPosts。
class UserPostCard extends ConsumerWidget {
  final PostModel post;
  final String userId;

  const UserPostCard({super.key, required this.post, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PostCard(
      post: post,
      onUpdate: (updated) =>
          ref.read(userPostsProvider(userId).notifier).updatePost(updated),
    );
  }
}
