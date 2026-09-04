import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/settlement_entities.dart';
import '../providers/settlement_controller.dart';

class SelectDebtBatchSheet extends ConsumerWidget {
  const SelectDebtBatchSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settlementControllerProvider);
    final controller = ref.read(settlementControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? AppColors.darkTextMain : AppColors.textMain;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPaper : const Color(0xFFF8FAF9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
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
                  color: isDark
                      ? AppColors.darkBorderStrong
                      : AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Chọn khoản nợ & Trả gộp',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 8),

            // Single-Creditor Rule Notice Banner
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF042F2E)
                    : const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF0F766E)
                      : const Color(0xFFCCFBF1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    HugeIcons.strokeRoundedInformationCircle,
                    color: Color(0xFF0F766E),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: isDark
                              ? const Color(0xFF99F6E4)
                              : const Color(0xFF0F766E),
                          height: 1.35,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Quy tắc VietQR: ',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text:
                                'Mã chuyển tiền trực tiếp đến STK của 1 chủ nợ duy nhất. Chỉ có thể gộp các hóa đơn của ',
                          ),
                          TextSpan(
                            text: 'cùng một người nhận',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Creditor Groups List
            for (final group in state.groupedDebts) ...[
              _buildCreditorCard(
                context: context,
                group: group,
                state: state,
                controller: controller,
                isDark: isDark,
                textMain: textMain,
                textMuted: textMuted,
                cardBg: cardBg,
                borderCol: borderCol,
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCreditorCard({
    required BuildContext context,
    required SingleCreditorBatchEntity group,
    required SettlementState state,
    required SettlementController controller,
    required bool isDark,
    required Color textMain,
    required Color textMuted,
    required Color cardBg,
    required Color borderCol,
  }) {
    final selectedDebtsInGroup = group.debts
        .where((d) => state.selectedDebtIds.contains(d.id))
        .toList();
    final currentTotal = selectedDebtsInGroup.fold<int>(
      0,
      (sum, item) => sum + item.amount,
    );

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Creditor Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          group.creditorAvatar,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.creditorName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: textMain,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            group.groupName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${group.debts.length} khoản nợ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '-${CurrencyFormatter.vnd(group.totalAmount)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Debts in this group
          ...group.debts.map((debt) {
            final isSelected = state.selectedDebtIds.contains(debt.id);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => controller.toggleDebtSelection(debt.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    IgnorePointer(
                      child: Checkbox(
                        value: isSelected,
                        activeColor: const Color(0xFF0F766E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (_) {},
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debt.billTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textMain,
                            ),
                          ),
                          Text(
                            debt.groupName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '-${CurrencyFormatter.vnd(debt.amount)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? const Color(0xFFDC2626) : textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 10),

          // Group Pay Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Tổng chọn: ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.vnd(currentTotal),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: currentTotal > 0
                    ? () {
                        Navigator.of(context).pop(
                          BatchPaymentSelection(
                            groupId: group.groupId,
                            creditorId: group.creditorId,
                            amount: currentTotal,
                            creditorName: group.creditorName,
                            debtIds: selectedDebtsInGroup
                                .map((debt) => debt.id)
                                .toList(),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(HugeIcons.strokeRoundedQrCode, size: 14),
                label: const Text('Trả nợ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
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

class BatchPaymentSelection {
  const BatchPaymentSelection({
    required this.groupId,
    required this.creditorId,
    required this.amount,
    required this.creditorName,
    required this.debtIds,
  });

  final String groupId;
  final String creditorId;
  final int amount;
  final String creditorName;
  final List<String> debtIds;
}
