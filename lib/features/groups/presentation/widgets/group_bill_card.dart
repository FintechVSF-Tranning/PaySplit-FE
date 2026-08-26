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
    final isVoided = bill.status == GroupBillStatus.voided;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isVoided ? 0.6 : 1,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      bill.initials,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
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
                            color: AppColors.textMain,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${bill.dateText}, ${bill.payerName} đã trả trước',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
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
                        color: AppColors.warningText,
                      ),
                    ),
                  ],
                )
              // Tiến độ thanh toán chỉ tồn tại sau khi chốt sổ — backend trả
              // member_count = 0 cho bill chưa chốt nên không vẽ thanh rỗng.
              else if (bill.status == GroupBillStatus.finalized && bill.memberCount > 0) ...[
                _PaidProgressBar(ratio: bill.paidRatio),
                const SizedBox(height: 8),
                Text(
                  '${bill.paidMemberCount} trên ${bill.memberCount} thành viên đã thanh toán',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSubtle,
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
                    color: AppColors.textSubtle,
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
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: ratio,
        minHeight: 3,
        backgroundColor: AppColors.surfaceMuted,
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
      ),
    );
  }
}

/// Dòng trạng thái OCR có chấm nhấp nháy màu hổ phách.
/// Cột phải của thẻ: phần tiền của người đang xem, hoặc lý do chưa có.
class _MyShareBlock extends StatelessWidget {
  const _MyShareBlock({required this.bill});

  final GroupBillEntity bill;

  @override
  Widget build(BuildContext context) {
    if (bill.myShare != null && bill.myShareStatus != GroupBillShareStatus.creditor) {
      final isSettled = bill.myShareStatus == GroupBillShareStatus.settled;
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
              color: isSettled ? AppColors.balancePositive : AppColors.warningText,
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
          color: AppColors.textMuted,
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
    final (bg, fg, border) = switch (status) {
      GroupBillStatus.finalized => (
        AppColors.successSubtle,
        AppColors.balancePositive,
        AppColors.successBorder,
      ),
      GroupBillStatus.draft => (
        AppColors.warningSubtle,
        AppColors.warningText,
        AppColors.warningBorder,
      ),
      GroupBillStatus.reviewed => (
        AppColors.infoSubtle,
        AppColors.infoText,
        AppColors.infoBorder,
      ),
      GroupBillStatus.voided => (AppColors.surfaceMuted, AppColors.textMuted, AppColors.border),
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
