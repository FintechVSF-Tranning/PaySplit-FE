import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/verify_otp_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/bills/domain/entities/bill_detail_entity.dart';
import '../../features/bills/presentation/pages/bill_capture_page.dart';
import '../../features/bills/presentation/pages/bill_detail_page.dart';
import '../../features/groups/domain/entities/group_entity.dart';
import '../../features/groups/presentation/pages/add_members_page.dart';
import '../../features/groups/presentation/pages/group_detail_page.dart';
import '../../features/groups/presentation/pages/groups_page.dart';
import '../../features/groups/presentation/pages/scan_qr_join_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/avatar_capture_page.dart';
import '../../features/profile/presentation/pages/avatar_crop_page.dart';
import '../../features/profile/presentation/pages/bank_settings_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/settlement/presentation/pages/settlement_page.dart';
import '../../features/settlement/presentation/providers/settlement_controller.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'app_routes.dart';
import 'group_detail_route_args.dart';
import 'main_navigation_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

final _goRouterRefreshNotifierProvider = Provider<_GoRouterRefreshNotifier>((
  ref,
) {
  return _GoRouterRefreshNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(_goRouterRefreshNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isAuth = authState.valueOrNull != null;
      final isGoingToSplash = state.matchedLocation == AppRoutes.splash;
      final isGoingToAuth =
          state.matchedLocation == AppRoutes.welcome ||
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.verifyOtp ||
          state.matchedLocation == AppRoutes.forgotPassword ||
          state.matchedLocation == AppRoutes.resetPassword;

      if (authState.isLoading) {
        return null;
      }

      if (!isAuth) {
        if (isGoingToSplash) {
          return AppRoutes.welcome;
        }
        if (isGoingToAuth) {
          return null;
        }
        return AppRoutes.welcome;
      }

      if (isGoingToSplash || isGoingToAuth) {
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
        builder: (context, state) =>
            LoginPage(resetSuccess: state.extra is bool && state.extra == true),
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
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            MainNavigationShell(navigationShell: navigationShell),
        navigatorContainerBuilder: MainNavigationShell.branchContainerBuilder,
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.groups,
                builder: (context, state) => const GroupsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.bills,
                builder: (context, state) {
                  final tab =
                      state.extra as SettlementTab? ?? SettlementTab.bills;
                  return SettlementPage(initialTab: tab);
                },
              ),
              GoRoute(
                path: AppRoutes.settlement,
                builder: (context, state) {
                  final tab =
                      state.extra as SettlementTab? ?? SettlementTab.payable;
                  return SettlementPage(initialTab: tab);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
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
          ),
        ],
      ),
      // Các màn hình con dạng Stack của tab Nhóm: đặt ngoài shell để hiển thị
      // full-screen (ẩn bottom navigation bar) và không làm lệch tab active.
      GoRoute(
        path: '${AppRoutes.groups}/:groupId',
        builder: (context, state) {
          final extra = state.extra;
          final groupId = state.pathParameters['groupId'] ?? '';

          GroupEntity fallbackGroup() => GroupEntity(
            id: groupId,
            name: 'Chi tiết nhóm',
            memberCount: 1,
            myBalance: 0,
            inviteCode: '',
            isCaptain: false,
            lastActivity: 'Đang tải thông tin...',
          );

          if (extra is GroupDetailRouteArgs) {
            return GroupDetailPage(
              group: extra.group ?? fallbackGroup(),
              openBatchId: extra.openBatchId,
              initialTab: extra.initialTab,
            );
          }
          if (extra is GroupEntity) {
            return GroupDetailPage(group: extra);
          }
          return GroupDetailPage(group: fallbackGroup());
        },
        routes: [
          GoRoute(
            path: 'add-members',
            builder: (context, state) =>
                AddMembersPage(group: state.extra! as GroupEntity),
          ),
        ],
      ),
      // Các luồng full-screen (ngoài bottom navigation shell)
      GoRoute(
        path: AppRoutes.scanGroupQr,
        builder: (context, state) => const ScanQrJoinPage(),
      ),
      GoRoute(
        path: AppRoutes.scanBill,
        redirect: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final groupId = extra?['groupId'] as String?;
          if (groupId == null || groupId.isEmpty) {
            return AppRoutes.bills;
          }
          return null;
        },
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BillCapturePage(
            groupId: extra['groupId'] as String,
            groupName: extra['groupName'] as String? ?? 'Chi tiết nhóm',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.avatarCapture,
        builder: (context, state) => const AvatarCapturePage(),
      ),
      GoRoute(
        path: AppRoutes.avatarCrop,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AvatarCropPage(
            imageBytes: extra?['imageBytes'] as Uint8List? ?? Uint8List(0),
            isFromCamera: extra?['isFromCamera'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.billDetail,
        redirect: (context, state) {
          final extra = state.extra;
          if (extra == null) {
            return AppRoutes.bills;
          }
          if (extra is! BillDetailEntity && extra is! Map<String, dynamic>) {
            return AppRoutes.bills;
          }
          if (extra is Map<String, dynamic>) {
            final bill = extra['bill'];
            final billId = extra['billId'] as String?;
            final groupId = extra['groupId'] as String?;
            if (bill == null &&
                (billId == null || billId.isEmpty) &&
                (groupId == null || groupId.isEmpty)) {
              return AppRoutes.bills;
            }
          }
          return null;
        },
        builder: (context, state) {
          if (state.extra is BillDetailEntity) {
            final bill = state.extra! as BillDetailEntity;
            return BillDetailPage(
              initialBill: bill,
              autoStartOcr: bill.photos.isNotEmpty && bill.items.isEmpty,
            );
          }
          final extra = state.extra as Map<String, dynamic>?;
          if (extra?['bill'] is BillDetailEntity) {
            final bill = extra!['bill'] as BillDetailEntity;
            return BillDetailPage(
              initialBill: bill,
              autoStartOcr:
                  extra['autoStartOcr'] as bool? ??
                  (bill.photos.isNotEmpty && bill.items.isEmpty),
            );
          }
          final billId = extra?['billId'] as String? ?? '';
          final groupId = extra?['groupId'] as String? ?? '';

          final initialBill = BillDetailEntity(
            id: billId,
            groupId: groupId,
            groupName: extra?['groupName'] as String? ?? 'Chi tiết nhóm',
            creditorMemberId: extra?['creditorMemberId'] as String? ?? '',
            creditorName: extra?['creditorName'] as String? ?? '',
            status: 'draft',
            merchantName:
                extra?['merchantName'] as String? ?? 'Đang tải thông tin...',
            subtotal: 0,
            serviceCharge: 0,
            vat: 0,
            totalItemDiscount: 0,
            generalDiscount: 0,
            total: 0,
          );
          return BillDetailPage(initialBill: initialBill);
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
  );
});
