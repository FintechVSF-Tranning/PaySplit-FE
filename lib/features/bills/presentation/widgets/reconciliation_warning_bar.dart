import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/bill_detail_entity.dart';

class ReconciliationWarningBar extends StatelessWidget {
  final int computedTotal;
  final int reportedTotal;
  final int deltaTotal;
  final List<BillItemEntity> unassignedItems;
  final VoidCallback onBalanceTotal;
  final Function(int amount) onAddAdjustment;

  const ReconciliationWarningBar({
    super.key,
    required this.computedTotal,
    required this.reportedTotal,
    required this.deltaTotal,
    required this.unassignedItems,
    required this.onBalanceTotal,
    required this.onAddAdjustment,
  });

  @override
  Widget build(BuildContext context) {
    final isMatched = deltaTotal == 0 && unassignedItems.isEmpty;
    final isMissing = deltaTotal < 0;
    final isExcess = deltaTotal > 0;

    if (isMatched) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: [
            const Icon(
              HugeIcons.strokeRoundedCheckmarkCircle02,
              color: Color(0xFF059669),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tổng tính toán: ${CurrencyFormatter.formatVND(computedTotal.toDouble())} · Khớp 100% với hoá đơn gốc',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF065F46),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMissing ? const Color(0xFFFEF2F2) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMissing ? const Color(0xFFFECACA) : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                HugeIcons.strokeRoundedAlert02,
                color: isMissing ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMissing)
                      Text(
                        'Tổng tính toán (${CurrencyFormatter.formatVND(computedTotal.toDouble())}) THIẾU ${CurrencyFormatter.formatVND(deltaTotal.abs().toDouble())} so với hoá đơn gốc (${CurrencyFormatter.formatVND(reportedTotal.toDouble())})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF991B1B),
                        ),
                      )
                    else if (isExcess)
                      Text(
                        'Tổng tính toán (${CurrencyFormatter.formatVND(computedTotal.toDouble())}) DƯ ${CurrencyFormatter.formatVND(deltaTotal.abs().toDouble())} so với hoá đơn gốc (${CurrencyFormatter.formatVND(reportedTotal.toDouble())})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    if (unassignedItems.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '• Còn ${unassignedItems.length} món chưa phân bổ người.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isMissing ? const Color(0xFFB91C1C) : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Action Buttons for fast reconciliation
          if (deltaTotal != 0) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (isMissing)
                  OutlinedButton.icon(
                    onPressed: () => onAddAdjustment(deltaTotal.abs()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF991B1B),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(HugeIcons.strokeRoundedPlusSign, size: 14),
                    label: Text(
                      '+ Thêm phụ thu ${CurrencyFormatter.formatVND(deltaTotal.abs().toDouble())}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed: onBalanceTotal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMissing ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Text(
                    'Cập nhật Tổng bill = ${CurrencyFormatter.formatVND(computedTotal.toDouble())}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
