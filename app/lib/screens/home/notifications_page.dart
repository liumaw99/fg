import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_divider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/notification_tile.dart';

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
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(notificationsProvider.notifier);
      if (notifier.hasMore) {
        notifier.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Column(
      children: [
        if (unreadCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                await ref
                    .read(markNotificationReadProvider.notifier)
                    .markAllAsRead();
                ref.invalidate(notificationsProvider);
              },
              child: const Text(AppStrings.markAllAsRead),
            ),
          ),
        Expanded(
          child: notificationsAsync.when(
            data: (response) {
              if (response.notifications.isEmpty) {
                return EmptyState(
                  icon: Icons.notifications_none,
                  title: AppStrings.noNotifications,
                );
              }

              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(notificationsProvider.notifier).refresh(),
                child: ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  itemCount: response.notifications.length + 1,
                  separatorBuilder: (_, __) => const AppDivider(),
                  itemBuilder: (context, index) {
                    if (index == response.notifications.length) {
                      final notifier =
                          ref.read(notificationsProvider.notifier);
                      if (notifier.hasMore) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }

                    final n = response.notifications[index];
                    return NotificationTile(
                      notification: n,
                      onTap: () {
                        if (!n.isRead) {
                          ref
                              .read(markNotificationReadProvider.notifier)
                              .markAsRead(n.id);
                        }
                        if (n.postId != null) {
                          context.push('/post/${n.postId}');
                        }
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const LoadingState(),
            error: (error, _) => ErrorState(
              message: error.toString(),
              onRetry: () =>
                  ref.read(notificationsProvider.notifier).refresh(),
            ),
          ),
        ),
      ],
    );
  }
}
