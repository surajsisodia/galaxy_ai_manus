import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_state_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/splash_screen.dart';
import 'route_names.dart';

class RouterRefreshListenable extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

final routerRefreshListenableProvider = Provider<RouterRefreshListenable>((
  ref,
) {
  final listenable = RouterRefreshListenable();

  ref.listen(appStateProvider, (_, _) => listenable.refresh());
  ref.listen(authProvider, (_, _) => listenable.refresh());
  ref.onDispose(listenable.dispose);

  return listenable;
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(routerRefreshListenableProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.chat,
        builder: (context, state) {
          final chatId = state.pathParameters['chatId'] ?? '';
          return ChatScreen(chatId: chatId);
        },
      ),
    ],
    redirect: (context, state) {
      final appState = ref.read(appStateProvider);
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;
      final isAtSplash = location == RouteNames.splash;
      final isAtAuth = location == RouteNames.auth;
      final isAtHome = location == RouteNames.home;
      final isAtProfile = location == RouteNames.profile;
      final isAtChat = location.startsWith(RouteNames.chatBase);

      if (!appState.isInitialized) {
        return isAtSplash ? null : RouteNames.splash;
      }

      if (!authState.isLoggedIn) {
        return isAtAuth ? null : RouteNames.auth;
      }

      if (isAtSplash || isAtAuth) {
        return RouteNames.home;
      }

      if (isAtHome || isAtProfile || isAtChat) return null;

      return RouteNames.home;
    },
  );
});
