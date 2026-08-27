import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/activity_mapper.dart';
import '../../domain/entities/group_entity.dart';
import 'group_avatar.dart';

/// Thẻ nhóm trong danh sách "Nhóm của tôi": bo góc 18px, viền 1px, bóng mềm, responsive trên mọi kích thước.
class GroupListCard extends StatelessWidget {
  const GroupListCard({super.key, required this.group, this.onTap});

  final GroupEntity group;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isClosed = group.isClosed;

    final (balanceBg, balanceFg, balanceLabel) = switch (group.balanceState) {
      GroupBalanceState.positive => (
        AppColors.balancePositiveBg,
        AppColors.balancePositive,
        'Bạn được nhận',
      ),
      GroupBalanceState.negative => (
        AppColors.balanceNegativeBg,
        AppColors.balanceNegative,
        'Bạn cần trả',
      ),
      GroupBalanceState.settled => (AppColors.surfaceMuted, AppColors.textMuted, 'Đã cân bằng'),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GroupAvatar(group: group),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            flex: 3,
                            child: Text(
                              group.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (isClosed) ...[
                            const SizedBox(width: 6),
                            const Flexible(
                              flex: 2,
                              child: _LockedBadge(),
                            ),
                          ] else if (group.isCaptain) ...[
                            const SizedBox(width: 6),
                            const Flexible(
                              flex: 2,
                              child: _CaptainBadge(),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(
                                  HugeIcons.strokeRoundedUserGroup,
                                  size: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            TextSpan(
                              text: '${group.memberCount} thành viên',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (group.pendingBillCount > 0) ...[
                              TextSpan(
                                text: '  •  ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSubtle,
                                ),
                              ),
                              TextSpan(
                                text: '${group.pendingBillCount} bill mở',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warningText,
                                ),
                              ),
                            ],
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          group.balanceState == GroupBalanceState.settled
                              ? CurrencyFormatter.vnd(0)
                              : CurrencyFormatter.vndSigned(group.myBalance),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: balanceFg,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: balanceBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          balanceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: balanceFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.lastActivity != null
                        ? formatActivityTitle(group.lastActivity!)
                        : 'Chưa có hoạt động nào',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isClosed && group.closedAtText != null
                      ? group.closedAtText!
                      : group.lastActivityAt == null
                      ? ''
                      : formatRelativeTime(group.lastActivityAt!),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSubtle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptainBadge extends StatelessWidget {
  const _CaptainBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warningSubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Trưởng nhóm',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: AppColors.warningText,
          ),
        ),
      ),
    );
  }
}

/// Huy hiệu nhóm tạm khóa nhận bill — gọn gàng, rõ ràng
class _LockedBadge extends StatelessWidget {
  const _LockedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warningSubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              HugeIcons.strokeRoundedLock,
              size: 11,
              color: AppColors.warningText,
            ),
            const SizedBox(width: 3),
            Text(
              'Tạm khóa',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppColors.warningText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thời gian tương đối kiểu "5 phút trước" cho các dòng hoạt động nhóm.
String formatRelativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 30) return '${diff.inDays} ngày trước';
  return '${diff.inDays ~/ 30} tháng trước';
}
