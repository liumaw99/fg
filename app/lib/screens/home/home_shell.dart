import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_duration.dart';
import '../../providers/notification_provider.dart';
import '../../providers/user_provider.dart';
import '../../router/route_names.dart';
import '../../ui/atoms/app_avatar.dart';
import '../../ui/atoms/app_badge.dart';
import '../../ui/atoms/app_haptic.dart';
import 'explore_page.dart';
import 'messages_page.dart';
import 'notifications_page.dart';
import 'timeline_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  // 子页面通过 key 暴露 scrollToTop 方法
  final _timelineKey = GlobalKey<TimelinePageState>();

  late final List<Widget> _pages = [
    TimelinePage(key: _timelineKey),
    const ExplorePage(),
    const NotificationsPage(),
    const MessagesPage(),
  ];

  void _onTabSelected(int index) {
    if (index == _currentIndex) {
      // 二次点击当前 tab -> 滚动到顶部
      if (index == 0) {
        _timelineKey.currentState?.scrollToTop();
      }
      AppHaptic.selection();
      return;
    }
    setState(() => _currentIndex = index);
    AppHaptic.light();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = ref.watch(unreadCountProvider);
    final me = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: theme.appBackground,
      appBar: AppBar(
        toolbarHeight: 52,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppAvatar(
              imageUrl: me?.avatarUrl,
              fallbackText: me?.displayNameOrUsername,
              size: AvatarSize.sm,
              onTap: () => context.push(RouteNames.profile),
            ),
          ),
        ),
        title: Icon(Icons.bolt_rounded, size: 28, color: theme.appTextPrimary),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: theme.appTextPrimary, size: 22),
            onPressed: () => context.push(RouteNames.settings),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedSwitcher(
        duration: AppDuration.fast,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: _BottomBar(
        currentIndex: _currentIndex,
        unreadCount: unreadCount,
        onTap: _onTabSelected,
      ),
      floatingActionButton: _ComposeButton(
        onTap: () => context.push(RouteNames.createPost),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final int unreadCount;
  final ValueChanged<int> onTap;

  const _BottomBar({
    required this.currentIndex,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      _TabItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: '首页',
      ),
      _TabItem(
        icon: Icons.search,
        activeIcon: Icons.search,
        label: '探索',
      ),
      _TabItem(
        icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications_rounded,
        label: '通知',
        badge: unreadCount,
      ),
      _TabItem(
        icon: Icons.mail_outline,
        activeIcon: Icons.mail_rounded,
        label: '消息',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.appBackground,
        border: Border(top: BorderSide(color: theme.appBorder, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Center(
                    child: AppBadge(
                      count: item.badge ?? 0,
                      child: AnimatedScale(
                        scale: selected ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          selected ? item.activeIcon : item.icon,
                          size: 26,
                          color: selected ? theme.appTextPrimary : theme.appTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badge;

  _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge,
  });
}

class _ComposeButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ComposeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FloatingActionButton(
      onPressed: () {
        AppHaptic.light();
        onTap();
      },
      backgroundColor: theme.appAccent,
      foregroundColor: theme.appAccentText,
      elevation: 2,
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }
}
