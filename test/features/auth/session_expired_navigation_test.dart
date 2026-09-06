import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paysplit/app/router/app_router.dart';
import 'package:paysplit/app/router/app_routes.dart';
import 'package:paysplit/app/session/session_scope.dart';
import 'package:paysplit/features/auth/domain/entities/user_entity.dart';
import 'package:paysplit/features/auth/presentation/pages/login_page.dart';
import 'package:paysplit/features/auth/presentation/providers/auth_controller.dart';

class _SignedOutController extends AuthController {
  @override
  Future<UserEntity?> build() async => null;
}

void main() {
  testWidgets('expired session redirects to login with a persistent warning', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_SignedOutController.new),
        sessionExpiredProvider.overrideWith((ref) => true),
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
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.login);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.textContaining('thiết bị khác'), findsOneWidget);

    router.go(AppRoutes.profile);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.login);
  });
}
