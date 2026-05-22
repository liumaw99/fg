import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_duration.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/chat/chat_detail_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/post/create_post_screen.dart';
import '../screens/post/image_preview_screen.dart';
import '../screens/post/post_detail_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/follow_list_screen.dart';
import '../screens/profile/my_profile_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import 'route_names.dart';

/// iOS 风格右滑入场 + 淡入
CustomTransitionPage<T> _slidePage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDuration.page,
    reverseTransitionDuration: AppDuration.slow,
    transitionsBuilder: (context, animation, secondary, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: AppDuration.standard));
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return SlideTransition(position: slide, child: FadeTransition(opacity: fade, child: child));
    },
  );
}

/// 模态：从下方滑入
CustomTransitionPage<T> _modalPage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDuration.page,
    reverseTransitionDuration: AppDuration.slow,
    transitionsBuilder: (context, animation, secondary, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: AppDuration.emphasized));
      return SlideTransition(position: slide, child: child);
    },
  );
}

/// 淡入淡出（用于初始 splash/home 切换）
CustomTransitionPage<T> _fadePage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDuration.normal,
    transitionsBuilder: (context, animation, secondary, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: authState,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == RouteNames.login || loc == RouteNames.register;
      final isSplash = loc == RouteNames.splash;

      if (isSplash) return null;
      if (!isLoggedIn && !isAuthRoute) return RouteNames.login;
      if (isLoggedIn && isAuthRoute) return RouteNames.home;
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        pageBuilder: (context, state) => _fadePage(state, const SplashScreen()),
      ),
      GoRoute(
        path: RouteNames.login,
        pageBuilder: (context, state) => _fadePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: RouteNames.register,
        pageBuilder: (context, state) => _slidePage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: RouteNames.home,
        pageBuilder: (context, state) => _fadePage(state, const HomeShell()),
      ),
      GoRoute(
        path: RouteNames.profile,
        pageBuilder: (context, state) => _slidePage(state, const MyProfileScreen()),
      ),
      GoRoute(
        path: RouteNames.settings,
        pageBuilder: (context, state) => _slidePage(state, const SettingsScreen()),
      ),
      GoRoute(
        path: RouteNames.createPost,
        pageBuilder: (context, state) => _modalPage(state, const CreatePostScreen()),
      ),
      GoRoute(
        path: RouteNames.imagePreview,
        pageBuilder: (context, state) {
          final args = state.extra as ImagePreviewArgs?;
          return _fadePage(
            state,
            ImagePreviewScreen(
              imageUrls: args?.imageUrls ?? const [],
              initialIndex: args?.initialIndex ?? 0,
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.postDetail,
        pageBuilder: (context, state) {
          final postId = state.pathParameters['id']!;
          return _slidePage(state, PostDetailScreen(postId: postId));
        },
      ),
      GoRoute(
        path: RouteNames.userProfile,
        pageBuilder: (context, state) {
          final username = state.pathParameters['username']!;
          return _slidePage(state, UserProfileScreen(username: username));
        },
      ),
      GoRoute(
        path: RouteNames.editProfile,
        pageBuilder: (context, state) => _modalPage(state, const EditProfileScreen()),
      ),
      GoRoute(
        path: RouteNames.followers,
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return _slidePage(state, FollowersScreen(userId: userId));
        },
      ),
      GoRoute(
        path: RouteNames.following,
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return _slidePage(state, FollowingScreen(userId: userId));
        },
      ),
      GoRoute(
        path: RouteNames.chatDetail,
        pageBuilder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          final participantId = state.extra as String?;
          return _slidePage(
            state,
            ChatDetailScreen(
              conversationId: conversationId,
              participantId: participantId,
            ),
          );
        },
      ),
    ],
  );
});
