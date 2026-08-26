import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/bill_detail_entity.dart';
import 'bill_breakdown_bottom_sheet.dart';

class BillStickyBottomBar extends StatelessWidget {
  final BillDetailEntity bill;
  final List<BillShareBreakdownEntity> breakdown;
  final bool isSaving;
  final bool isFinalizing;
  final bool isVoiding;
  final bool isCalculatingBreakdown;
  final bool hasBankAccount;
  final bool hasNoItems;
  final bool hasUnassignedItems;
  final bool isTotalMismatch;
  final bool isCaptain;
  final bool isCreditor;
  final bool isEditable;
  final bool isDirty;
  final VoidCallback onSaveDraft;
  final VoidCallback onFinalize;
  final VoidCallback? onVoid;
  final VoidCallback? onReview;
  final VoidCallback? onOpenBreakdown;
  final VoidCallback? onUpdateBankAccount;
  final VoidCallback? onOpenUnassignedDetail;
  final VoidCallback? onOpenMismatchDetail;

  const BillStickyBottomBar({
    super.key,
    required this.bill,
    required this.breakdown,
    required this.isSaving,
    required this.isFinalizing,
    this.isVoiding = false,
    this.isCalculatingBreakdown = false,
    this.hasBankAccount = true,
    this.hasNoItems = false,
    this.hasUnassignedItems = false,
    this.isTotalMismatch = false,
    this.isCaptain = true,
    this.isCreditor = true,
    this.isEditable = true,
    this.isDirty = false,
    required this.onSaveDraft,
    required this.onFinalize,
    this.onVoid,
    this.onReview,
    this.onOpenBreakdown,
    this.onUpdateBankAccount,
    this.onOpenUnassignedDetail,
    this.onOpenMismatchDetail,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final memberCount = breakdown.isNotEmpty ? breakdown.length : (bill.members.isNotEmpty ? bill.members.length : 0);
    final hasWarnings = !hasBankAccount || hasNoItems || hasUnassignedItems || isTotalMismatch;

    final hasMainBreakdownButton = bill.status == 'finalized' ||
        bill.status == 'voided' ||
        (!isCaptain && !isCreditor);
    final showTopBreakdownChip = !hasMainBreakdownButton;
    final showTopRow = hasWarnings || showTopBreakdownChip;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 6 : 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTopRow) ...[
            Row(
              children: [
                Expanded(
                  child: hasWarnings
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!hasBankAccount) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      HugeIcons.strokeRoundedAlert02,
                                      size: 13,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        children: [
                                          const TextSpan(text: 'Chưa cập nhật STK '),
                                          TextSpan(
                                            text: '(cập nhật)',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                              decoration: TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = onUpdateBankAccount,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (hasNoItems) ...[
                              if (!hasBankAccount) const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      HugeIcons.strokeRoundedAlert02,
                                      size: 13,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      'Hoá đơn chưa có món ăn nào',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (hasUnassignedItems && !hasNoItems) ...[
                              if (!hasBankAccount || hasNoItems) const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      HugeIcons.strokeRoundedAlert02,
                                      size: 13,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        children: [
                                          const TextSpan(text: 'Có món chưa được chia '),
                                          TextSpan(
                                            text: '(chi tiết)',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                              decoration: TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = onOpenUnassignedDetail,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (isTotalMismatch) ...[
                              if (!hasBankAccount || hasNoItems || (hasUnassignedItems && !hasNoItems)) const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      HugeIcons.strokeRoundedAlert02,
                                      size: 13,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        children: [
                                          const TextSpan(text: 'Tổng tiền bị chênh lệch '),
                                          TextSpan(
                                            text: '(chi tiết)',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                              decoration: TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = onOpenMismatchDetail,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                if (showTopBreakdownChip) ...[
                  if (hasWarnings) const SizedBox(width: 10),
                  InkWell(
                    onTap: isCalculatingBreakdown
                        ? null
                        : (onOpenBreakdown ??
                            () => BillBreakdownBottomSheet.show(
                                  context,
                                  breakdown: breakdown,
                                  totalAmount: bill.total,
                                )),
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCalculatingBreakdown)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          else
                            const Icon(
                              HugeIcons.strokeRoundedUserGroup,
                              size: 15,
                              color: AppColors.primary,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            isCalculatingBreakdown
                                ? 'Đang tính...'
                                : 'Phân bổ ($memberCount) ▾',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Action Buttons dynamic according to Status & Role
          _buildActionButtons(
            context,
            hasWarnings: hasWarnings,
            textMuted: textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context, {
    required bool hasWarnings,
    required Color textMuted,
  }) {
    // 1. Hoá đơn đã chốt sổ (Finalized)
    if (bill.status == 'finalized') {
      if (isCaptain) {
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: AppButton(
                label: 'Huỷ hoá đơn',
                variant: AppButtonVariant.outline,
                isLoading: isVoiding,
                onPressed: isVoiding ? null : onVoid,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: AppButton(
                label: 'Xem phân bổ',
                variant: AppButtonVariant.gradient,
                onPressed: onOpenBreakdown ??
                    () => BillBreakdownBottomSheet.show(
                          context,
                          breakdown: breakdown,
                          totalAmount: bill.total,
                        ),
              ),
            ),
          ],
        );
      }

      return Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Xem phân bổ',
              variant: AppButtonVariant.gradient,
              onPressed: onOpenBreakdown ??
                  () => BillBreakdownBottomSheet.show(
                        context,
                        breakdown: breakdown,
                        totalAmount: bill.total,
                      ),
            ),
          ),
        ],
      );
    }

    // 2. Hoá đơn đã huỷ (Voided)
    if (bill.status == 'voided') {
      return Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Xem phân bổ',
              variant: AppButtonVariant.outline,
              onPressed: onOpenBreakdown ??
                  () => BillBreakdownBottomSheet.show(
                        context,
                        breakdown: breakdown,
                        totalAmount: bill.total,
                      ),
            ),
          ),
        ],
      );
    }

    // 3. Hoá đơn đã đối soát (Reviewed)
    if (bill.status == 'reviewed') {
      if (isCaptain) {
        return Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Chốt chia tiền',
                variant: hasWarnings ? AppButtonVariant.outline : AppButtonVariant.gradient,
                isLoading: isFinalizing,
                onPressed: (isFinalizing || hasWarnings) ? null : onFinalize,
              ),
            ),
          ],
        );
      } else if (isCreditor) {
        return Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Gửi đối soát',
                variant: (hasWarnings || !isDirty) ? AppButtonVariant.outline : AppButtonVariant.primary,
                isLoading: isSaving,
                onPressed: (isSaving || hasWarnings || !isDirty) ? null : (onReview ?? onFinalize),
              ),
            ),
          ],
        );
      } else {
        return Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Xem phân bổ',
                variant: AppButtonVariant.outline,
                onPressed: onOpenBreakdown ??
                    () => BillBreakdownBottomSheet.show(
                          context,
                          breakdown: breakdown,
                          totalAmount: bill.total,
                        ),
              ),
            ),
          ],
        );
      }
    }

    // 4. Hoá đơn nháp (Draft) hoặc Khởi tạo (Initial)
    if (isCaptain) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: AppButton(
              label: 'Lưu nháp',
              variant: AppButtonVariant.outline,
              isLoading: isSaving,
              onPressed: (isSaving || !isDirty) ? null : onSaveDraft,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: AppButton(
              label: 'Chốt hoá đơn',
              variant: hasWarnings ? AppButtonVariant.outline : AppButtonVariant.gradient,
              isLoading: isFinalizing,
              onPressed: (isFinalizing || hasWarnings) ? null : onFinalize,
            ),
          ),
        ],
      );
    }

    if (isCreditor) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: AppButton(
              label: 'Lưu nháp',
              variant: AppButtonVariant.outline,
              isLoading: isSaving,
              onPressed: (isSaving || !isDirty) ? null : onSaveDraft,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: AppButton(
              label: 'Gửi đối soát',
              variant: hasWarnings ? AppButtonVariant.outline : AppButtonVariant.primary,
              isLoading: isSaving,
              onPressed: (isSaving || hasWarnings) ? null : (onReview ?? onFinalize),
            ),
          ),
        ],
      );
    }

    // Member khác (ReadOnly)
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Xem phân bổ',
            variant: AppButtonVariant.outline,
            onPressed: onOpenBreakdown ??
                () => BillBreakdownBottomSheet.show(
                      context,
                      breakdown: breakdown,
                      totalAmount: bill.total,
                    ),
          ),
        ),
      ],
    );
  }
}
