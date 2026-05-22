import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/api/interaction_api.dart';
import '../data/models/notification_model.dart';

part 'notification_provider.g.dart';

final interactionApiProvider = Provider<InteractionApi>(
  (ref) => InteractionApi(),
);

@riverpod
class Notifications extends _$Notifications {
  String? _nextCursor;
  bool _hasMore = true;

  @override
  Future<NotificationListResponse> build() async {
    final api = ref.read(interactionApiProvider);
    final data = await api.getNotifications(cursor: _nextCursor);
    final response = NotificationListResponse.fromJson(data);
    _nextCursor = response.nextCursor;
    _hasMore = response.hasMore;
    return response;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    _nextCursor = null;
    _hasMore = true;
    state = await AsyncValue.guard(() => build());
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    final current = state.valueOrNull;
    if (current == null || _nextCursor == null) return;

    try {
      final more = await build();
      state = AsyncValue.data(
        NotificationListResponse(
          notifications: [...current.notifications, ...more.notifications],
          unreadCount: more.unreadCount,
          nextCursor: _nextCursor,
          hasMore: _hasMore,
        ),
      );
    } catch (_) {}
  }

  bool get hasMore => _hasMore;
}

@riverpod
int unreadCount(UnreadCountRef ref) {
  final asyncValue = ref.watch(notificationsProvider);
  return asyncValue.when(
    data: (d) => d.unreadCount,
    loading: () => 0,
    error: (_, __) => 0,
  );
}

@riverpod
class MarkNotificationRead extends _$MarkNotificationRead {
  @override
  FutureOr<void> build() => null;

  Future<void> markAsRead(String id) async {
    try {
      final api = ref.read(interactionApiProvider);
      await api.markNotificationAsRead(id);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final api = ref.read(interactionApiProvider);
      await api.markAllNotificationsAsRead();
    } catch (_) {}
  }
}
