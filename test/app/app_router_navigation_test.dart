import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
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

  testWidgets('settings routes stay inside the persistent navigation shell', (
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

    router.go(AppRoutes.bankSettings);
    await tester.pumpAndSettle();

    expect(find.byType(BankSettingsPage), findsOneWidget);
    expect(find.byType(AppBottomNavBar), findsOneWidget);
    expect(
      tester.widget<AppBottomNavBar>(find.byType(AppBottomNavBar)).currentIndex,
      3,
    );
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
