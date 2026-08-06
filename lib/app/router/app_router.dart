import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/bills/presentation/pages/bills_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'app_routes.dart';

/// Bridges Riverpod's [authControllerProvider] to go_router's
/// [GoRouter.refreshListenable]. This lets the router re-evaluate
/// [GoRouter.redirect] whenever auth state changes without recreating the
/// [GoRouter] instance itself (which would otherwise reset the navigation
/// stack on every login/logout).
class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

final _goRouterRefreshNotifierProvider = Provider<_GoRouterRefreshNotifier>((ref) {
  return _GoRouterRefreshNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(_goRouterRefreshNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.valueOrNull != null;

      final goingToSplash = state.matchedLocation == AppRoutes.splash;
      final goingToLogin = state.matchedLocation == AppRoutes.login;

      // Only bounce to splash for loading states that start there (initial
      // session restore). A login/register submission starts on the Login
      // page and must stay there so its failure listener can observe the
      // AsyncLoading -> AsyncError transition.
      if (isLoading) return (goingToSplash || goingToLogin) ? null : AppRoutes.splash;
      if (!isLoggedIn) return goingToLogin ? null : AppRoutes.login;
      if (goingToLogin || goingToSplash) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashPage()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginPage()),
      GoRoute(path: AppRoutes.home, builder: (context, state) => const HomePage()),
      GoRoute(path: AppRoutes.bills, builder: (context, state) => const BillsPage()),
    ],
  );
});
