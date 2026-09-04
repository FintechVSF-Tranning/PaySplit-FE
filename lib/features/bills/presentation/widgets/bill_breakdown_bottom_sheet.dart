import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/bill_detail_entity.dart';

class BillBreakdownBottomSheet extends StatelessWidget {
  final List<BillShareBreakdownEntity> breakdown;
  final int totalAmount;

  const BillBreakdownBottomSheet({
    super.key,
    required this.breakdown,
    required this.totalAmount,
  });

  static Future<void> show(
    BuildContext context, {
    required List<BillShareBreakdownEntity> breakdown,
    required int totalAmount,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BillBreakdownBottomSheet(
        breakdown: breakdown,
        totalAmount: totalAmount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      HugeIcons.strokeRoundedUserGroup,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bảng phân bổ chi phí (${breakdown.length} người)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: textMain,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(HugeIcons.strokeRoundedCancel01, size: 20),
                color: textMuted,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // List of member shares or Empty state
          if (breakdown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      HugeIcons.strokeRoundedUserGroup,
                      size: 40,
                      color: textMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có dữ liệu phân bổ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vui lòng thêm món ăn và gán thành viên tham gia để hệ thống tính toán chi tiết.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: breakdown.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final share = breakdown[index];
                  final initials = share.displayName.isNotEmpty
                      ? share.displayName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
                      : 'TV';

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Avatar + Name + Final Amount
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: share.isCreditor
                                  ? const Color(0xFF0F766E)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              backgroundImage: (share.avatarUrl != null && share.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(share.avatarUrl!)
                                  : null,
                              child: (share.avatarUrl == null || share.avatarUrl!.isEmpty)
                                  ? Text(
                                      initials,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: share.isCreditor
                                            ? Colors.white
                                            : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  share.displayName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: textMain,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (share.isCreditor) ...[
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySubtle,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Người trả trước',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                CurrencyFormatter.formatVND(share.finalAmount.toDouble()),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F766E),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Breakdown details (Subtotal, VAT, Surcharge, Discount)
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tiền món: ${CurrencyFormatter.formatVND(share.itemsSubtotal.toDouble())}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: textMuted),
                            ),
                            if (share.serviceShare > 0 || share.vatShare > 0)
                              Text(
                                'Thuế/Phí: +${CurrencyFormatter.formatVND((share.serviceShare + share.vatShare).toDouble())}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: textMuted),
                              ),
                            if (share.generalDiscountShare > 0)
                              Text(
                                'Voucher: -${CurrencyFormatter.formatVND(share.generalDiscountShare.toDouble())}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF059669)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Total Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Tổng cộng cả hoá đơn:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    CurrencyFormatter.formatVND(totalAmount.toDouble()),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
