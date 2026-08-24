import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/group_entity.dart';

/// Thẻ nhóm trong danh sách "Nhóm của tôi": bo góc 18px, viền 1px, bóng mềm.
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
          // Nhóm đã khóa bill hạ tông xuống nền xám và bỏ đổ bóng: vẫn đọc được
          // nhưng lùi lại phía sau các nhóm đang hoạt động.
          color: isClosed ? AppColors.surfaceSubtle : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: isClosed
              ? null
              : [
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
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isClosed ? AppColors.surfaceMuted : AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isClosed ? AppColors.border : AppColors.primaryBorder,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: isClosed ? 0.55 : 1,
                    child: Text(group.emoji, style: const TextStyle(fontSize: 21)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              group.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (isClosed) ...[
                            const SizedBox(width: 6),
                            const _ClosedBadge(),
                          ] else if (group.isCaptain) ...[
                            const SizedBox(width: 6),
                            const _CaptainBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            HugeIcons.strokeRoundedUserGroup,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${group.memberCount} thành viên',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (group.pendingBillCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: AppColors.textSubtle,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${group.pendingBillCount} hóa đơn đang mở',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warningText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      group.balanceState == GroupBalanceState.settled
                          ? CurrencyFormatter.vnd(0)
                          : CurrencyFormatter.vndSigned(group.myBalance),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: balanceFg,
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
                        // Nhóm khóa bill vẫn có thể còn nợ, nên nhãn phải nói rõ
                        // là số tiền đã được chốt chứ không phải đã trả xong.
                        isClosed && group.myBalance != 0 ? 'Đã khóa, cần trả' : balanceLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: balanceFg,
                        ),
                      ),
                    ),
                  ],
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
                    group.lastActivity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isClosed && group.closedAtText != null
                      ? 'Khóa bill ${group.closedAtText}'
                      : formatRelativeTime(group.lastActivityAt),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warningSubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Text(
        'Trưởng nhóm',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.warningText,
        ),
      ),
    );
  }
}

/// Huy hiệu nhóm đã khóa bill — tông slate trung tính để không tranh màu với
/// các pill tài chính (xanh/đỏ) nằm cùng thẻ.
class _ClosedBadge extends StatelessWidget {
  const _ClosedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            HugeIcons.strokeRoundedCheckmarkCircle02,
            size: 11,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 3),
          Text(
            'Đã khóa bill',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ],
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
