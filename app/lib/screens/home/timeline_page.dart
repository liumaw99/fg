import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_duration.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/post/post_card.dart';
import '../../providers/post_provider.dart';
import '../../ui/atoms/app_haptic.dart';
import '../../ui/molecules/skeletons/post_card_skeleton.dart';
import '../../ui/states/empty_state.dart';
import '../../ui/states/error_state.dart';

class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => TimelinePageState();
}

class TimelinePageState extends ConsumerState<TimelinePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _forYouScrollCtrl = ScrollController();
  final _followingScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) AppHaptic.selection();
    });
    _forYouScrollCtrl.addListener(_onForYouScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _forYouScrollCtrl.dispose();
    _followingScrollCtrl.dispose();
    super.dispose();
  }

  void _onForYouScroll() {
    if (_forYouScrollCtrl.position.pixels >=
        _forYouScrollCtrl.position.maxScrollExtent - 300) {
      final n = ref.read(feedPostsProvider.notifier);
      if (n.hasMore) n.loadMore();
    }
  }

  /// 外部可调用：滚动到顶部
  void scrollToTop() {
    final ctrl = _tabController.index == 0 ? _forYouScrollCtrl : _followingScrollCtrl;
    if (ctrl.hasClients) {
      ctrl.animateTo(0, duration: AppDuration.slow, curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
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
            _ForYouTab(scrollController: _forYouScrollCtrl),
            _FollowingTab(scrollController: _followingScrollCtrl),
          ],
        ),
      ),
    );
  }
}

class _ForYouTab extends ConsumerWidget {
  final ScrollController scrollController;
  const _ForYouTab({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(feedPostsProvider);

    return CustomScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () => ref.read(feedPostsProvider.notifier).refresh(),
        ),
        postsAsync.when(
          loading: () => SliverList.builder(
            itemCount: 5,
            itemBuilder: (_, __) => const PostCardSkeleton(),
          ),
          error: (e, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              message: e.toString(),
              onRetry: () => ref.read(feedPostsProvider.notifier).refresh(),
            ),
          ),
          data: (posts) {
            if (posts.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.timeline,
                  title: '还没有任何动态',
                  subtitle: '关注一些用户或来发表第一条动态',
                ),
              );
            }
            return SliverList.builder(
              itemCount: posts.length + 1,
              itemBuilder: (context, index) {
                if (index == posts.length) {
                  final n = ref.read(feedPostsProvider.notifier);
                  if (n.hasMore) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  return const SizedBox(height: 80);
                }
                return FeedPostCard(post: posts[index]);
              },
            );
          },
        ),
      ],
    );
  }
}

class _FollowingTab extends StatelessWidget {
  final ScrollController scrollController;
  const _FollowingTab({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    // 后端未提供专门的 following timeline 接口，暂占位
    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: const [
        SizedBox(height: 80),
        EmptyState(
          icon: Icons.people_outline,
          title: '关注页即将上线',
          subtitle: '关注好友后会在这里看到他们的动态',
        ),
      ],
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: TabBar(
        controller: tabController,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: indicatorColor, width: 3),
          insets: const EdgeInsets.symmetric(horizontal: 48),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: labelColor,
        unselectedLabelColor: unselectedLabelColor,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.1),
        unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith((_) => Colors.transparent),
        tabs: const [
          Tab(text: '为你'),
          Tab(text: '关注'),
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
      old.borderColor != borderColor ||
      old.indicatorColor != indicatorColor;
}
