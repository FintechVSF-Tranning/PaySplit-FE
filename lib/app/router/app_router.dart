import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/verify_otp_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/bills/presentation/pages/bills_page.dart';
import '../../features/groups/domain/entities/group_entity.dart';
import '../../features/groups/presentation/pages/add_members_page.dart';
import '../../features/groups/presentation/pages/group_detail_page.dart';
import '../../features/groups/presentation/pages/groups_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/bank_settings_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'app_routes.dart';

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

      final loc = state.matchedLocation;
      final isAuthFlow = loc == AppRoutes.welcome ||
          loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.verifyOtp ||
          loc == AppRoutes.forgotPassword ||
          loc == AppRoutes.resetPassword;

      if (isLoading) {
        return (loc == AppRoutes.splash || isAuthFlow) ? null : AppRoutes.splash;
      }

      if (!isLoggedIn) {
        if (loc == AppRoutes.splash) return AppRoutes.welcome;
        return isAuthFlow ? null : AppRoutes.welcome;
      }

      if (isLoggedIn && (isAuthFlow || loc == AppRoutes.splash)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          final resetSuccess = state.extra as bool? ?? false;
          return LoginPage(resetSuccess: resetSuccess);
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.verifyOtp,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return VerifyOtpPage(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return ResetPasswordPage(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.bills,
        builder: (context, state) => const BillsPage(),
      ),
      GoRoute(
        path: AppRoutes.groups,
        builder: (context, state) => const GroupsPage(),
        routes: [
          GoRoute(
            path: ':groupId',
            // Nhóm được truyền qua `extra` để tránh fetch lại ngay sau điều hướng.
            builder: (context, state) => GroupDetailPage(group: state.extra! as GroupEntity),
            routes: [
              GoRoute(
                path: 'add-members',
                builder: (context, state) =>
                    AddMembersPage(group: state.extra! as GroupEntity),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.bankSettings,
        builder: (context, state) => const BankSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordPage(),
      ),
    ],
  );
});
