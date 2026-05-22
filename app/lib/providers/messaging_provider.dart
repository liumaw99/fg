import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/api/messaging_api.dart';
import '../data/models/conversation_model.dart';
import '../data/models/message_model.dart';

part 'messaging_provider.g.dart';

final messagingApiProvider = Provider<MessagingApi>((ref) => MessagingApi());

@riverpod
class Conversations extends _$Conversations {
  String? _nextCursor;
  bool _hasMore = true;

  @override
  Future<ConversationListResponse> build() async {
    final api = ref.read(messagingApiProvider);
    final data = await api.getConversations(cursor: _nextCursor);
    final response = ConversationListResponse.fromJson(data);
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
      state = AsyncValue.data(ConversationListResponse(
        conversations: [...current.conversations, ...more.conversations],
        nextCursor: _nextCursor,
        hasMore: _hasMore,
      ));
    } catch (_) {}
  }

  bool get hasMore => _hasMore;
}

@riverpod
class Messages extends _$Messages {
  String? _nextCursor;
  bool _hasMore = true;

  @override
  Future<List<MessageModel>> build(String conversationId) async {
    final api = ref.read(messagingApiProvider);
    final data = await api.getMessages(conversationId, cursor: _nextCursor);
    final response = MessageListResponse.fromJson(data);
    _nextCursor = response.nextCursor;
    _hasMore = response.hasMore;
    return response.messages.reversed.toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    _nextCursor = null;
    _hasMore = true;
    state = await AsyncValue.guard(() => build(conversationId));
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    final current = state.valueOrNull ?? [];
    if (_nextCursor == null) return;

    try {
      final api = ref.read(messagingApiProvider);
      final data = await api.getMessages(conversationId, cursor: _nextCursor);
      final response = MessageListResponse.fromJson(data);
      _nextCursor = response.nextCursor;
      _hasMore = response.hasMore;
      state = AsyncValue.data([...response.messages.reversed, ...current]);
    } catch (_) {}
  }

  bool get hasMore => _hasMore;
}

@riverpod
class SendMessage extends _$SendMessage {
  @override
  FutureOr<void> build() => null;

  Future<void> send({
    required String conversationId,
    required String content,
    required String clientMessageId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(messagingApiProvider);
      await api.sendMessage(
        conversationId: conversationId,
        content: content,
        clientMessageId: clientMessageId,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
