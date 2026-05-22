import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/post_model.dart';
import '../../providers/post_provider.dart';
import '../../providers/user_provider.dart';
import '../../router/route_names.dart';
import '../../ui/atoms/app_avatar.dart';
import '../../ui/atoms/app_divider.dart';
import '../../ui/molecules/media_grid.dart';
import '../../ui/molecules/user_header.dart';
import '../../ui/states/empty_state.dart';
import '../../ui/states/error_state.dart';
import '../../ui/states/loading_state.dart';
import 'image_preview_screen.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _replyController = TextEditingController();
  final _replyFocusNode = FocusNode();
  String? _replyTargetId;
  String? _replyTargetName;

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    final targetId = _replyTargetId ?? widget.postId;
    _replyController.clear();
    FocusScope.of(context).unfocus();

    await ref
        .read(createReplyProvider.notifier)
        .createReply(postId: targetId, content: content);
    final state = ref.read(createReplyProvider);
    if (!mounted) return;

    if (state.hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('回复失败：${state.error}')));
      return;
    }

    setState(() {
      _replyTargetId = null;
      _replyTargetName = null;
    });
    ref.invalidate(postDetailProvider(widget.postId));
    ref.invalidate(postRepliesProvider(widget.postId));
  }

  void _setReplyTarget(PostModel reply) {
    setState(() {
      _replyTargetId = reply.id;
      _replyTargetName = reply.author?.effectiveDisplayName ?? '用户';
    });
    _replyFocusNode.requestFocus();
  }

  Future<void> _deleteReply(PostModel reply) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除回复？'),
        content: const Text('删除后将无法恢复'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(postApiProvider).deletePost(reply.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败：$e')));
      return;
    }
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已删除回复')));
    ref.invalidate(postDetailProvider(widget.postId));
    ref.invalidate(postRepliesProvider(widget.postId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final createReplyState = ref.watch(createReplyProvider);
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('动态')),
      body: postAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(postDetailProvider(widget.postId)),
        ),
        data: (post) {
          if (post == null) {
            return const EmptyState(
              icon: Icons.article_outlined,
              title: AppStrings.notFound,
            );
          }
          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _PostDetailContent(post: post)),
                    SliverToBoxAdapter(
                      child: _ReplySectionHeader(
                        postId: post.id,
                        fallbackCount: post.replyCount,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _ReplyList(
                        postId: post.id,
                        currentUserId: currentUserId,
                        onReplyTap: _setReplyTarget,
                        onDeleteTap: _deleteReply,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.appBorder, width: 0.5),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_replyTargetName != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: theme.appSurfaceElevated,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.reply_rounded,
                                  size: 16,
                                  color: theme.appTextSecondary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    '正在回复 $_replyTargetName',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.appTextSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _replyTargetId = null;
                                    _replyTargetName = null;
                                  }),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: theme.appTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        Row(
                          children: [
                            const AppAvatar(
                              fallbackText: 'Me',
                              size: AvatarSize.sm,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: TextField(
                                controller: _replyController,
                                focusNode: _replyFocusNode,
                                style: TextStyle(
                                  color: theme.appTextPrimary,
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  hintText: _replyTargetName == null
                                      ? '写回复...'
                                      : '继续回复...',
                                  hintStyle: TextStyle(
                                    color: theme.appTextTertiary,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9999),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: theme.appSurfaceElevated,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                onSubmitted: (_) => _submitReply(),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            IconButton(
                              onPressed: createReplyState.isLoading
                                  ? null
                                  : _submitReply,
                              icon: createReplyState.isLoading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: theme.appTextSecondary,
                                      ),
                                    )
                                  : Icon(
                                      Icons.arrow_upward_rounded,
                                      color: theme.appTextPrimary,
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReplySectionHeader extends ConsumerWidget {
  final String postId;
  final int fallbackCount;

  const _ReplySectionHeader({
    required this.postId,
    required this.fallbackCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repliesAsync = ref.watch(postRepliesProvider(postId));
    final count = repliesAsync.maybeWhen(
      data: (replies) => _countReplies(replies),
      orElse: () => fallbackCount,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            '全部回复',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: theme.appTextPrimary,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            Formatters.formatCount(count),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyList extends ConsumerWidget {
  final String postId;
  final String? currentUserId;
  final ValueChanged<PostModel> onReplyTap;
  final ValueChanged<PostModel> onDeleteTap;

  const _ReplyList({
    required this.postId,
    required this.currentUserId,
    required this.onReplyTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repliesAsync = ref.watch(postRepliesProvider(postId));
    return repliesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: LoadingState(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(postRepliesProvider(postId)),
        ),
      ),
      data: (replies) {
        if (replies.isEmpty) {
          return const EmptyState(
            icon: Icons.chat_bubble_outline,
            title: '暂无回复',
            subtitle: '来发表第一条回复吧',
          );
        }
        return Column(
          children: [
            for (final reply in replies)
              _ReplyTile(
                reply: reply,
                currentUserId: currentUserId,
                onReplyTap: onReplyTap,
                onDeleteTap: onDeleteTap,
              ),
          ],
        );
      },
    );
  }
}

class _ReplyTile extends StatelessWidget {
  final PostModel reply;
  final String? currentUserId;
  final ValueChanged<PostModel> onReplyTap;
  final ValueChanged<PostModel> onDeleteTap;

  const _ReplyTile({
    required this.reply,
    required this.currentUserId,
    required this.onReplyTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = reply.author;
    final displayName = author?.effectiveDisplayName ?? '用户';
    final username =
        author?.effectiveUsername ?? 'user_${reply.userId.substring(0, 6)}';
    final hasChildren = reply.replies.isNotEmpty;
    final isOwner = currentUserId == reply.userId;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.appBorder, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                AppAvatar(
                  imageUrl: author?.avatarUrl,
                  fallbackText: displayName,
                  size: AvatarSize.sm,
                ),
                if (hasChildren) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 2,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.appBorder,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: theme.appTextPrimary,
                          letterSpacing: -0.1,
                        ),
                      ),
                      TextSpan(
                        text: ' @$username',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  reply.content,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.48,
                    color: theme.appTextPrimary,
                    letterSpacing: -0.03,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(
                      Formatters.formatDateTime(reply.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.appTextTertiary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _ReplyAction(onTap: () => onReplyTap(reply)),
                    if (isOwner) ...[
                      const SizedBox(width: AppSpacing.lg),
                      _DeleteReplyAction(onTap: () => onDeleteTap(reply)),
                    ],
                  ],
                ),
                if (hasChildren) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ChildReplyGroup(
                    replies: reply.replies,
                    currentUserId: currentUserId,
                    onReplyTap: onReplyTap,
                    onDeleteTap: onDeleteTap,
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

class _ReplyAction extends StatelessWidget {
  final VoidCallback onTap;

  const _ReplyAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.reply_rounded, size: 14, color: theme.appTextSecondary),
          const SizedBox(width: 3),
          Text(
            '回复',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteReplyAction extends StatelessWidget {
  final VoidCallback onTap;

  const _DeleteReplyAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(
        '删除',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: theme.appTextSecondary,
        ),
      ),
    );
  }
}

class _ChildReplyGroup extends StatefulWidget {
  final List<PostModel> replies;
  final String? currentUserId;
  final ValueChanged<PostModel> onReplyTap;
  final ValueChanged<PostModel> onDeleteTap;

  const _ChildReplyGroup({
    required this.replies,
    required this.currentUserId,
    required this.onReplyTap,
    required this.onDeleteTap,
  });

  @override
  State<_ChildReplyGroup> createState() => _ChildReplyGroupState();
}

class _ChildReplyGroupState extends State<_ChildReplyGroup> {
  static const _collapsedCount = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flattenedReplies = _flattenReplies(widget.replies);
    final visibleReplies = _expanded
        ? flattenedReplies
        : flattenedReplies.take(_collapsedCount).toList();
    final hiddenCount = flattenedReplies.length - visibleReplies.length;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final reply in visibleReplies) ...[
            _DouyinChildReply(
              reply: reply,
              currentUserId: widget.currentUserId,
              onReplyTap: widget.onReplyTap,
              onDeleteTap: widget.onDeleteTap,
            ),
          ],
          if (flattenedReplies.length > _collapsedCount)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
                0,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 24, height: 1, color: theme.appBorder),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _expanded ? '收起' : '展开 $hiddenCount 条回复',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.appTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: theme.appTextSecondary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DouyinChildReply extends StatelessWidget {
  final PostModel reply;
  final String? currentUserId;
  final ValueChanged<PostModel> onReplyTap;
  final ValueChanged<PostModel> onDeleteTap;

  const _DouyinChildReply({
    required this.reply,
    required this.currentUserId,
    required this.onReplyTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = reply.author;
    final displayName = author?.effectiveDisplayName ?? '用户';
    final replyToName = reply.replyToAuthorName;
    final isOwner = currentUserId == reply.userId;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        6,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: displayName,
                  style: TextStyle(
                    color: theme.appTextPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (replyToName != null && replyToName.isNotEmpty)
                  TextSpan(
                    text: ' 回复 @$replyToName',
                    style: TextStyle(
                      color: theme.appTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                TextSpan(text: '：${reply.content}'),
              ],
            ),
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: theme.appTextPrimary,
              letterSpacing: -0.02,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Formatters.formatDateTime(reply.createdAt),
                style: TextStyle(fontSize: 11, color: theme.appTextTertiary),
              ),
              const SizedBox(width: AppSpacing.md),
              _ReplyAction(onTap: () => onReplyTap(reply)),
              if (isOwner) ...[
                const SizedBox(width: AppSpacing.md),
                _DeleteReplyAction(onTap: () => onDeleteTap(reply)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

List<PostModel> _flattenReplies(List<PostModel> replies) {
  final result = <PostModel>[];
  for (final reply in replies) {
    result.add(reply);
    result.addAll(_flattenReplies(reply.replies));
  }
  return result;
}

int _countReplies(List<PostModel> replies) {
  var count = 0;
  for (final reply in replies) {
    count++;
    count += _countReplies(reply.replies);
  }
  return count;
}

class _PostDetailContent extends StatelessWidget {
  final PostModel post;
  const _PostDetailContent({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = post.author;
    final displayName = author?.effectiveDisplayName ?? '用户';
    final username =
        author?.effectiveUsername ?? 'user_${post.userId.substring(0, 6)}';
    final mediaUrls = post.mediaUrls.map((m) => m.url).toList();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserHeader(
            displayName: displayName,
            username: username,
            avatarUrl: author?.avatarUrl,
            avatarSize: AvatarSize.lg,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            post.content,
            style: TextStyle(
              fontSize: 18,
              height: 1.5,
              color: theme.appTextPrimary,
              letterSpacing: -0.05,
            ),
          ),
          if (mediaUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            MediaGrid(
              imageUrls: mediaUrls,
              onTap: (index) {
                context.push(
                  RouteNames.imagePreview,
                  extra: ImagePreviewArgs(
                    imageUrls: mediaUrls,
                    initialIndex: index,
                  ),
                );
              },
            ),
          ],
          if (post.repostOf != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _DetailRepostPreview(post: post.repostOf!),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            Formatters.formatDateTime(post.createdAt),
            style: TextStyle(fontSize: 14, color: theme.appTextSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          const AppDivider(),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _Stat(count: post.replyCount, label: '回复'),
              _Stat(count: post.repostCount, label: '转发'),
              _Stat(count: post.likeCount, label: '点赞'),
              _Stat(count: post.bookmarkCount, label: '收藏'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const AppDivider(),
        ],
      ),
    );
  }
}

class _DetailRepostPreview extends StatelessWidget {
  final PostModel post;

  const _DetailRepostPreview({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = post.author;
    final displayName = author?.effectiveDisplayName ?? '用户';
    final username =
        author?.effectiveUsername ?? 'user_${post.userId.substring(0, 6)}';
    final mediaUrls = post.mediaUrls.map((m) => m.url).toList();
    return InkWell(
      onTap: () => context.push('/post/${post.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$displayName @$username',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.appTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (post.content.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                post.content,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: theme.appTextSecondary,
                ),
              ),
            ],
            if (mediaUrls.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              MediaGrid(
                imageUrls: mediaUrls,
                onTap: (index) {
                  context.push(
                    RouteNames.imagePreview,
                    extra: ImagePreviewArgs(
                      imageUrls: mediaUrls,
                      initialIndex: index,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int count;
  final String label;
  const _Stat({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Formatters.formatCount(count),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: theme.appTextPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: theme.appTextSecondary),
        ),
      ],
    );
  }
}
