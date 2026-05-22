import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/user/follow_button.dart';
import '../../providers/user_provider.dart';
import '../../ui/states/error_state.dart';
import '../../ui/states/loading_state.dart';
import 'profile_view.dart';

class UserProfileScreen extends ConsumerWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByUsernameProvider(username));

    return userAsync.when(
      loading: () => const Scaffold(body: LoadingState()),
      error: (e, _) => Scaffold(
        body: ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(userByUsernameProvider(username)),
        ),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            body: ErrorState(
              message: '用户不存在',
              onRetry: () => ref.invalidate(userByUsernameProvider(username)),
            ),
          );
        }
        return ProfileView(
          user: user,
          isMe: false,
          actionButton: FollowButton(userId: user.id),
        );
      },
    );
  }
}
