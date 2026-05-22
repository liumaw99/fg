import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/post_model.dart';
import '../../providers/post_provider.dart';
import '../../ui/atoms/app_avatar.dart';
import '../../ui/atoms/app_divider.dart';
import '../../ui/molecules/media_grid.dart';
import '../../ui/molecules/user_header.dart';
import '../../ui/states/empty_state.dart';
import '../../ui/states/error_state.dart';
import '../../ui/states/loading_state.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    _replyController.clear();
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('回复功能即将上线')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postAsync = ref.watch(postDetailProvider(widget.postId));

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
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          '回复 (${post.replyCount})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: theme.appTextPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.chat_bubble_outline,
                        title: '暂无回复',
                        subtitle: '来发表第一条回复吧',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: theme.appBorder, width: 0.5)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        const AppAvatar(fallbackText: 'Me', size: AvatarSize.sm),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            style: TextStyle(color: theme.appTextPrimary, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: '写回复...',
                              hintStyle: TextStyle(color: theme.appTextTertiary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9999),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: theme.appSurfaceElevated,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onSubmitted: (_) => _submitReply(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          onPressed: _submitReply,
                          icon: Icon(Icons.arrow_upward_rounded, color: theme.appTextPrimary),
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

class _PostDetailContent extends StatelessWidget {
  final PostModel post;
  const _PostDetailContent({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = post.author;
    final displayName = author?.effectiveDisplayName ?? '用户';
    final username = author?.effectiveUsername ?? 'user_${post.userId.substring(0, 6)}';

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
            style: TextStyle(fontSize: 18, height: 1.5, color: theme.appTextPrimary, letterSpacing: -0.05),
          ),
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            MediaGrid(imageUrls: post.mediaUrls.map((m) => m.url).toList()),
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
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: theme.appTextPrimary),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 14, color: theme.appTextSecondary)),
      ],
    );
  }
}
