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
import '../../features/bills/domain/entities/bill_detail_entity.dart';
import '../../features/bills/presentation/pages/bill_capture_page.dart';
import '../../features/bills/presentation/pages/bill_detail_page.dart';
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
        path: AppRoutes.scanBill,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BillCapturePage(
            groupId: extra?['groupId'] as String? ?? '01a02363-242d-7cee-ae30-8f61857fd62c',
            groupName: extra?['groupName'] as String? ?? 'Phòng Dev Cty',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.billDetail,
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
              autoStartOcr: extra['autoStartOcr'] as bool? ?? (bill.photos.isNotEmpty && bill.items.isEmpty),
            );
          }
          final initialBill = BillDetailEntity(
            id: extra?['billId'] as String? ?? '',
            groupId: extra?['groupId'] as String? ?? '01a02363-242d-7cee-ae30-8f61857fd62c',
            groupName: extra?['groupName'] as String? ?? 'Phòng Dev Cty',
            creditorMemberId: extra?['creditorMemberId'] as String? ?? '01a02363-242f-72df-b61e-05e551f3360b',
            creditorName: extra?['creditorName'] as String? ?? 'Nguyen Trong Tin',
            status: 'draft',
            merchantName: extra?['merchantName'] as String? ?? 'Lẩu gà lá é Tao Ngộ',
            subtotal: 750000,
            serviceCharge: 50000,
            vat: 60000,
            totalItemDiscount: 50000,
            generalDiscount: 50000,
            total: 760000,
            items: [
              const BillItemEntity(
                id: 'item-1',
                name: 'Lẩu gà lá é lớn',
                unitPrice: 350000,
                lineTotal: 350000,
                discountAmount: 50000,
                finalPrice: 300000,
                assignments: [
                  BillItemAssignmentEntity(
                    memberId: '01a02363-242f-72df-b61e-05e551f3360b',
                    displayName: 'Tin',
                    weight: 0.33,
                  ),
                  BillItemAssignmentEntity(
                    memberId: '01a03a02-0001-7000-8000-000000000001',
                    displayName: 'Nam',
                    weight: 0.33,
                  ),
                  BillItemAssignmentEntity(
                    memberId: '01a03a02-0002-7000-8000-000000000002',
                    displayName: 'Linh',
                    weight: 0.34,
                  ),
                ],
              ),
              const BillItemEntity(
                id: 'item-2',
                name: 'Bò nhúng dấm đặc biệt',
                unitPrice: 400000,
                lineTotal: 400000,
                finalPrice: 400000,
                assignments: [
                  BillItemAssignmentEntity(
                    memberId: '01a02363-242f-72df-b61e-05e551f3360b',
                    displayName: 'Tin',
                    weight: 0.5,
                  ),
                  BillItemAssignmentEntity(
                    memberId: '01a03a02-0003-7000-8000-000000000003',
                    displayName: 'Tuấn',
                    weight: 0.5,
                  ),
                ],
              ),
            ],
            members: const [
              BillMemberEntity(
                memberId: '01a02363-242f-72df-b61e-05e551f3360b',
                userId: '01a01ce0-c270-75ad-ae24-a054943629cc',
                displayName: 'Nguyen Trong Tin',
                role: 'captain',
              ),
              BillMemberEntity(
                memberId: '01a03a02-0001-7000-8000-000000000001',
                userId: '01a03a01-0001-7000-8000-000000000001',
                displayName: 'Lê Nam',
              ),
              BillMemberEntity(
                memberId: '01a03a02-0002-7000-8000-000000000002',
                userId: '01a03a01-0002-7000-8000-000000000002',
                displayName: 'Hoàng Linh',
              ),
              BillMemberEntity(
                memberId: '01a03a02-0003-7000-8000-000000000003',
                userId: '01a03a01-0003-7000-8000-000000000003',
                displayName: 'Minh Tuấn',
              ),
              BillMemberEntity(
                memberId: '01a03a02-0004-7000-8000-000000000004',
                userId: '01a03a01-0004-7000-8000-000000000004',
                displayName: 'Thu Hà',
              ),
            ],
          );
          return BillDetailPage(initialBill: initialBill);
        },
      ),
      GoRoute(
        path: AppRoutes.groups,
        builder: (context, state) => const GroupsPage(),
        routes: [
          GoRoute(
            path: ':groupId',
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
