import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/api/auth_api.dart';
import '../data/api/user_api.dart';
import '../data/models/user_model.dart';

part 'user_provider.g.dart';

@riverpod
Future<UserModel?> currentUser(CurrentUserRef ref) async {
  final api = AuthApi();
  try {
    final data = await api.getMe();
    return UserModel.fromJson(data);
  } catch (_) {
    return null;
  }
}

@riverpod
Future<UserModel?> profile(ProfileRef ref) async {
  final api = UserApi();
  try {
    final data = await api.getProfile();
    return UserModel.fromJson(data);
  } catch (_) {
    return null;
  }
}

@riverpod
Future<UserModel?> userByUsername(UserByUsernameRef ref, String username) async {
  final api = UserApi();
  try {
    final data = await api.getUserByUsername(username);
    return UserModel.fromJson(data);
  } catch (_) {
    return null;
  }
}

@riverpod
class UpdateProfile extends _$UpdateProfile {
  @override
  FutureOr<void> build() => null;

  Future<void> submit({
    String? displayName,
    String? bio,
    String? location,
    String? website,
  }) async {
    state = const AsyncValue.loading();
    try {
      final api = UserApi();
      await api.updateProfile(
        displayName: displayName,
        bio: bio,
        location: location,
        website: website,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
