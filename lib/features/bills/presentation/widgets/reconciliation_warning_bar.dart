import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/bill_detail_entity.dart';

class ReconciliationWarningBar extends StatelessWidget {
  final int computedTotal;
  final int reportedTotal;
  final int deltaTotal;
  final List<BillItemEntity> unassignedItems;
  final bool isEditable;
  final VoidCallback onBalanceTotal;
  final VoidCallback onAddSurcharge;
  final VoidCallback onAddVoucher;

  const ReconciliationWarningBar({
    super.key,
    required this.computedTotal,
    required this.reportedTotal,
    required this.deltaTotal,
    required this.unassignedItems,
    required this.isEditable,
    required this.onBalanceTotal,
    required this.onAddSurcharge,
    required this.onAddVoucher,
  });

  @override
  Widget build(BuildContext context) {
    final isMatched = deltaTotal == 0 && unassignedItems.isEmpty;
    final isMissing = deltaTotal < 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tone = isMatched
        ? _ReconciliationTone.success(isDark)
        : isMissing
        ? _ReconciliationTone.danger(isDark)
        : _ReconciliationTone.warning(isDark);

    return Semantics(
      liveRegion: true,
      label: _semanticLabel(isMatched: isMatched, isMissing: isMissing),
      child: Container(
        key: const Key('reconciliation-warning-bar'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tone.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isMatched
                      ? HugeIcons.strokeRoundedCheckmarkCircle02
                      : HugeIcons.strokeRoundedAlert02,
                  color: tone.accent,
                  size: 21,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    isMatched
                        ? 'Đối soát hóa đơn'
                        : isMissing
                        ? 'Cảnh báo: Tính toán THIẾU tiền'
                        : deltaTotal > 0
                        ? 'Cảnh báo: Tính toán DƯ tiền'
                        : 'Cảnh báo: Còn món chưa gán',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tone.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (deltaTotal == 0)
              Text(
                'Tổng tính toán là ${_money(computedTotal)}, khớp hoàn toàn với hóa đơn gốc.',
                style: _bodyStyle(tone.text),
              )
            else
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Tổng tính toán là '),
                    TextSpan(
                      text: _money(computedTotal),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: isMissing ? ', đang THIẾU ' : ', đang DƯ '),
                    TextSpan(
                      text: _money(deltaTotal.abs()),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ' so với hóa đơn gốc ('),
                    TextSpan(
                      text: _money(reportedTotal),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ').'),
                  ],
                ),
                style: _bodyStyle(tone.text),
              ),
            if (unassignedItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              Divider(height: 1, color: tone.border),
              const SizedBox(height: 8),
              Text(
                _unassignedMessage(),
                style: _bodyStyle(
                  tone.text,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
            if (isEditable && deltaTotal != 0) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: tone.border),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isMissing)
                    OutlinedButton.icon(
                      key: const Key('add-surcharge-action'),
                      onPressed: onAddSurcharge,
                      style: _outlineStyle(tone),
                      icon: const Icon(
                        HugeIcons.strokeRoundedPlusSign,
                        size: 15,
                      ),
                      label: Text('+ Thêm phụ thu ${_money(deltaTotal.abs())}'),
                    )
                  else
                    OutlinedButton.icon(
                      key: const Key('add-voucher-action'),
                      onPressed: onAddVoucher,
                      style: _outlineStyle(tone),
                      icon: const Icon(
                        HugeIcons.strokeRoundedCouponPercent,
                        size: 15,
                      ),
                      label: Text('Bù vào Voucher ${_money(deltaTotal)}'),
                    ),
                  OutlinedButton(
                    key: const Key('balance-reported-total-action'),
                    onPressed: onBalanceTotal,
                    style: _outlineStyle(tone),
                    child: Text(
                      'Cập nhật Tổng bill thành ${_money(computedTotal)}',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  TextStyle _bodyStyle(Color color) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 12.5,
      height: 1.45,
      color: color,
    );
  }

  ButtonStyle _outlineStyle(_ReconciliationTone tone) {
    return OutlinedButton.styleFrom(
      foregroundColor: tone.text,
      backgroundColor: tone.buttonBackground,
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      side: BorderSide(color: tone.border),
      textStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  String _semanticLabel({required bool isMatched, required bool isMissing}) {
    final reconciliation = isMatched
        ? 'Tổng tính toán ${_money(computedTotal)} khớp hóa đơn gốc.'
        : 'Tổng tính toán ${_money(computedTotal)} '
              '${isMissing ? 'thiếu' : 'dư'} ${_money(deltaTotal.abs())} '
              'so với hóa đơn gốc ${_money(reportedTotal)}.';
    if (unassignedItems.isEmpty) return reconciliation;
    return '$reconciliation ${_unassignedMessage()}';
  }

  String _unassignedMessage() {
    final first = unassignedItems.first;
    final firstDescription = '${first.name}, ${_money(first.finalPrice)}';
    if (unassignedItems.length == 1) {
      return 'Còn 1 món ($firstDescription) chưa phân bổ cho ai.';
    }
    return 'Còn ${unassignedItems.length} món chưa phân bổ cho ai, gồm $firstDescription và ${unassignedItems.length - 1} món khác.';
  }
}

class _ReconciliationTone {
  final Color background;
  final Color buttonBackground;
  final Color border;
  final Color accent;
  final Color text;

  const _ReconciliationTone({
    required this.background,
    required this.buttonBackground,
    required this.border,
    required this.accent,
    required this.text,
  });

  factory _ReconciliationTone.success(bool isDark) {
    return _ReconciliationTone(
      background: isDark
          ? AppColors.success.withValues(alpha: 0.14)
          : AppColors.successSubtle,
      buttonBackground: isDark ? AppColors.darkSurface : AppColors.surface,
      border: isDark ? AppColors.success : AppColors.successBorder,
      accent: AppColors.balancePositive,
      text: isDark ? AppColors.darkTextMain : AppColors.successText,
    );
  }

  factory _ReconciliationTone.danger(bool isDark) {
    return _ReconciliationTone(
      background: isDark
          ? AppColors.danger.withValues(alpha: 0.14)
          : AppColors.dangerSubtle,
      buttonBackground: isDark ? AppColors.darkSurface : AppColors.surface,
      border: isDark ? AppColors.danger : AppColors.dangerBorder,
      accent: AppColors.balanceNegative,
      text: isDark ? AppColors.darkTextMain : AppColors.dangerText,
    );
  }

  factory _ReconciliationTone.warning(bool isDark) {
    return _ReconciliationTone(
      background: isDark
          ? AppColors.warning.withValues(alpha: 0.14)
          : AppColors.warningSubtle,
      buttonBackground: isDark ? AppColors.darkSurface : AppColors.surface,
      border: isDark ? AppColors.warning : AppColors.warningBorder,
      accent: AppColors.warning,
      text: isDark ? AppColors.darkTextMain : AppColors.warningText,
    );
  }
}

String _money(int amount) {
  return CurrencyFormatter.formatVND(amount.toDouble());
}
