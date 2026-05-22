import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/user_model.dart';
import '../../providers/post_provider.dart';
import '../../providers/social_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_divider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/post_card.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userByUsernameProvider(widget.username));

    return Scaffold(
      appBar: AppBar(),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return ErrorState(
              message: '用户不存在',
              onRetry: () => ref.invalidate(userByUsernameProvider(widget.username)),
            );
          }
          return _ProfileBody(user: user);
        },
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(userByUsernameProvider(widget.username)),
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  final UserModel user;

  const _ProfileBody({required this.user});

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final followStatus = ref.watch(followStatusProvider(user.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final postsAsync = ref.watch(userPostsProvider(user.id));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
                child: user.coverUrl.isNotEmpty
                    ? Image.network(
                        user.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      )
                    : const Center(
                        child: Icon(Icons.image, size: 40, color: Color(0xFF71717A)),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -36),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                width: 4,
                              ),
                            ),
                            child: AppAvatar(
                              url: user.avatarUrl,
                              fallbackText: user.displayNameOrUsername,
                              size: AvatarSize.xl,
                            ),
                          ),
                          followStatus.when(
                            data: (isFollowing) => AppButton(
                              label: isFollowing ? AppStrings.followed : AppStrings.follow,
                              onPressed: () => _toggleFollow(isFollowing),
                              variant: isFollowing
                                  ? AppButtonVariant.secondary
                                  : AppButtonVariant.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                            ),
                            loading: () => const SizedBox(
                              width: 80,
                              height: 32,
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayNameOrUsername,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${user.username}',
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark
                                  ? const Color(0xFF71717A)
                                  : const Color(0xFFA1A1AA),
                            ),
                          ),
                          if (user.bio.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              user.bio,
                              style: const TextStyle(fontSize: 15, height: 1.5),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _StatLink(
                                count: user.followingCount,
                                label: AppStrings.following,
                                onTap: () => context.push('/following/${user.id}'),
                              ),
                              const SizedBox(width: 20),
                              _StatLink(
                                count: user.followerCount,
                                label: AppStrings.followers,
                                onTap: () => context.push('/followers/${user.id}'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: AppDivider()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppStrings.posts,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        postsAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
              return const SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.article_outlined,
                  title: AppStrings.noPosts,
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => PostCard(
                  post: posts[index],
                  onTap: () => context.push('/post/${posts[index].id}'),
                ),
                childCount: posts.length,
              ),
            );
          },
          loading: () => const SliverFillRemaining(child: LoadingState()),
          error: (error, _) => SliverFillRemaining(
            child: ErrorState(message: error.toString()),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFollow(bool currentlyFollowing) async {
    if (currentlyFollowing) {
      await ref.read(unfollowProvider.notifier).unfollowUser(widget.user.id);
    } else {
      await ref.read(followProvider.notifier).followUser(widget.user.id);
    }
    ref.invalidate(followStatusProvider(widget.user.id));
  }
}

class _StatLink extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback onTap;

  const _StatLink({
    required this.count,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Formatters.formatCount(count),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
      ),
    );
  }
}
