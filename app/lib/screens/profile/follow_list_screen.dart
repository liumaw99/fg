import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/social_provider.dart';
import '../../widgets/app_divider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/user_list_tile.dart';

class FollowersScreen extends ConsumerWidget {
  final String userId;

  const FollowersScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followersAsync = ref.watch(followersProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.followers),
      ),
      body: _FollowList(
        asyncValue: followersAsync,
        onRetry: () => ref.read(followersProvider(userId).notifier).refresh(),
        emptyTitle: AppStrings.noFollowers,
      ),
    );
  }
}

class FollowingScreen extends ConsumerWidget {
  final String userId;

  const FollowingScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingAsync = ref.watch(followingProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.following),
      ),
      body: _FollowList(
        asyncValue: followingAsync,
        onRetry: () => ref.read(followingProvider(userId).notifier).refresh(),
        emptyTitle: AppStrings.noFollowing,
      ),
    );
  }
}

class _FollowList extends ConsumerWidget {
  final dynamic asyncValue;
  final VoidCallback onRetry;
  final String emptyTitle;

  const _FollowList({
    required this.asyncValue,
    required this.onRetry,
    required this.emptyTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This is a simplified version - the actual notifier pattern
    // would need proper family provider setup
    return asyncValue.when(
      data: (users) {
        if (users.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline,
            title: emptyTitle,
          );
        }
        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, __) => const AppDivider(indent: 72),
          itemBuilder: (context, index) {
            final user = users[index];
            return UserListTile(
              user: user,
              onTap: () => context.push('/user/${user.username}'),
            );
          },
        );
      },
      loading: () => const LoadingState(),
      error: (error, _) => ErrorState(
        message: error.toString(),
        onRetry: onRetry,
      ),
    );
  }
}
