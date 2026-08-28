import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/settlement_entities.dart';

class AllBillsTab extends StatelessWidget {
  const AllBillsTab({
    required this.bills,
    required this.onTapBill,
    required this.onScanBill,
    this.searchQuery,
    this.onClearSearch,
    super.key,
  });

  final List<SettlementBillEntity> bills;
  final ValueChanged<SettlementBillEntity> onTapBill;
  final VoidCallback onScanBill;
  final String? searchQuery;
  final VoidCallback? onClearSearch;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? AppColors.darkTextMain : AppColors.textMain;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Tất cả hóa đơn chi tiêu đa nhóm:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
            ),
            InkWell(
              onTap: onScanBill,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF0F766E)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      HugeIcons.strokeRoundedCamera01,
                      size: 12,
                      color: Color(0xFF0F766E),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '+ Quét bill',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (bills.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (searchQuery != null && searchQuery!.isNotEmpty)
                        ? HugeIcons.strokeRoundedSearch01
                        : HugeIcons.strokeRoundedInvoice01,
                    size: 38,
                    color: textMuted.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    (searchQuery != null && searchQuery!.isNotEmpty)
                        ? 'Không tìm thấy hóa đơn phù hợp với "$searchQuery"'
                        : 'Chưa có hóa đơn nào',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                  if (searchQuery != null &&
                      searchQuery!.isNotEmpty &&
                      onClearSearch != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: onClearSearch,
                      icon: const Icon(HugeIcons.strokeRoundedCancel01, size: 14),
                      label: const Text('Xóa tìm kiếm để xem tất cả'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F766E),
                        side: const BorderSide(color: Color(0xFF0F766E)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bills.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final bill = bills[index];
              final colors = _statusColors(bill.status);
              return InkWell(
                onTap: () => onTapBill(bill),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(
                              HugeIcons.strokeRoundedInvoice01,
                              size: 16,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bill.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: textMain,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: colors.border),
                            ),
                            child: Text(
                              _statusLabel(bill.status),
                              style: TextStyle(
                                color: colors.foreground,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${bill.groupName} · ${DateFormat('dd/MM/yyyy').format(bill.createdAt.toLocal())}',
                        style: TextStyle(color: textMuted, fontSize: 11.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Người trả trước: ${bill.payerDisplayName}',
                        style: TextStyle(
                          color: textMain,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          CurrencyFormatter.vnd(bill.amount),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          key: ValueKey('bill-progress-${bill.id}'),
                          value: bill.paidRatio,
                          minHeight: 4,
                          backgroundColor: isDark
                              ? AppColors.darkSurfaceSubtle
                              : AppColors.surfaceMuted,
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF0F766E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bill.memberCount == 0
                            ? 'Chưa có tiến độ thanh toán'
                            : '${bill.paidMemberCount}/${bill.memberCount} người đã trả',
                        key: ValueKey('bill-progress-label-${bill.id}'),
                        style: TextStyle(color: textMuted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'draft' => 'Bản nháp',
      'reviewed' => 'Đã duyệt',
      'finalized' => 'Đã chốt sổ',
      'voided' => 'Đã hủy',
      _ => status,
    };
  }

  _BillStatusColors _statusColors(String status) {
    if (status == 'finalized') {
      return const _BillStatusColors(
        foreground: Color(0xFF047857),
        background: Color(0xFFECFDF5),
        border: Color(0xFFA7F3D0),
      );
    }
    return const _BillStatusColors(
      foreground: Color(0xFFB45309),
      background: Color(0xFFFFFBEB),
      border: Color(0xFFFDE68A),
    );
  }
}

class _BillStatusColors {
  const _BillStatusColors({
    required this.foreground,
    required this.background,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final Color border;
}
