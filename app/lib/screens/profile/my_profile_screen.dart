import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../providers/post_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_divider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/post_card.dart';

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/edit-profile'),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (user) {
          if (user == null) {
            return ErrorState(
              message: '无法加载个人资料',
              onRetry: () => ref.invalidate(profileProvider),
            );
          }

          final postsAsync = ref.watch(userPostsProvider(user.id));

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ProfileHeader(user: user),
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
                loading: () => const SliverFillRemaining(
                  child: LoadingState(),
                ),
                error: (error, _) => SliverFillRemaining(
                  child: ErrorState(message: error.toString()),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(profileProvider),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover
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
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 4,
                    ),
                  ),
                  child: AppAvatar(
                    url: user.avatarUrl,
                    fallbackText: user.displayNameOrUsername,
                    size: AvatarSize.xl,
                  ),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (user.location.isNotEmpty) ...[
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: isDark
                                ? const Color(0xFF71717A)
                                : const Color(0xFFA1A1AA),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.location,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? const Color(0xFF71717A)
                                  : const Color(0xFFA1A1AA),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (user.website.isNotEmpty) ...[
                          Icon(
                            Icons.link,
                            size: 16,
                            color: isDark
                                ? const Color(0xFF71717A)
                                : const Color(0xFFA1A1AA),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.website,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
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
                        const SizedBox(width: 20),
                        _Stat(count: user.postCount, label: AppStrings.posts),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
    return Row(
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
    );
  }
}
