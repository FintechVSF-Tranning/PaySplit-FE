import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/group_entity.dart';

/// Banner số dư riêng của tôi trong nhóm — 3 trạng thái màu theo spec.
class GroupBalanceBanner extends StatelessWidget {
  const GroupBalanceBanner({super.key, required this.group, required this.onSettle});

  final GroupEntity group;

  /// Chỉ được gọi khi tôi đang nợ; trạng thái khác nút bị disable.
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, copy) = switch (group.balanceState) {
      GroupBalanceState.positive => (
        AppColors.balancePositiveBg,
        AppColors.successBorder,
        AppColors.balancePositive,
        'Bạn được nhận lại',
      ),
      GroupBalanceState.negative => (
        AppColors.balanceNegativeBg,
        AppColors.dangerBorder,
        AppColors.balanceNegative,
        'Bạn cần trả nợ',
      ),
      GroupBalanceState.settled => (
        AppColors.surfaceSubtle,
        AppColors.border,
        AppColors.textMain,
        'Đã cân bằng sạch nợ',
      ),
    };

    final isDebt = group.balanceState == GroupBalanceState.negative;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Số dư của bạn trong nhóm',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  group.myBalance == 0
                      ? CurrencyFormatter.vnd(0)
                      : CurrencyFormatter.vndSigned(group.myBalance),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  copy,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _BalanceActionButton(
            label: isDebt ? 'Trả QR' : 'Đã cân bằng',
            isEnabled: isDebt,
            onTap: onSettle,
          ),
        ],
      ),
    );
  }
}

class _BalanceActionButton extends StatelessWidget {
  const _BalanceActionButton({required this.label, required this.isEnabled, required this.onTap});

  final String label;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1 : 0.55,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: isEnabled ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isEnabled ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
