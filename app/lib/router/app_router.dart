import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/chat/chat_detail_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/post/create_post_screen.dart';
import '../screens/post/post_detail_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/follow_list_screen.dart';
import '../screens/profile/my_profile_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: authState,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == RouteNames.login ||
          state.matchedLocation == RouteNames.register;
      final isSplash = state.matchedLocation == RouteNames.splash;

      if (isSplash) return null;

      if (!isLoggedIn && !isAuthRoute) {
        return RouteNames.login;
      }

      if (isLoggedIn && isAuthRoute) {
        return RouteNames.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (context, state) => const MyProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.createPost,
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: RouteNames.postDetail,
        builder: (context, state) {
          final postId = state.pathParameters['id']!;
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: RouteNames.userProfile,
        builder: (context, state) {
          final username = state.pathParameters['username']!;
          return UserProfileScreen(username: username);
        },
      ),
      GoRoute(
        path: RouteNames.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.followers,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return FollowersScreen(userId: userId);
        },
      ),
      GoRoute(
        path: RouteNames.following,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return FollowingScreen(userId: userId);
        },
      ),
      GoRoute(
        path: RouteNames.chatDetail,
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          final participantId = state.extra as String?;
          return ChatDetailScreen(
            conversationId: conversationId,
            participantId: participantId,
          );
        },
      ),
    ],
  );
});
