import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/group_activity_entity.dart';
import '../../domain/entities/group_detail_entity.dart';
import 'group_debts_panel.dart';

/// Tab "Hoạt động": timeline sự kiện của nhóm + nút tải thêm.
class GroupActivityPanel extends StatelessWidget {
  const GroupActivityPanel({
    super.key,
    required this.detail,
    required this.onLoadMore,
    required this.hasMore,
  });

  final GroupDetailEntity detail;
  final VoidCallback onLoadMore;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF14B8A6) : AppColors.primary;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupPanelHead(
          title: 'Hoạt động nhóm',
          subtitle: 'Các thay đổi gần đây trong ${detail.group.name}',
        ),
        const SizedBox(height: 14),

        for (var i = 0; i < detail.activities.length; i++)
          _ActivityRow(activity: detail.activities[i], isLast: i == detail.activities.length - 1),

        const SizedBox(height: 6),
        OutlinedButton(
          onPressed: hasMore ? onLoadMore : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            disabledForegroundColor: textMuted,
            side: BorderSide(color: borderColor),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          child: Text(
            hasMore ? 'Tải thêm hoạt động' : 'Đã hiển thị toàn bộ hoạt động',
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.isLast});

  final GroupActivityEntity activity;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final textSubtle = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final surface = isDark ? const Color(0xFF0F172A) : Colors.white;
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final markerColor = switch (activity.kind) {
      GroupActivityKind.payment => isDark ? const Color(0xFF34D399) : AppColors.success,
      GroupActivityKind.bill => isDark ? const Color(0xFFFBBF24) : AppColors.warning,
      GroupActivityKind.member => isDark ? const Color(0xFF60A5FA) : AppColors.info,
      GroupActivityKind.system => isDark ? const Color(0xFF94A3B8) : AppColors.textSubtle,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột mốc timeline: chấm tròn + đường nối xuống mục kế tiếp.
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: surface, width: 2),
                  boxShadow: [BoxShadow(color: markerColor.withValues(alpha: 0.25), blurRadius: 6)],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: VerticalDivider(width: 10, thickness: 1, color: dividerColor),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: textMain,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activity.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    activity.timeText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textSubtle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
