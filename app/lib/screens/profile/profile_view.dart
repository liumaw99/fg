import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/user_model.dart';
import '../../features/post/post_card.dart';
import '../../providers/post_provider.dart';
import '../../ui/atoms/app_avatar.dart';
import '../../ui/atoms/app_haptic.dart';
import '../../ui/molecules/skeletons/post_card_skeleton.dart';
import '../../ui/states/empty_state.dart';
import '../../ui/states/error_state.dart';

/// 通用 Profile 视图（自己 + 别人共用）。
///
/// - Sliver 折叠封面
/// - 4 Tab：Posts / Replies / Media / Likes
/// - [actionButton] 用于注入「编辑资料」（自己）或「关注按钮」（他人）
class ProfileView extends ConsumerStatefulWidget {
  final UserModel user;
  final bool isMe;
  final Widget? actionButton;

  const ProfileView({
    super.key,
    required this.user,
    required this.isMe,
    this.actionButton,
  });

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) AppHaptic.selection();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.user;

    return Scaffold(
      backgroundColor: theme.appBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: theme.appBackground,
            expandedHeight: 150 + 56, // cover + header overlap
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: Colors.black.withAlpha(80),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            title: Text(
              user.displayNameOrUsername,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: theme.appTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: false,
            titleSpacing: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              background: _CoverImage(url: user.coverUrl),
              collapseMode: CollapseMode.parallax,
            ),
          ),
          SliverToBoxAdapter(
            child: _ProfileHeader(
              user: user,
              isMe: widget.isMe,
              actionButton: widget.actionButton,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabsDelegate(
              tabController: _tabController,
              backgroundColor: theme.appBackground,
              borderColor: theme.appBorder,
              indicatorColor: theme.appTextPrimary,
              labelColor: theme.appTextPrimary,
              unselectedLabelColor: theme.appTextSecondary,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _PostsTab(userId: user.id),
            const _ComingSoonTab(message: '回复即将上线'),
            const _ComingSoonTab(message: '媒体即将上线'),
            const _ComingSoonTab(message: '喜欢即将上线'),
          ],
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  final String url;
  const _CoverImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (url.isEmpty) {
      return Container(color: theme.appSurfaceElevated);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Container(color: theme.appSurfaceElevated),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool isMe;
  final Widget? actionButton;

  const _ProfileHeader({
    required this.user,
    required this.isMe,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像 + 操作按钮一行
          SizedBox(
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -40,
                  left: 0,
                  child: AppAvatar(
                    imageUrl: user.avatarUrl,
                    fallbackText: user.displayNameOrUsername,
                    size: AvatarSize.xl,
                    heroTag: 'avatar_user_${user.id}',
                    ringColor: theme.appBackground,
                    ringWidth: 4,
                  ),
                ),
                if (actionButton != null)
                  Positioned(right: 0, top: 8, child: actionButton!),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            user.displayNameOrUsername,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: theme.appTextPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '@${user.username}',
            style: TextStyle(fontSize: 15, color: theme.appTextSecondary),
          ),
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              user.bio,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: theme.appTextPrimary,
              ),
            ),
          ],
          if (user.location.isNotEmpty ||
              user.website.isNotEmpty ||
              user.createdAt != null) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                if (user.location.isNotEmpty)
                  _MetaItem(
                    icon: Icons.location_on_outlined,
                    label: user.location,
                  ),
                if (user.website.isNotEmpty)
                  _MetaItem(
                    icon: Icons.link,
                    label: user.website,
                    highlight: true,
                  ),
                if (user.createdAt != null)
                  _MetaItem(
                    icon: Icons.calendar_today_outlined,
                    label:
                        '加入于 ${user.createdAt!.year}年${user.createdAt!.month}月',
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
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
              _StatItem(count: user.postCount, label: AppStrings.posts),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _MetaItem({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlight ? theme.appTextPrimary : theme.appTextSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.appTextSecondary),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 14, color: color)),
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
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Formatters.formatCount(count),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: theme.appTextPrimary,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: theme.appTextSecondary),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;

  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Formatters.formatCount(count),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: theme.appTextPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: theme.appTextSecondary),
        ),
      ],
    );
  }
}

class _PostsTab extends ConsumerWidget {
  final String userId;
  const _PostsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(userPostsProvider(userId));

    return asyncList.when(
      loading: () => ListView.builder(
        itemCount: 4,
        itemBuilder: (_, __) => const PostCardSkeleton(),
      ),
      error: (e, _) => ErrorState(
        message: e.toString(),
        onRetry: () => ref.read(userPostsProvider(userId).notifier).refresh(),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return const EmptyState(
            icon: Icons.article_outlined,
            title: AppStrings.noPosts,
          );
        }
        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (_, i) => UserPostCard(post: posts[i], userId: userId),
        );
      },
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  final String message;
  const _ComingSoonTab({required this.message});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.hourglass_empty,
      title: message,
      subtitle: '功能开发中',
    );
  }
}

class _StickyTabsDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final Color backgroundColor;
  final Color borderColor;
  final Color indicatorColor;
  final Color labelColor;
  final Color unselectedLabelColor;

  _StickyTabsDelegate({
    required this.tabController,
    required this.backgroundColor,
    required this.borderColor,
    required this.indicatorColor,
    required this.labelColor,
    required this.unselectedLabelColor,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: TabBar(
        controller: tabController,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: indicatorColor, width: 3),
          insets: const EdgeInsets.symmetric(horizontal: 24),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: labelColor,
        unselectedLabelColor: unselectedLabelColor,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith(
          (_) => Colors.transparent,
        ),
        tabs: const [
          Tab(text: '动态'),
          Tab(text: '回复'),
          Tab(text: '媒体'),
          Tab(text: '喜欢'),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant _StickyTabsDelegate old) =>
      old.backgroundColor != backgroundColor ||
      old.indicatorColor != indicatorColor;
}
