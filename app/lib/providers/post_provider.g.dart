// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$postDetailHash() => r'3c8aee23d21c420b36ca972c9d0c68f7913886b2';

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

/// See also [postDetail].
@ProviderFor(postDetail)
const postDetailProvider = PostDetailFamily();

/// See also [postDetail].
class PostDetailFamily extends Family<AsyncValue<PostModel?>> {
  /// See also [postDetail].
  const PostDetailFamily();

  /// See also [postDetail].
  PostDetailProvider call(String postId) {
    return PostDetailProvider(postId);
  }

  @override
  PostDetailProvider getProviderOverride(
    covariant PostDetailProvider provider,
  ) {
    return call(provider.postId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'postDetailProvider';
}

/// See also [postDetail].
class PostDetailProvider extends AutoDisposeFutureProvider<PostModel?> {
  /// See also [postDetail].
  PostDetailProvider(String postId)
    : this._internal(
        (ref) => postDetail(ref as PostDetailRef, postId),
        from: postDetailProvider,
        name: r'postDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$postDetailHash,
        dependencies: PostDetailFamily._dependencies,
        allTransitiveDependencies: PostDetailFamily._allTransitiveDependencies,
        postId: postId,
      );

  PostDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  Override overrideWith(
    FutureOr<PostModel?> Function(PostDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostDetailProvider._internal(
        (ref) => create(ref as PostDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PostModel?> createElement() {
    return _PostDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostDetailProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PostDetailRef on AutoDisposeFutureProviderRef<PostModel?> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _PostDetailProviderElement
    extends AutoDisposeFutureProviderElement<PostModel?>
    with PostDetailRef {
  _PostDetailProviderElement(super.provider);

  @override
  String get postId => (origin as PostDetailProvider).postId;
}

String _$postRepliesHash() => r'da93c05aff999fd59ef1576a8c7097515aedad21';

/// See also [postReplies].
@ProviderFor(postReplies)
const postRepliesProvider = PostRepliesFamily();

/// See also [postReplies].
class PostRepliesFamily extends Family<AsyncValue<List<PostModel>>> {
  /// See also [postReplies].
  const PostRepliesFamily();

  /// See also [postReplies].
  PostRepliesProvider call(String postId) {
    return PostRepliesProvider(postId);
  }

  @override
  PostRepliesProvider getProviderOverride(
    covariant PostRepliesProvider provider,
  ) {
    return call(provider.postId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'postRepliesProvider';
}

/// See also [postReplies].
class PostRepliesProvider extends AutoDisposeFutureProvider<List<PostModel>> {
  /// See also [postReplies].
  PostRepliesProvider(String postId)
    : this._internal(
        (ref) => postReplies(ref as PostRepliesRef, postId),
        from: postRepliesProvider,
        name: r'postRepliesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$postRepliesHash,
        dependencies: PostRepliesFamily._dependencies,
        allTransitiveDependencies: PostRepliesFamily._allTransitiveDependencies,
        postId: postId,
      );

  PostRepliesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  Override overrideWith(
    FutureOr<List<PostModel>> Function(PostRepliesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostRepliesProvider._internal(
        (ref) => create(ref as PostRepliesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PostModel>> createElement() {
    return _PostRepliesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostRepliesProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PostRepliesRef on AutoDisposeFutureProviderRef<List<PostModel>> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _PostRepliesProviderElement
    extends AutoDisposeFutureProviderElement<List<PostModel>>
    with PostRepliesRef {
  _PostRepliesProviderElement(super.provider);

  @override
  String get postId => (origin as PostRepliesProvider).postId;
}

String _$feedPostsHash() => r'd76bd1ede11577fb962831765fabec9169808ac5';

/// See also [FeedPosts].
@ProviderFor(FeedPosts)
final feedPostsProvider =
    AutoDisposeAsyncNotifierProvider<FeedPosts, List<PostModel>>.internal(
      FeedPosts.new,
      name: r'feedPostsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$feedPostsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FeedPosts = AutoDisposeAsyncNotifier<List<PostModel>>;
String _$userPostsHash() => r'038c52c6bd4e2750118dff9a80e90e6b05a2779c';

abstract class _$UserPosts
    extends BuildlessAutoDisposeAsyncNotifier<List<PostModel>> {
  late final String userId;

  FutureOr<List<PostModel>> build(String userId);
}

/// See also [UserPosts].
@ProviderFor(UserPosts)
const userPostsProvider = UserPostsFamily();

/// See also [UserPosts].
class UserPostsFamily extends Family<AsyncValue<List<PostModel>>> {
  /// See also [UserPosts].
  const UserPostsFamily();

  /// See also [UserPosts].
  UserPostsProvider call(String userId) {
    return UserPostsProvider(userId);
  }

  @override
  UserPostsProvider getProviderOverride(covariant UserPostsProvider provider) {
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
  String? get name => r'userPostsProvider';
}

/// See also [UserPosts].
class UserPostsProvider
    extends AutoDisposeAsyncNotifierProviderImpl<UserPosts, List<PostModel>> {
  /// See also [UserPosts].
  UserPostsProvider(String userId)
    : this._internal(
        () => UserPosts()..userId = userId,
        from: userPostsProvider,
        name: r'userPostsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userPostsHash,
        dependencies: UserPostsFamily._dependencies,
        allTransitiveDependencies: UserPostsFamily._allTransitiveDependencies,
        userId: userId,
      );

  UserPostsProvider._internal(
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
  FutureOr<List<PostModel>> runNotifierBuild(covariant UserPosts notifier) {
    return notifier.build(userId);
  }

  @override
  Override overrideWith(UserPosts Function() create) {
    return ProviderOverride(
      origin: this,
      override: UserPostsProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<UserPosts, List<PostModel>>
  createElement() {
    return _UserPostsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserPostsProvider && other.userId == userId;
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
mixin UserPostsRef on AutoDisposeAsyncNotifierProviderRef<List<PostModel>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserPostsProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<UserPosts, List<PostModel>>
    with UserPostsRef {
  _UserPostsProviderElement(super.provider);

  @override
  String get userId => (origin as UserPostsProvider).userId;
}

String _$createReplyHash() => r'31303986fd475d66932aa406610343efd02e1fba';

/// See also [CreateReply].
@ProviderFor(CreateReply)
final createReplyProvider =
    AutoDisposeAsyncNotifierProvider<CreateReply, void>.internal(
      CreateReply.new,
      name: r'createReplyProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$createReplyHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CreateReply = AutoDisposeAsyncNotifier<void>;
String _$createPostHash() => r'66d89f1b84e55e27ac0e4fd4e32edfe089d368e8';

/// See also [CreatePost].
@ProviderFor(CreatePost)
final createPostProvider =
    AutoDisposeAsyncNotifierProvider<CreatePost, void>.internal(
      CreatePost.new,
      name: r'createPostProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$createPostHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CreatePost = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
