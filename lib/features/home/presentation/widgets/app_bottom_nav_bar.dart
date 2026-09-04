import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

const appBottomNavigationTransitionDuration = Duration(milliseconds: 160);

/// DTO cấu hình cho mỗi mục trong Bottom Navigation Bar
class BottomNavItemData {
  final IconData icon;
  final String label;
  final String route;

  const BottomNavItemData({
    required this.icon,
    required this.label,
    required this.route,
  });
}

/// Custom Bottom Navigation Bar tuân thủ chuẩn PaySplit (Tally x Hallmark).
///
/// - Thiết kế 4 tab cố định: Tổng quan, Nhóm, Hóa đơn, Cài đặt.
/// - Active indicator: Dấu chấm tròn 4px màu Deep Teal (#0F766E) chỉ xuất hiện ở tab đang active (`index == currentIndex`).
/// - Tab không active: Dấu chấm giữ kích thước 4px nhưng có màu `Colors.transparent` để giữ nguyên chiều cao layout, tránh giật khung hình.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItemData>? items;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items,
  });

  static const defaultItems = [
    BottomNavItemData(
      icon: HugeIcons.strokeRoundedHome01,
      label: 'Tổng quan',
      route: '/home',
    ),
    BottomNavItemData(
      icon: HugeIcons.strokeRoundedUserGroup,
      label: 'Nhóm',
      route: '/groups',
    ),
    BottomNavItemData(
      icon: HugeIcons.strokeRoundedInvoice01,
      label: 'Hóa đơn',
      route: '/bills',
    ),
    BottomNavItemData(
      icon: HugeIcons.strokeRoundedSettings01,
      label: 'Cài đặt',
      route: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final navItems = items ?? defaultItems;

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFDBE0CE), // Olive Zinc Border
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          final item = navItems[index];
          final isSelected = index == currentIndex;

          return Expanded(
            child: _BottomNavItemWidget(
              item: item,
              isSelected: isSelected,
              onTap: () => onTap(index),
            ),
          );
        }),
      ),
    );
  }
}

class _BottomNavItemWidget extends StatelessWidget {
  final BottomNavItemData item;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF0F766E); // Deep Teal
    const inactiveColor = Color(0xFF676E5F); // Olive Muted Text
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: isSelected ? 1 : 0),
        duration: disableAnimations
            ? Duration.zero
            : appBottomNavigationTransitionDuration,
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) {
          final color = Color.lerp(inactiveColor, activeColor, progress)!;

          return InkWell(
            onTap: onTap,
            excludeFromSemantics: true,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 1 + (0.05 * progress),
                    child: Icon(item.icon, size: 20, color: color),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Opacity(
                    opacity: progress,
                    child: Transform.scale(
                      scale: 0.75 + (0.25 * progress),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: activeColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
