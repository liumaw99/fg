// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$followStatusHash() => r'66e138dcad5db24a0aa677132b3c97a6c26383fc';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [followStatus].
@ProviderFor(followStatus)
const followStatusProvider = FollowStatusFamily();

/// See also [followStatus].
class FollowStatusFamily extends Family<AsyncValue<bool>> {
  /// See also [followStatus].
  const FollowStatusFamily();

  /// See also [followStatus].
  FollowStatusProvider call(String userId) {
    return FollowStatusProvider(userId);
  }

  @override
  FollowStatusProvider getProviderOverride(
    covariant FollowStatusProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'followStatusProvider';
}

/// See also [followStatus].
class FollowStatusProvider extends AutoDisposeFutureProvider<bool> {
  /// See also [followStatus].
  FollowStatusProvider(String userId)
    : this._internal(
        (ref) => followStatus(ref as FollowStatusRef, userId),
        from: followStatusProvider,
        name: r'followStatusProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$followStatusHash,
        dependencies: FollowStatusFamily._dependencies,
        allTransitiveDependencies:
            FollowStatusFamily._allTransitiveDependencies,
        userId: userId,
      );

  FollowStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(FollowStatusRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FollowStatusProvider._internal(
        (ref) => create(ref as FollowStatusRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _FollowStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowStatusProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FollowStatusRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _FollowStatusProviderElement
    extends AutoDisposeFutureProviderElement<bool>
    with FollowStatusRef {
  _FollowStatusProviderElement(super.provider);

  @override
  String get userId => (origin as FollowStatusProvider).userId;
}

String _$followHash() => r'537c93303c7b3fd47ccb401d8461f8c0906b1a93';

/// See also [Follow].
@ProviderFor(Follow)
final followProvider = AutoDisposeAsyncNotifierProvider<Follow, void>.internal(
  Follow.new,
  name: r'followProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$followHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Follow = AutoDisposeAsyncNotifier<void>;
String _$unfollowHash() => r'1c3c0812fc087af883869c1f6ed8d1775db37604';

/// See also [Unfollow].
@ProviderFor(Unfollow)
final unfollowProvider =
    AutoDisposeAsyncNotifierProvider<Unfollow, void>.internal(
      Unfollow.new,
      name: r'unfollowProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$unfollowHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Unfollow = AutoDisposeAsyncNotifier<void>;
String _$followersHash() => r'13e4f204093c6823e53979e8a48bdf31b6fc3af1';

abstract class _$Followers
    extends BuildlessAutoDisposeAsyncNotifier<List<UserModel>> {
  late final String userId;

  FutureOr<List<UserModel>> build(String userId);
}

/// See also [Followers].
@ProviderFor(Followers)
const followersProvider = FollowersFamily();

/// See also [Followers].
class FollowersFamily extends Family<AsyncValue<List<UserModel>>> {
  /// See also [Followers].
  const FollowersFamily();

  /// See also [Followers].
  FollowersProvider call(String userId) {
    return FollowersProvider(userId);
  }

  @override
  FollowersProvider getProviderOverride(covariant FollowersProvider provider) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'followersProvider';
}

/// See also [Followers].
class FollowersProvider
    extends AutoDisposeAsyncNotifierProviderImpl<Followers, List<UserModel>> {
  /// See also [Followers].
  FollowersProvider(String userId)
    : this._internal(
        () => Followers()..userId = userId,
        from: followersProvider,
        name: r'followersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$followersHash,
        dependencies: FollowersFamily._dependencies,
        allTransitiveDependencies: FollowersFamily._allTransitiveDependencies,
        userId: userId,
      );

  FollowersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  FutureOr<List<UserModel>> runNotifierBuild(covariant Followers notifier) {
    return notifier.build(userId);
  }

  @override
  Override overrideWith(Followers Function() create) {
    return ProviderOverride(
      origin: this,
      override: FollowersProvider._internal(
        () => create()..userId = userId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<Followers, List<UserModel>>
  createElement() {
    return _FollowersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowersProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FollowersRef on AutoDisposeAsyncNotifierProviderRef<List<UserModel>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _FollowersProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<Followers, List<UserModel>>
    with FollowersRef {
  _FollowersProviderElement(super.provider);

  @override
  String get userId => (origin as FollowersProvider).userId;
}

String _$followingHash() => r'd379098e0472361a352bd4481f965fb4d745d13c';

abstract class _$Following
    extends BuildlessAutoDisposeAsyncNotifier<List<UserModel>> {
  late final String userId;

  FutureOr<List<UserModel>> build(String userId);
}

/// See also [Following].
@ProviderFor(Following)
const followingProvider = FollowingFamily();

/// See also [Following].
class FollowingFamily extends Family<AsyncValue<List<UserModel>>> {
  /// See also [Following].
  const FollowingFamily();

  /// See also [Following].
  FollowingProvider call(String userId) {
    return FollowingProvider(userId);
  }

  @override
  FollowingProvider getProviderOverride(covariant FollowingProvider provider) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'followingProvider';
}

/// See also [Following].
class FollowingProvider
    extends AutoDisposeAsyncNotifierProviderImpl<Following, List<UserModel>> {
  /// See also [Following].
  FollowingProvider(String userId)
    : this._internal(
        () => Following()..userId = userId,
        from: followingProvider,
        name: r'followingProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$followingHash,
        dependencies: FollowingFamily._dependencies,
        allTransitiveDependencies: FollowingFamily._allTransitiveDependencies,
        userId: userId,
      );

  FollowingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  FutureOr<List<UserModel>> runNotifierBuild(covariant Following notifier) {
    return notifier.build(userId);
  }

  @override
  Override overrideWith(Following Function() create) {
    return ProviderOverride(
      origin: this,
      override: FollowingProvider._internal(
        () => create()..userId = userId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<Following, List<UserModel>>
  createElement() {
    return _FollowingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowingProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FollowingRef on AutoDisposeAsyncNotifierProviderRef<List<UserModel>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _FollowingProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<Following, List<UserModel>>
    with FollowingRef {
  _FollowingProviderElement(super.provider);

  @override
  String get userId => (origin as FollowingProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
