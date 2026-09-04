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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final (bg, border, fg, copy) = switch (group.balanceState) {
      GroupBalanceState.positive => (
        isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : AppColors.balancePositiveBg,
        isDark ? const Color(0xFF059669).withValues(alpha: 0.4) : AppColors.successBorder,
        isDark ? const Color(0xFF34D399) : AppColors.balancePositive,
        'Bạn được nhận lại',
      ),
      GroupBalanceState.negative => (
        isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.35) : AppColors.balanceNegativeBg,
        isDark ? const Color(0xFFDC2626).withValues(alpha: 0.4) : AppColors.dangerBorder,
        isDark ? const Color(0xFFF87171) : AppColors.balanceNegative,
        'Bạn cần trả nợ',
      ),
      GroupBalanceState.settled => (
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
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
                    color: textMuted,
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
                    color: textMuted,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF14B8A6) : AppColors.primary;
    final disabledBg = isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : AppColors.surface;
    final disabledBorder = isDark ? const Color(0xFF475569) : AppColors.border;
    final disabledText = isDark ? const Color(0xFF94A3B8) : AppColors.textMuted;

    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isEnabled ? primaryColor : disabledBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: isEnabled ? primaryColor : disabledBorder),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isEnabled ? Colors.white : disabledText,
            ),
          ),
        ),
      ),
    );
  }
}
