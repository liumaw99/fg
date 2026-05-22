import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../ui/states/error_state.dart';
import '../../ui/states/loading_state.dart';
import 'profile_view.dart';

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(body: LoadingState()),
      error: (e, _) => Scaffold(
        body: ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(profileProvider),
        ),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            body: ErrorState(
              message: '无法加载个人资料',
              onRetry: () => ref.invalidate(profileProvider),
            ),
          );
        }
        return ProfileView(
          user: user,
          isMe: true,
          actionButton: _EditButton(),
        );
      },
    );
  }
}

class _EditButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: () => context.push('/edit-profile'),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.appTextPrimary,
        side: BorderSide(color: theme.appBorderStrong, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.1),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('编辑资料'),
    );
  }
}
