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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isClosed = group.isClosed;

    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final textSubtle = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final (balanceBg, balanceFg, balanceLabel) = switch (group.balanceState) {
      GroupBalanceState.positive => (
        isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : AppColors.balancePositiveBg,
        isDark ? const Color(0xFF34D399) : AppColors.balancePositive,
        'Bạn được nhận',
      ),
      GroupBalanceState.negative => (
        isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : AppColors.balanceNegativeBg,
        isDark ? const Color(0xFFF87171) : AppColors.balanceNegative,
        'Bạn cần trả',
      ),
      GroupBalanceState.settled => (
        isDark ? const Color(0xFF334155).withValues(alpha: 0.4) : const Color(0xFFF1F5F9),
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        'Đã cân bằng',
      ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                                color: textMain,
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
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  HugeIcons.strokeRoundedUserGroup,
                                  size: 13,
                                  color: textMuted,
                                ),
                              ),
                            ),
                            TextSpan(
                              text: '${group.memberCount} thành viên',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textMuted,
                              ),
                            ),
                            if (group.pendingBillCount > 0) ...[
                              TextSpan(
                                text: '  •  ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textSubtle,
                                ),
                              ),
                              TextSpan(
                                text: '${group.pendingBillCount} bill mở',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFFBBF24) : AppColors.warningText,
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
            Divider(height: 1, color: dividerColor),
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
                      color: textMuted,
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
                    color: textSubtle,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : AppColors.warningSubtle;
    final border = isDark ? const Color(0xFFD97706).withValues(alpha: 0.4) : AppColors.warningBorder;
    final fg = isDark ? const Color(0xFFFBBF24) : AppColors.warningText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Trưởng nhóm',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: fg,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF334155).withValues(alpha: 0.4) : AppColors.surfaceMuted;
    final border = isDark ? const Color(0xFF475569) : AppColors.border;
    final fg = isDark ? const Color(0xFFFBBF24) : AppColors.warningText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              HugeIcons.strokeRoundedLock,
              size: 11,
              color: fg,
            ),
            const SizedBox(width: 3),
            Text(
              'Tạm khóa',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: fg,
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
