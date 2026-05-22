// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$unreadCountHash() => r'0defaf9c7228f92e723fbc1ac703dd30d0940922';

/// See also [unreadCount].
@ProviderFor(unreadCount)
final unreadCountProvider = AutoDisposeProvider<int>.internal(
  unreadCount,
  name: r'unreadCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnreadCountRef = AutoDisposeProviderRef<int>;
String _$notificationsHash() => r'd444aa0dbce6826a9d11dd1e1923cc783e04ead4';

/// See also [Notifications].
@ProviderFor(Notifications)
final notificationsProvider =
    AutoDisposeAsyncNotifierProvider<
      Notifications,
      NotificationListResponse
    >.internal(
      Notifications.new,
      name: r'notificationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Notifications = AutoDisposeAsyncNotifier<NotificationListResponse>;
String _$markNotificationReadHash() =>
    r'1755e014143fd5f3c3d55c7fc3fffba76a8c9266';

/// See also [MarkNotificationRead].
@ProviderFor(MarkNotificationRead)
final markNotificationReadProvider =
    AutoDisposeAsyncNotifierProvider<MarkNotificationRead, void>.internal(
      MarkNotificationRead.new,
      name: r'markNotificationReadProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$markNotificationReadHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MarkNotificationRead = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
