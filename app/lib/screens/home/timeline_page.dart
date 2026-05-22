import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/post_provider.dart';
import '../../widgets/app_divider.dart';
import '../../widgets/app_skeleton.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/post_card.dart';

class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(feedPostsProvider.notifier);
      if (notifier.hasMore) {
        notifier.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(feedPostsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(feedPostsProvider.notifier).refresh(),
      child: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return EmptyState(
              icon: Icons.timeline,
              title: AppStrings.noPostsYet,
              subtitle: AppStrings.beTheFirst,
            );
          }

          return ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: posts.length + 1,
            separatorBuilder: (_, __) => const AppDivider(),
            itemBuilder: (context, index) {
              if (index == posts.length) {
                final notifier = ref.read(feedPostsProvider.notifier);
                if (notifier.hasMore) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              final post = posts[index];
              return PostCard(
                post: post,
                onTap: () => context.push('/post/${post.id}'),
                onLike: () {},
                onReply: () => context.push('/post/${post.id}'),
              );
            },
          );
        },
        loading: () => ListView.builder(
          itemCount: 5,
          itemBuilder: (_, __) => const PostCardSkeleton(),
        ),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(feedPostsProvider.notifier).refresh(),
        ),
      ),
    );
  }
}
