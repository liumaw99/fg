import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/interaction_api.dart';
import '../../data/models/post_model.dart';
import '../../providers/post_provider.dart';
import '../../ui/atoms/app_haptic.dart';
import '../../ui/molecules/post_card_view.dart';
import 'post_actions_sheet.dart';

/// 业务包装的 PostCard：连接 InteractionApi、跳转路由、乐观更新。
///
/// 上层（timeline / profile）只需要传 [post]，并可选择性提供 [onUpdate]
/// 回调，让对应 Provider 同步乐观更新（不刷新整列）。
class PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  final void Function(PostModel updated)? onUpdate;

  const PostCard({
    super.key,
    required this.post,
    this.onUpdate,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  final _api = InteractionApi();
  bool _busy = false;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showActions() {
    showPostActionsSheet(context, post: widget.post);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final author = p.author;
    return PostCardView(
      displayName: author?.effectiveDisplayName ?? '用户',
      username: author?.effectiveUsername ?? 'user_${p.userId.substring(0, 6)}',
      avatarUrl: author?.avatarUrl,
      createdAt: p.createdAt,
      content: p.content,
      mediaUrls: p.mediaUrls.map((m) => m.url).toList(),
      likeCount: p.likeCount,
      replyCount: p.replyCount,
      repostCount: p.repostCount,
      isLiked: p.isLiked,
      avatarHeroTag: 'avatar_${p.id}',
      onTap: () => context.push('/post/${p.id}'),
      onAuthorTap: () {
        final uname = author?.username;
        if (uname != null && uname.isNotEmpty) {
          context.push('/user/$uname');
        }
      },
      onReply: () => context.push('/post/${p.id}'),
      onRepost: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('转发功能即将上线')),
        );
      },
      onLike: _toggleLike,
      onShare: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已复制动态链接')),
        );
      },
      onMore: _showActions,
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
      onUpdate: (updated) => ref.read(feedPostsProvider.notifier).updatePost(updated),
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
      onUpdate: (updated) => ref.read(userPostsProvider(userId).notifier).updatePost(updated),
    );
  }
}
