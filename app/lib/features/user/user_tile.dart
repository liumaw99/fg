import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/user_model.dart';
import '../../ui/molecules/user_tile_view.dart';
import 'follow_button.dart';

/// 用户行业务包装：跳转主页 + 注入 FollowButton。
class UserTile extends ConsumerWidget {
  final UserModel user;
  final bool showFollowButton;

  const UserTile({super.key, required this.user, this.showFollowButton = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UserTileView(
      displayName: user.displayName.isEmpty ? user.username : user.displayName,
      username: user.username,
      avatarUrl: user.avatarUrl,
      bio: user.bio,
      trailing: showFollowButton ? FollowButton(userId: user.id) : null,
      onTap: () => context.push('/user/${user.username}'),
    );
  }
}
