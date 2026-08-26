import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/widgets/app_bottom_nav_bar.dart';

class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static Widget branchContainerBuilder(
    BuildContext context,
    StatefulNavigationShell navigationShell,
    List<Widget> children,
  ) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = disableAnimations
        ? Duration.zero
        : appBottomNavigationTransitionDuration;

    return Stack(
      fit: StackFit.expand,
      children: List.generate(children.length, (index) {
        final isActive = index == navigationShell.currentIndex;

        return AnimatedOpacity(
          key: ValueKey(index),
          opacity: isActive ? 1 : 0,
          duration: duration,
          curve: Curves.easeOutCubic,
          child: IgnorePointer(
            ignoring: !isActive,
            child: ExcludeFocus(
              excluding: !isActive,
              child: ExcludeSemantics(
                excluding: !isActive,
                child: TickerMode(
                  enabled: isActive,
                  child: RepaintBoundary(child: children[index]),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          // Luôn quay về route gốc của branch khi bấm tab: tránh trường hợp
          // rời tab Nhóm khi đang ở màn chi tiết rồi quay lại vẫn thấy chi tiết.
          navigationShell.goBranch(index, initialLocation: true);
        },
      ),
    );
  }
}
