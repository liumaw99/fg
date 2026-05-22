import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/notification/notification_tile.dart';
import '../../providers/notification_provider.dart';
import '../../ui/atoms/app_divider.dart';
import '../../ui/molecules/skeletons/list_skeletons.dart';
import '../../ui/states/empty_state.dart';
import '../../ui/states/error_state.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final n = ref.read(notificationsProvider.notifier);
      if (n.hasMore) n.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncList = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);

    return Column(
      children: [
        if (unread > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.appBorder, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '未读 $unread',
                  style: TextStyle(fontSize: 13, color: theme.appTextSecondary),
                ),
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(markNotificationReadProvider.notifier)
                        .markAllAsRead();
                    ref.invalidate(notificationsProvider);
                  },
                  child: const Text(AppStrings.markAllAsRead),
                ),
              ],
            ),
          ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: asyncList.when(
              loading: () => ListView.builder(
                key: const ValueKey('notif-loading'),
                itemCount: 6,
                itemBuilder: (_, __) => const NotificationTileSkeleton(),
              ),
              error: (error, _) => ErrorState(
                key: const ValueKey('notif-error'),
                message: error.toString(),
                onRetry: () =>
                    ref.read(notificationsProvider.notifier).refresh(),
              ),
              data: (response) {
                if (response.notifications.isEmpty) {
                  return const EmptyState(
                    key: ValueKey('notif-empty'),
                    icon: Icons.notifications_none,
                    title: AppStrings.noNotifications,
                    subtitle: '当有人关注你或与你互动时，会在这里出现',
                  );
                }

                return RefreshIndicator(
                  key: const ValueKey('notif-list'),
                  onRefresh: () =>
                      ref.read(notificationsProvider.notifier).refresh(),
                  color: theme.appTextPrimary,
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: response.notifications.length + 1,
                    separatorBuilder: (_, __) => const AppDivider(indent: 56),
                    itemBuilder: (context, index) {
                      if (index == response.notifications.length) {
                        final n = ref.read(notificationsProvider.notifier);
                        if (n.hasMore) {
                          return const Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox(height: 60);
                      }
                      return NotificationTile(
                        notification: response.notifications[index],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
