import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/api/post_api.dart';
import '../data/models/post_model.dart';

part 'post_provider.g.dart';

final postApiProvider = Provider<PostApi>((ref) => PostApi());

@riverpod
class FeedPosts extends _$FeedPosts {
  String? _nextCursor;
  bool _hasMore = true;
  bool _loadingMore = false;

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
    _loadingMore = false;
    state = await AsyncValue.guard(() => build());
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || _nextCursor == null) return;
    _loadingMore = true;

    final currentPosts = state.valueOrNull ?? [];
    final api = ref.read(postApiProvider);
    try {
      final response = await api.getFeed(cursor: _nextCursor);
      _nextCursor = response.nextCursor;
      _hasMore = response.hasMore;
      state = AsyncValue.data([...currentPosts, ...response.posts]);
    } catch (_) {
      // 失败时保留 cursor，允许下次重试
    } finally {
      _loadingMore = false;
    }
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
  bool get isLoadingMore => _loadingMore;
}

@riverpod
class UserPosts extends _$UserPosts {
  String? _nextCursor;
  bool _hasMore = true;
  bool _loadingMore = false;

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
    _loadingMore = false;
    state = await AsyncValue.guard(() => build(userId));
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || _nextCursor == null) return;
    _loadingMore = true;

    final currentPosts = state.valueOrNull ?? [];
    final api = ref.read(postApiProvider);
    try {
      final response = await api.getUserPosts(userId, cursor: _nextCursor);
      _nextCursor = response.nextCursor;
      _hasMore = response.hasMore;
      state = AsyncValue.data([...currentPosts, ...response.posts]);
    } catch (_) {
    } finally {
      _loadingMore = false;
    }
  }

  void updatePost(PostModel updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data([
      for (final p in current) p.id == updated.id ? updated : p,
    ]);
  }

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;
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
