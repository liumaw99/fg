import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/api/social_api.dart';
import '../data/models/user_model.dart';

part 'social_provider.g.dart';

final socialApiProvider = Provider<SocialApi>((ref) => SocialApi());

@riverpod
Future<bool> followStatus(FollowStatusRef ref, String userId) async {
  final api = ref.read(socialApiProvider);
  try {
    return await api.isFollowing(userId);
  } catch (_) {
    return false;
  }
}

@riverpod
class Follow extends _$Follow {
  @override
  FutureOr<void> build() => null;

  Future<void> followUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(socialApiProvider);
      await api.follow(userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

@riverpod
class Unfollow extends _$Unfollow {
  @override
  FutureOr<void> build() => null;

  Future<void> unfollowUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(socialApiProvider);
      await api.unfollow(userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

@riverpod
class Followers extends _$Followers {
  String? _nextCursor;
  bool _hasMore = true;

  @override
  Future<List<UserModel>> build(String userId) async {
    final api = ref.read(socialApiProvider);
    final data = await api.listFollowers(userId);
    final response = UserListResponse.fromJson(data);
    _nextCursor = response.nextCursor;
    _hasMore = response.hasMore;
    return response.users;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    _nextCursor = null;
    _hasMore = true;
    state = await AsyncValue.guard(() => build(userId));
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    final current = state.valueOrNull ?? [];
    if (_nextCursor == null) return;

    try {
      final api = ref.read(socialApiProvider);
      final data = await api.listFollowers(userId, cursor: _nextCursor);
      final response = UserListResponse.fromJson(data);
      _nextCursor = response.nextCursor;
      _hasMore = response.hasMore;
      state = AsyncValue.data([...current, ...response.users]);
    } catch (_) {}
  }

  bool get hasMore => _hasMore;
}

@riverpod
class Following extends _$Following {
  String? _nextCursor;
  bool _hasMore = true;

  @override
  Future<List<UserModel>> build(String userId) async {
    final api = ref.read(socialApiProvider);
    final data = await api.listFollowing(userId);
    final response = UserListResponse.fromJson(data);
    _nextCursor = response.nextCursor;
    _hasMore = response.hasMore;
    return response.users;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    _nextCursor = null;
    _hasMore = true;
    state = await AsyncValue.guard(() => build(userId));
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    final current = state.valueOrNull ?? [];
    if (_nextCursor == null) return;

    try {
      final api = ref.read(socialApiProvider);
      final data = await api.listFollowing(userId, cursor: _nextCursor);
      final response = UserListResponse.fromJson(data);
      _nextCursor = response.nextCursor;
      _hasMore = response.hasMore;
      state = AsyncValue.data([...current, ...response.users]);
    } catch (_) {}
  }

  bool get hasMore => _hasMore;
}
