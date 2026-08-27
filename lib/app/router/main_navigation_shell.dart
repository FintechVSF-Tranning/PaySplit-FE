import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/groups/presentation/providers/groups_provider.dart';
import '../../features/home/presentation/providers/home_activities_provider.dart';
import '../../features/home/presentation/providers/home_groups_provider.dart';
import '../../features/home/presentation/widgets/app_bottom_nav_bar.dart';

/// Thứ tự branch của [StatefulShellRoute] trong `app_router.dart`.
const int _homeBranchIndex = 0;
const int _groupsBranchIndex = 1;

class MainNavigationShell extends ConsumerWidget {
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

  /// Bấm vào tab đang mở dữ liệu từ cache của phiên — nhóm có thể đã bị người
  /// khác đổi tên, thêm người, hoặc phát sinh công nợ từ lúc mở app. Coi cú bấm
  /// tab là ý muốn "xem cái mới nhất" và tải lại đúng dữ liệu của tab đó.
  ///
  /// Chỉ đụng tới provider **đang sống**: một tab chưa từng mở thì chưa có gì
  /// để làm mới, đánh thức nó ở đây chỉ tạo request thừa cho màn hình người
  /// dùng còn chưa nhìn thấy.
  void _refreshBranch(BuildContext context, WidgetRef ref, int index) {
    final container = ProviderScope.containerOf(context, listen: false);

    switch (index) {
      case _homeBranchIndex:
        if (container.exists(homeGroupsProvider)) {
          ref.invalidate(homeGroupsProvider);
        }
        if (container.exists(homeActivitiesProvider)) {
          ref.invalidate(homeActivitiesProvider);
        }
      case _groupsBranchIndex:
        if (container.exists(groupsProvider)) {
          ref.read(groupsProvider.notifier).refresh();
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          _refreshBranch(context, ref, index);
          // Luôn quay về route gốc của branch khi bấm tab: tránh trường hợp
          // rời tab Nhóm khi đang ở màn chi tiết rồi quay lại vẫn thấy chi tiết.
          navigationShell.goBranch(index, initialLocation: true);
        },
      ),
    );
  }
}
