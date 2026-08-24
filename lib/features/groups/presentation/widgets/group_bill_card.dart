import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/group_bill_entity.dart';

/// Thẻ hóa đơn dạng Receipt Card trong tab "Hóa đơn" của nhóm.
class GroupBillCard extends StatelessWidget {
  const GroupBillCard({super.key, required this.bill, this.onTap});

  final GroupBillEntity bill;
  final VoidCallback? onTap;

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
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _AmountBlock(
                      label: bill.status == GroupBillStatus.settled
                          ? 'Tổng hóa đơn'
                          : 'Tổng tạm tính',
                      value: CurrencyFormatter.vnd(bill.totalAmount),
                    ),
                  ),
                  Expanded(
                    child: bill.myShare != null
                        ? _AmountBlock(
                            label: 'Phần của bạn',
                            value: CurrencyFormatter.vnd(bill.myShare!),
                            alignEnd: true,
                          )
                        : Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              bill.status == GroupBillStatus.voided
                                  ? 'Hóa đơn đã hủy'
                                  : 'Chờ phân bổ món',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (bill.status == GroupBillStatus.ocrScanning)
                const _OcrProgressLine()
              else if (bill.status == GroupBillStatus.settled) ...[
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
                  bill.status == GroupBillStatus.awaitingAllocation
                      ? 'Cần gán món cho từng thành viên'
                      : 'Hóa đơn đã bị hủy bỏ',
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
class _OcrProgressLine extends StatefulWidget {
  const _OcrProgressLine();

  @override
  State<_OcrProgressLine> createState() => _OcrProgressLineState();
}

class _OcrProgressLineState extends State<_OcrProgressLine> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FadeTransition(
          opacity: _controller,
          child: Container(
            width: 14,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Đang nhận diện ảnh hóa đơn',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.warningText,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final GroupBillStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (status) {
      GroupBillStatus.settled => (
        AppColors.successSubtle,
        AppColors.balancePositive,
        AppColors.successBorder,
      ),
      GroupBillStatus.ocrScanning => (
        AppColors.warningSubtle,
        AppColors.warningText,
        AppColors.warningBorder,
      ),
      GroupBillStatus.awaitingAllocation => (
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
