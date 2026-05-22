import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/social_provider.dart';
import '../../ui/atoms/app_button.dart';

/// 关注/取消关注按钮。读 followStatusProvider，调用 follow/unfollow。
class FollowButton extends ConsumerWidget {
  final String userId;

  const FollowButton({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(followStatusProvider(userId));

    return statusAsync.when(
      loading: () => const AppButton(
        label: '...',
        size: AppButtonSize.compact,
        variant: AppButtonVariant.secondary,
      ),
      error: (_, __) => AppButton(
        label: '关注',
        size: AppButtonSize.compact,
        variant: AppButtonVariant.primary,
        onPressed: () async {
          await ref.read(followProvider.notifier).followUser(userId);
          ref.invalidate(followStatusProvider(userId));
        },
      ),
      data: (isFollowing) {
        if (isFollowing) {
          return AppButton(
            label: '已关注',
            size: AppButtonSize.compact,
            variant: AppButtonVariant.secondary,
            onPressed: () async {
              await ref.read(unfollowProvider.notifier).unfollowUser(userId);
              ref.invalidate(followStatusProvider(userId));
            },
          );
        }
        return AppButton(
          label: '关注',
          size: AppButtonSize.compact,
          variant: AppButtonVariant.primary,
          onPressed: () async {
            await ref.read(followProvider.notifier).followUser(userId);
            ref.invalidate(followStatusProvider(userId));
          },
        );
      },
    );
  }
}
