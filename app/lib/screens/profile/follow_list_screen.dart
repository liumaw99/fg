import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../data/models/user_model.dart';
import '../../features/user/user_tile.dart';
import '../../providers/social_provider.dart';
import '../../ui/atoms/app_divider.dart';
import '../../ui/molecules/skeletons/user_tile_skeleton.dart';
import '../../ui/states/empty_state.dart';
import '../../ui/states/error_state.dart';

class FollowersScreen extends ConsumerWidget {
  final String userId;

  const FollowersScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(followersProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.followers)),
      body: _FollowList(
        asyncValue: asyncList,
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
    final asyncList = ref.watch(followingProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.following)),
      body: _FollowList(
        asyncValue: asyncList,
        onRetry: () => ref.read(followingProvider(userId).notifier).refresh(),
        emptyTitle: AppStrings.noFollowing,
      ),
    );
  }
}

class _FollowList extends ConsumerWidget {
  final AsyncValue<List<UserModel>> asyncValue;
  final VoidCallback onRetry;
  final String emptyTitle;

  const _FollowList({
    required this.asyncValue,
    required this.onRetry,
    required this.emptyTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncValue.when(
      loading: () => ListView.builder(
        itemCount: 6,
        itemBuilder: (_, __) => const UserTileSkeleton(),
      ),
      error: (error, _) => ErrorState(message: error.toString(), onRetry: onRetry),
      data: (users) {
        if (users.isEmpty) {
          return EmptyState(icon: Icons.people_outline, title: emptyTitle);
        }
        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, __) => const AppDivider(indent: 68),
          itemBuilder: (context, index) => UserTile(user: users[index]),
        );
      },
    );
  }
}
