// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentUserHash() => r'48fbd075ebb792750873c2c2a96bfc9574d670a9';

/// See also [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = AutoDisposeFutureProvider<UserModel?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = AutoDisposeFutureProviderRef<UserModel?>;
String _$profileHash() => r'e62317fd7a5ee20f4b0b62a8caf6cecf08ac0037';

/// See also [profile].
@ProviderFor(profile)
final profileProvider = AutoDisposeFutureProvider<UserModel?>.internal(
  profile,
  name: r'profileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileRef = AutoDisposeFutureProviderRef<UserModel?>;
String _$userByUsernameHash() => r'8c15cd7477b8aa1f5e87dad0fc81a171e1323ee8';

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

/// See also [userByUsername].
@ProviderFor(userByUsername)
const userByUsernameProvider = UserByUsernameFamily();

/// See also [userByUsername].
class UserByUsernameFamily extends Family<AsyncValue<UserModel?>> {
  /// See also [userByUsername].
  const UserByUsernameFamily();

  /// See also [userByUsername].
  UserByUsernameProvider call(String username) {
    return UserByUsernameProvider(username);
  }

  @override
  UserByUsernameProvider getProviderOverride(
    covariant UserByUsernameProvider provider,
  ) {
    return call(provider.username);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userByUsernameProvider';
}

/// See also [userByUsername].
class UserByUsernameProvider extends AutoDisposeFutureProvider<UserModel?> {
  /// See also [userByUsername].
  UserByUsernameProvider(String username)
    : this._internal(
        (ref) => userByUsername(ref as UserByUsernameRef, username),
        from: userByUsernameProvider,
        name: r'userByUsernameProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userByUsernameHash,
        dependencies: UserByUsernameFamily._dependencies,
        allTransitiveDependencies:
            UserByUsernameFamily._allTransitiveDependencies,
        username: username,
      );

  UserByUsernameProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.username,
  }) : super.internal();

  final String username;

  @override
  Override overrideWith(
    FutureOr<UserModel?> Function(UserByUsernameRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserByUsernameProvider._internal(
        (ref) => create(ref as UserByUsernameRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        username: username,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<UserModel?> createElement() {
    return _UserByUsernameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserByUsernameProvider && other.username == username;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, username.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserByUsernameRef on AutoDisposeFutureProviderRef<UserModel?> {
  /// The parameter `username` of this provider.
  String get username;
}

class _UserByUsernameProviderElement
    extends AutoDisposeFutureProviderElement<UserModel?>
    with UserByUsernameRef {
  _UserByUsernameProviderElement(super.provider);

  @override
  String get username => (origin as UserByUsernameProvider).username;
}

String _$updateProfileHash() => r'b4a24da6e1e869938bf1b473d6f64ac85c5f1520';

/// See also [UpdateProfile].
@ProviderFor(UpdateProfile)
final updateProfileProvider =
    AutoDisposeAsyncNotifierProvider<UpdateProfile, void>.internal(
      UpdateProfile.new,
      name: r'updateProfileProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$updateProfileHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UpdateProfile = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
