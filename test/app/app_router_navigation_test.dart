import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paysplit/app/router/app_router.dart';
import 'package:paysplit/app/router/app_routes.dart';
import 'package:paysplit/di/injection.dart';
import 'package:paysplit/features/auth/domain/entities/user_entity.dart';
import 'package:paysplit/features/auth/presentation/providers/auth_controller.dart';
import 'package:paysplit/features/groups/domain/repositories/group_repository.dart';
import 'package:paysplit/features/groups/domain/usecases/list_groups_usecase.dart';
import 'package:paysplit/features/groups/presentation/pages/groups_page.dart';
import 'package:paysplit/features/home/presentation/pages/home_page.dart';
import 'package:paysplit/features/home/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:paysplit/features/profile/presentation/pages/bank_settings_page.dart';
import 'package:paysplit/features/profile/presentation/pages/profile_page.dart';
import 'package:paysplit/features/settlement/data/mock/mock_settlement_repository.dart';
import 'package:paysplit/features/settlement/presentation/providers/settlement_controller.dart';
import 'package:paysplit/features/settlement/presentation/widgets/all_bills_tab.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  setUpAll(() {
    final groupRepository = _MockGroupRepository();
    when(
      () => groupRepository.listGroups(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => Right(const GroupPage(items: [])));
    getIt.registerSingleton(ListGroupsUseCase(groupRepository));
  });

  testWidgets('app router switches main branches without replacing the shell', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_SignedInAuthController.new),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    final navElement = tester.element(find.byType(AppBottomNavBar));

    await tester.tap(find.text('Nhóm').last);
    await tester.pumpAndSettle();

    expect(find.byType(GroupsPage), findsOneWidget);
    expect(find.byType(AppBottomNavBar), findsOneWidget);
    expect(
      identical(navElement, tester.element(find.byType(AppBottomNavBar))),
      isTrue,
    );
  });

  testWidgets('settings routes are registered outside the navigation shell', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_SignedInAuthController.new),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    router.go(AppRoutes.profile);
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.byType(AppBottomNavBar), findsOneWidget);
    expect(
      tester.widget<AppBottomNavBar>(find.byType(AppBottomNavBar)).currentIndex,
      3,
    );

    router.push(AppRoutes.bankSettings);
    await tester.pumpAndSettle();

    expect(find.byType(BankSettingsPage), findsOneWidget);
    expect(find.byType(AppBottomNavBar), findsNothing);
  });

  testWidgets(
    'navigating from Home to the Nhóm tab keeps the bottom bar on Nhóm',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_SignedInAuthController.new),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);

      // Mô phỏng luồng "Tạo nhóm" từ Trang chủ: điều hướng sang tab Nhóm
      // (context.go) — bottom bar phải highlight đúng tab Nhóm.
      router.go(AppRoutes.groups);
      await tester.pumpAndSettle();

      expect(find.byType(GroupsPage), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(
        tester
            .widget<AppBottomNavBar>(find.byType(AppBottomNavBar))
            .currentIndex,
        1,
      );
    },
  );

  test('group child screens are registered outside the navigation shell', () {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_SignedInAuthController.new),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);
    final shell = router.configuration.routes
        .whereType<StatefulShellRoute>()
        .single;

    // Branch "Nhóm" chỉ còn đúng 1 route gốc, không lồng màn hình con.
    final groupsBranch = shell.branches[1].routes.single as GoRoute;
    expect(groupsBranch.path, AppRoutes.groups);

    // Chi tiết nhóm & thêm thành viên là route full-screen ngoài shell,
    // nên bottom navigation bar không hiển thị trên các màn hình này.
    final detailRoute = router.configuration.routes
        .whereType<GoRoute>()
        .firstWhere((route) => route.path == '${AppRoutes.groups}/:groupId');
    expect((detailRoute.routes.single as GoRoute).path, 'add-members');
  });

  test('group QR scanner is registered outside the navigation shell', () {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_SignedInAuthController.new),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);

    final rootPaths = router.configuration.routes.whereType<GoRoute>().map(
      (route) => route.path,
    );
    expect(rootPaths, contains(AppRoutes.scanGroupQr));
  });

  testWidgets('Hóa đơn bottom nav opens the bills tab', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_SignedInAuthController.new),
        settlementRepositoryProvider.overrideWithValue(
          MockSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hóa đơn').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(AllBillsTab), findsOneWidget);
    expect(
      tester.widget<AppBottomNavBar>(find.byType(AppBottomNavBar)).currentIndex,
      2,
    );
  });
}

class _SignedInAuthController extends AuthController {
  @override
  FutureOr<UserEntity?> build() {
    return const UserEntity(
      id: 'test-user',
      name: 'Test User',
      email: 'test@paysplit.app',
    );
  }
}
