import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api/post_api.dart';
import '../data/models/post_model.dart';

final postApiProvider = Provider<PostApi>((ref) => PostApi());

// Feed posts provider
final feedPostsProvider = AsyncNotifierProvider<FeedPostsNotifier, List<PostModel>>(
  FeedPostsNotifier.new,
);

class FeedPostsNotifier extends AsyncNotifier<List<PostModel>> {
  String? _nextCursor;
  bool _hasMore = true;

  @override
  Future<List<PostModel>> build() async {
    return _fetchPosts();
  }

  Future<List<PostModel>> _fetchPosts() async {
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
    state = await AsyncValue.guard(_fetchPosts);
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;

    final currentPosts = state.valueOrNull ?? [];
    if (_nextCursor == null) return;

    state = const AsyncLoading();

    final api = ref.read(postApiProvider);
    try {
      final response = await api.getFeed(cursor: _nextCursor);
      _nextCursor = response.nextCursor;
      _hasMore = response.hasMore;
      state = AsyncValue.data([...currentPosts, ...response.posts]);
    } catch (e) {
      state = AsyncValue.data(currentPosts);
    }
  }
}

// Create post provider
final createPostProvider = StateNotifierProvider<CreatePostNotifier, AsyncValue<void>>(
  (ref) => CreatePostNotifier(ref.read(postApiProvider)),
);

class CreatePostNotifier extends StateNotifier<AsyncValue<void>> {
  final PostApi _api;

  CreatePostNotifier(this._api) : super(const AsyncValue.data(null));

  Future<void> createPost(String content) async {
    state = const AsyncValue.loading();
    try {
      await _api.createPost(content);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
