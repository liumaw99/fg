// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messaging_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$conversationsHash() => r'99bd43c484a42cf317c6e40055e8780e6f01f4ff';

/// See also [Conversations].
@ProviderFor(Conversations)
final conversationsProvider =
    AutoDisposeAsyncNotifierProvider<
      Conversations,
      ConversationListResponse
    >.internal(
      Conversations.new,
      name: r'conversationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$conversationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Conversations = AutoDisposeAsyncNotifier<ConversationListResponse>;
String _$messagesHash() => r'a0ef92cc13e8dea4979d26e252ec1dd5507606e5';

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

abstract class _$Messages
    extends BuildlessAutoDisposeAsyncNotifier<List<MessageModel>> {
  late final String conversationId;

  FutureOr<List<MessageModel>> build(String conversationId);
}

/// See also [Messages].
@ProviderFor(Messages)
const messagesProvider = MessagesFamily();

/// See also [Messages].
class MessagesFamily extends Family<AsyncValue<List<MessageModel>>> {
  /// See also [Messages].
  const MessagesFamily();

  /// See also [Messages].
  MessagesProvider call(String conversationId) {
    return MessagesProvider(conversationId);
  }

  @override
  MessagesProvider getProviderOverride(covariant MessagesProvider provider) {
    return call(provider.conversationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'messagesProvider';
}

/// See also [Messages].
class MessagesProvider
    extends AutoDisposeAsyncNotifierProviderImpl<Messages, List<MessageModel>> {
  /// See also [Messages].
  MessagesProvider(String conversationId)
    : this._internal(
        () => Messages()..conversationId = conversationId,
        from: messagesProvider,
        name: r'messagesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$messagesHash,
        dependencies: MessagesFamily._dependencies,
        allTransitiveDependencies: MessagesFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  MessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  FutureOr<List<MessageModel>> runNotifierBuild(covariant Messages notifier) {
    return notifier.build(conversationId);
  }

  @override
  Override overrideWith(Messages Function() create) {
    return ProviderOverride(
      origin: this,
      override: MessagesProvider._internal(
        () => create()..conversationId = conversationId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<Messages, List<MessageModel>>
  createElement() {
    return _MessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MessagesProvider && other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MessagesRef on AutoDisposeAsyncNotifierProviderRef<List<MessageModel>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _MessagesProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<Messages, List<MessageModel>>
    with MessagesRef {
  _MessagesProviderElement(super.provider);

  @override
  String get conversationId => (origin as MessagesProvider).conversationId;
}

String _$sendMessageHash() => r'8dd2bc13d93d7e46c4f5c836efc65d7596fbc36f';

/// See also [SendMessage].
@ProviderFor(SendMessage)
final sendMessageProvider =
    AutoDisposeAsyncNotifierProvider<SendMessage, void>.internal(
      SendMessage.new,
      name: r'sendMessageProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sendMessageHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SendMessage = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
