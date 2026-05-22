import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/notification_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/app_badge.dart';
import 'explore_page.dart';
import 'messages_page.dart';
import 'notifications_page.dart';
import 'timeline_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  final _pages = const [
    TimelinePage(),
    ExplorePage(),
    NotificationsPage(),
    MessagesPage(),
  ];

  String get _title {
    switch (_currentIndex) {
      case 0:
        return AppStrings.timeline;
      case 1:
        return AppStrings.explore;
      case 2:
        return AppStrings.notifications;
      case 3:
        return AppStrings.messages;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RouteNames.settings),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: AppStrings.home,
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: AppStrings.explore,
          ),
          NavigationDestination(
            icon: unreadCount > 0
                ? AppBadge(
                    count: unreadCount,
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_outlined),
            selectedIcon: unreadCount > 0
                ? AppBadge(
                    count: unreadCount,
                    child: const Icon(Icons.notifications),
                  )
                : const Icon(Icons.notifications),
            label: AppStrings.notifications,
          ),
          const NavigationDestination(
            icon: Icon(Icons.mail_outline),
            selectedIcon: Icon(Icons.mail),
            label: AppStrings.messages,
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () => context.push('/create-post'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
