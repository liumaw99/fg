import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import 'route_names.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_shell.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/create_post_screen.dart';

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

      // Allow splash screen to check auth state
      if (isSplash) return null;

      // Redirect unauthenticated users to login
      if (!isLoggedIn && !isAuthRoute) {
        return RouteNames.login;
      }

      // Redirect authenticated users away from auth pages
      if (isLoggedIn && isAuthRoute) {
        return RouteNames.home;
      }

      print('GoRouter redirect: isLoggedIn=$isLoggedIn, isAuthRoute=$isAuthRoute, isSplash=$isSplash');

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
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
    ],
  );
});
