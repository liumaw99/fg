import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/api/post_api.dart';
import '../data/models/post_model.dart';

part 'post_provider.g.dart';

final postApiProvider = Provider<PostApi>((ref) => PostApi());

@riverpod
class FeedPosts extends _$FeedPosts {
  String? _nextCursor;
  bool _hasMore = true;

  @override
  Future<List<PostModel>> build() async {
    final api = ref.read(postApiProvider);
    final response = await api.getFeed();
    _nextCursor = response.nextCursor;
    _hasMore = response.hasMore;
    return response.posts;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    _nextCursor = null;
    _hasMore = true;
    state = await AsyncValue.guard(() => build());
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    final currentPosts = state.valueOrNull ?? [];
    if (_nextCursor == null) return;

    final api = ref.read(postApiProvider);
    try {
      final response = await api.getFeed(cursor: _nextCursor);
      _nextCursor = response.nextCursor;
      _hasMore = response.hasMore;
      state = AsyncValue.data([...currentPosts, ...response.posts]);
    } catch (_) {}
  }

  /// 局部替换某条 post（点赞等乐观更新使用，不重建整列）
  void updatePost(PostModel updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data([
      for (final p in current) p.id == updated.id ? updated : p,
    ]);
  }

  bool get hasMore => _hasMore;
}

@riverpod
class UserPosts extends _$UserPosts {
  String? _nextCursor;
  bool _hasMore = true;

  @override
  Future<List<PostModel>> build(String userId) async {
    final api = ref.read(postApiProvider);
    final response = await api.getUserPosts(userId);
    _nextCursor = response.nextCursor;
    _hasMore = response.hasMore;
    return response.posts;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    _nextCursor = null;
    _hasMore = true;
    state = await AsyncValue.guard(() => build(userId));
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    final currentPosts = state.valueOrNull ?? [];
    if (_nextCursor == null) return;

    final api = ref.read(postApiProvider);
    try {
      final response = await api.getUserPosts(userId, cursor: _nextCursor);
      _nextCursor = response.nextCursor;
      _hasMore = response.hasMore;
      state = AsyncValue.data([...currentPosts, ...response.posts]);
    } catch (_) {}
  }

  void updatePost(PostModel updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data([
      for (final p in current) p.id == updated.id ? updated : p,
    ]);
  }

  bool get hasMore => _hasMore;
}

@riverpod
Future<PostModel?> postDetail(PostDetailRef ref, String postId) async {
  final api = ref.read(postApiProvider);
  try {
    return await api.getPost(postId);
  } catch (_) {
    return null;
  }
}

@riverpod
class CreatePost extends _$CreatePost {
  @override
  FutureOr<void> build() => null;

  Future<void> createPost(String content) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(postApiProvider);
      await api.createPost(content);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
