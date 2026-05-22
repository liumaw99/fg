import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/post_model.dart';
import '../../providers/post_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_divider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

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

    // TODO: Implement reply API when backend supports it
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('回复功能即将上线')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('动态'),
      ),
      body: postAsync.when(
        data: (post) {
          if (post == null) {
            return EmptyState(
              icon: Icons.article_outlined,
              title: AppStrings.notFound,
            );
          }

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _PostDetailContent(post: post),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '回复 (${post.replyCount})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    // TODO: Reply list when backend supports it
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
              const Divider(height: 0.5, thickness: 0.5),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const AppAvatar(
                        fallbackText: 'Me',
                        size: AvatarSize.sm,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          decoration: InputDecoration(
                            hintText: '写回复...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9999),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) => _submitReply(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _submitReply,
                        icon: const Icon(Icons.send),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(postDetailProvider(widget.postId)),
        ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppAvatar(
                fallbackText: 'U',
                size: AvatarSize.lg,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userId.substring(0, 8),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '@${post.userId.substring(0, 8)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFF71717A)
                            : const Color(0xFFA1A1AA),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post.content,
            style: const TextStyle(fontSize: 17, height: 1.6),
          ),
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildMediaGrid(),
          ],
          const SizedBox(height: 16),
          Text(
            Formatters.formatDateTime(post.createdAt),
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? const Color(0xFF71717A)
                  : const Color(0xFFA1A1AA),
            ),
          ),
          const SizedBox(height: 12),
          const AppDivider(),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(count: post.replyCount, label: '回复'),
              const SizedBox(width: 24),
              _Stat(count: post.repostCount, label: '转发'),
              const SizedBox(width: 24),
              _Stat(count: post.likeCount, label: '点赞'),
              const SizedBox(width: 24),
              _Stat(count: post.bookmarkCount, label: '收藏'),
            ],
          ),
          const SizedBox(height: 12),
          const AppDivider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.repeat, size: 20),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(
                  post.isLiked ? Icons.favorite : Icons.favorite_outline,
                  size: 20,
                  color: post.isLiked ? Colors.red : null,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_outline, size: 20),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 20),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          const AppDivider(),
        ],
      ),
    );
  }

  Widget _buildMediaGrid() {
    final media = post.mediaUrls;
    if (media.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.grey.shade800,
            child: const Center(
              child: Icon(Icons.image, size: 40, color: Colors.grey),
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
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            color: Colors.grey.shade800,
            child: const Center(
              child: Icon(Icons.image, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final int count;
  final String label;

  const _Stat({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Formatters.formatCount(count),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF71717A)
                : const Color(0xFFA1A1AA),
          ),
        ),
      ],
    );
  }
}
