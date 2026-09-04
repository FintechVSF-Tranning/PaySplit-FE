import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/app/router/main_navigation_shell.dart';
import 'package:paysplit/features/home/presentation/widgets/app_bottom_nav_bar.dart';

void main() {
  testWidgets(
    'switches branches with one persistent navigation bar and keeps tab state',
    (tester) async {
      final router = _buildRouter();
      addTearDown(router.dispose);

      // Shell đọc provider để làm mới dữ liệu của tab khi người dùng bấm tab.
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      final navElement = tester.element(find.byType(AppBottomNavBar));
      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(_currentIndex(tester), 0);

      await tester.tap(find.text('Tăng'));
      await tester.pump();
      expect(find.text('Tổng quan 1'), findsOneWidget);

      await tester.tap(find.text('Nhóm'));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/groups');
      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(
        identical(navElement, tester.element(find.byType(AppBottomNavBar))),
        isTrue,
      );
      expect(_currentIndex(tester), 1);
      expect(
        tester
            .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
            .every(
              (animation) =>
                  animation.duration == appBottomNavigationTransitionDuration,
            ),
        isTrue,
      );

      await tester.tap(find.text('Tổng quan'));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(find.text('Tổng quan 1'), findsOneWidget);
      expect(_currentIndex(tester), 0);
    },
  );

  testWidgets('disables branch motion when reduced motion is requested', (
    tester,
  ) async {
    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
          .every((animation) => animation.duration == Duration.zero),
      isTrue,
    );
  });
}

int _currentIndex(WidgetTester tester) {
  return tester
      .widget<AppBottomNavBar>(find.byType(AppBottomNavBar))
      .currentIndex;
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            MainNavigationShell(navigationShell: navigationShell),
        navigatorContainerBuilder: MainNavigationShell.branchContainerBuilder,
        branches: [
          _branch('/home', 'Tổng quan'),
          _branch('/groups', 'Nhóm'),
          _branch('/bills', 'Hóa đơn'),
          _branch('/profile', 'Cài đặt'),
        ],
      ),
    ],
  );
}

StatefulShellBranch _branch(String path, String label) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        builder: (context, state) => _StatefulBranchPage(label: label),
      ),
    ],
  );
}

class _StatefulBranchPage extends StatefulWidget {
  const _StatefulBranchPage({required this.label});

  final String label;

  @override
  State<_StatefulBranchPage> createState() => _StatefulBranchPageState();
}

class _StatefulBranchPageState extends State<_StatefulBranchPage> {
  var _count = 0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.label} $_count'),
            if (widget.label == 'Tổng quan')
              TextButton(
                onPressed: () => setState(() => _count++),
                child: const Text('Tăng'),
              ),
          ],
        ),
      ),
    );
  }
}
