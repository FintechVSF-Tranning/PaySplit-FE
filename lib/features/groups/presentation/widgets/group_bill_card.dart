import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/group_bill_entity.dart';

/// Thẻ hóa đơn dạng Receipt Card trong tab "Hóa đơn" của nhóm.
class GroupBillCard extends StatelessWidget {
  const GroupBillCard({super.key, required this.bill, this.onTap, this.onDelete});

  final GroupBillEntity bill;
  final VoidCallback? onTap;

  /// Gỡ bỏ hóa đơn. `null` nghĩa là người đang xem không có quyền — nút không
  /// hiện, thay vì hiện rồi báo lỗi khi bấm.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVoided = bill.status == GroupBillStatus.voided;

    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final initialsBg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final initialsBorder = isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0);
    final initialsColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final textSubtle = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isVoided ? 0.6 : 1,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: initialsBg,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: initialsBorder),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      bill.initials,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: initialsColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textMain,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${bill.dateText}, ${bill.payerName} đã trả trước',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(status: bill.status),
                  if (onDelete != null) ...[
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(
                          HugeIcons.strokeRoundedDelete02,
                          size: 17,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _AmountBlock(
                      label: bill.status == GroupBillStatus.finalized
                          ? 'Tổng hóa đơn'
                          : 'Tổng tạm tính',
                      value: CurrencyFormatter.vnd(bill.totalAmount),
                    ),
                  ),
                  Expanded(child: _MyShareBlock(bill: bill)),
                ],
              ),
              const SizedBox(height: 12),

              // Ảnh đang được AI bóc tách: chưa có món nào để nói chuyện gán.
              if (bill.isScanningOcr)
                Row(
                  children: [
                    const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(strokeWidth: 1.8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Đang quét hóa đơn bằng AI...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFFBBF24) : AppColors.warningText,
                      ),
                    ),
                  ],
                )
              // Tiến độ thanh toán chỉ tồn tại sau khi chốt sổ
              else if (bill.status == GroupBillStatus.finalized && bill.memberCount > 0) ...[
                _PaidProgressBar(ratio: bill.paidRatio),
                const SizedBox(height: 8),
                Text(
                  '${bill.paidMemberCount} trên ${bill.memberCount} thành viên đã thanh toán',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: textSubtle,
                  ),
                ),
              ] else
                Text(
                  switch (bill.status) {
                    GroupBillStatus.draft => 'Cần gán món cho từng thành viên',
                    GroupBillStatus.reviewed => 'Đã đối soát, chờ chốt sổ',
                    GroupBillStatus.finalized => 'Đã chốt sổ',
                    GroupBillStatus.voided => 'Hóa đơn đã bị hủy bỏ',
                  },
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: textSubtle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountBlock extends StatelessWidget {
  const _AmountBlock({required this.label, required this.value, this.alignEnd = false});

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textMain,
          ),
        ),
      ],
    );
  }
}

class _PaidProgressBar extends StatelessWidget {
  const _PaidProgressBar({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final primaryColor = isDark ? const Color(0xFF14B8A6) : AppColors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: ratio,
        minHeight: 3,
        backgroundColor: bg,
        valueColor: AlwaysStoppedAnimation(primaryColor),
      ),
    );
  }
}

class _MyShareBlock extends StatelessWidget {
  const _MyShareBlock({required this.bill});

  final GroupBillEntity bill;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    if (bill.myShare != null && bill.myShareStatus != GroupBillShareStatus.creditor) {
      final isSettled = bill.myShareStatus == GroupBillShareStatus.settled;
      final statusColor = isSettled
          ? (isDark ? const Color(0xFF34D399) : AppColors.balancePositive)
          : (isDark ? const Color(0xFFFBBF24) : AppColors.warningText);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _AmountBlock(
            label: 'Phần của bạn',
            value: CurrencyFormatter.vnd(bill.myShare!),
            alignEnd: true,
          ),
          const SizedBox(height: 3),
          Text(
            isSettled ? 'Bạn đã trả xong' : 'Bạn còn phải trả',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      );
    }

    final note = switch (bill.myShareStatus) {
      GroupBillShareStatus.creditor => 'Bạn đã trả trước',
      _ => switch (bill.status) {
        GroupBillStatus.voided => 'Hóa đơn đã hủy',
        GroupBillStatus.finalized => 'Bạn không có phần trong hóa đơn này',
        _ => bill.isScanningOcr ? 'Chờ AI bóc tách' : 'Chờ phân bổ món',
      },
    };

    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        note,
        textAlign: TextAlign.end,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final GroupBillStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (bg, fg, border) = switch (status) {
      GroupBillStatus.finalized => (
        isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : AppColors.successSubtle,
        isDark ? const Color(0xFF34D399) : AppColors.balancePositive,
        isDark ? const Color(0xFF059669).withValues(alpha: 0.4) : AppColors.successBorder,
      ),
      GroupBillStatus.draft => (
        isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : AppColors.warningSubtle,
        isDark ? const Color(0xFFFBBF24) : AppColors.warningText,
        isDark ? const Color(0xFFD97706).withValues(alpha: 0.4) : AppColors.warningBorder,
      ),
      GroupBillStatus.reviewed => (
        isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : AppColors.infoSubtle,
        isDark ? const Color(0xFF60A5FA) : AppColors.infoText,
        isDark ? const Color(0xFF2563EB).withValues(alpha: 0.4) : AppColors.infoBorder,
      ),
      GroupBillStatus.voided => (
        isDark ? const Color(0xFF334155).withValues(alpha: 0.4) : AppColors.surfaceMuted,
        isDark ? const Color(0xFF94A3B8) : AppColors.textMuted,
        isDark ? const Color(0xFF475569) : AppColors.border,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
