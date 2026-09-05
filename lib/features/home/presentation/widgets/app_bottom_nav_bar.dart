import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';

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

/// Bảng màu của thanh điều hướng, tách riêng theo chế độ sáng/tối.
///
/// Thanh này cố ý không lấy màu từ `colorScheme`: tông olive của nó lệch khỏi
/// bộ màu trung tính trong `ThemeData`. Nhưng "tự khai báo màu" trước đây đồng
/// nghĩa với chỉ có bản sáng — ở dark mode thanh vẫn trắng, nổi hẳn lên giữa
/// nền tối và chữ xám #676E5F gần như không đọc được.
class _NavBarPalette {
  const _NavBarPalette({
    required this.background,
    required this.border,
    required this.active,
    required this.inactive,
  });

  /// Bản sáng giữ nguyên đúng các mã màu cũ, nên đổi chế độ không kéo theo
  /// thay đổi nào cho giao diện sáng.
  factory _NavBarPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark
        ? const _NavBarPalette(
            background: AppColors.darkSurface,
            border: AppColors.darkBorder,
            active: AppColors.darkPrimary,
            inactive: AppColors.darkTextMuted,
          )
        : const _NavBarPalette(
            background: AppColors.paper,
            border: Color(0xFFDBE0CE), // Olive Zinc Border
            active: AppColors.primary, // Deep Teal
            inactive: AppColors.textMuted, // Olive Muted Text
          );
  }

  final Color background;
  final Color border;
  final Color active;
  final Color inactive;
}

/// Custom Bottom Navigation Bar tuân thủ chuẩn PaySplit (Tally x Hallmark).
///
/// - Thiết kế 4 tab cố định: Tổng quan, Nhóm, Hóa đơn, Cài đặt.
/// - Active indicator: Dấu chấm tròn 4px màu chủ đạo (Deep Teal ở chế độ sáng, Teal sáng ở chế độ tối) chỉ xuất hiện ở tab đang active (`index == currentIndex`).
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
    final palette = _NavBarPalette.of(context);

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: palette.background,
        border: Border(top: BorderSide(color: palette.border)),
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
              palette: palette,
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
  final _NavBarPalette palette;
  final VoidCallback onTap;

  const _BottomNavItemWidget({
    required this.item,
    required this.isSelected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = palette.active;
    final inactiveColor = palette.inactive;
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
                        decoration: BoxDecoration(
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
