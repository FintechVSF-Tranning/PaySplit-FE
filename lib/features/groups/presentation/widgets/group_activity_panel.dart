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
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
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
    final markerColor = switch (activity.kind) {
      GroupActivityKind.payment => AppColors.success,
      GroupActivityKind.bill => AppColors.warning,
      GroupActivityKind.member => AppColors.info,
      GroupActivityKind.system => AppColors.textSubtle,
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
                  border: Border.all(color: AppColors.surface, width: 2),
                  boxShadow: [BoxShadow(color: markerColor.withValues(alpha: 0.25), blurRadius: 6)],
                ),
              ),
              if (!isLast)
                const Expanded(
                  child: VerticalDivider(width: 10, thickness: 1, color: AppColors.border),
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
                      color: AppColors.textMain,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activity.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    activity.timeText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSubtle,
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
