import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/group_debt_entity.dart';
import '../../domain/entities/group_detail_entity.dart';

/// Tab "Công nợ": danh sách nợ đã gom + ma trận ai trả ai.
class GroupDebtsPanel extends StatelessWidget {
  const GroupDebtsPanel({
    super.key,
    required this.detail,
    required this.onPayQr,
    required this.onReviewProof,
    required this.onRemind,
  });

  final GroupDetailEntity detail;
  final ValueChanged<GroupDebtEntity> onPayQr;
  final ValueChanged<GroupDebtEntity> onReviewProof;
  final ValueChanged<GroupDebtEntity> onRemind;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PanelHead(
          title: 'Công nợ cần xử lý',
          subtitle: 'Đã được gom theo từng người trong nhóm',
        ),
        const SizedBox(height: 12),

        if (detail.debts.isEmpty)
          const _AllSettledCard()
        else
          for (final debt in detail.debts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DebtCard(
                debt: debt,
                onPayQr: () => onPayQr(debt),
                onReviewProof: () => onReviewProof(debt),
                onRemind: () => onRemind(debt),
              ),
            ),

        if (detail.debtMatrix.isNotEmpty) ...[
          const SizedBox(height: 8),
          _DebtMatrixCard(rows: detail.debtMatrix, total: detail.outstandingTotal),
        ],
      ],
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({
    required this.debt,
    required this.onPayQr,
    required this.onReviewProof,
    required this.onRemind,
  });

  final GroupDebtEntity debt;
  final VoidCallback onPayQr;
  final VoidCallback onReviewProof;
  final VoidCallback onRemind;

  @override
  Widget build(BuildContext context) {
    final iOwe = debt.direction == DebtDirection.iOwe;
    final amountColor = iOwe ? AppColors.balanceNegative : AppColors.balancePositive;

    // Chủ nợ duyệt proof khi có minh chứng, ngược lại chỉ nhắc nợ được.
    final (actionLabel, action) = iOwe
        ? ('Trả QR', onPayQr)
        : debt.hasPendingProof
        ? ('Duyệt proof', onReviewProof)
        : ('Nhắc nợ', onRemind);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySubtle,
              border: Border.all(color: AppColors.primaryBorder),
            ),
            alignment: Alignment.center,
            child: Text(
              debt.initials,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.counterpartName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  debt.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.vndSigned(iOwe ? -debt.amount : debt.amount),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: action,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    actionLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

class _DebtMatrixCard extends StatelessWidget {
  const _DebtMatrixCard({required this.rows, required this.total});

  final List<DebtMatrixRow> rows;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ma trận công nợ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    row.from,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 14, color: AppColors.textSubtle),
                  const SizedBox(width: 8),
                  Text(
                    row.to,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    CurrencyFormatter.vnd(row.amount),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 18, color: AppColors.border),
          Text.rich(
            TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
              children: [
                const TextSpan(text: 'Cần thêm '),
                TextSpan(
                  text: CurrencyFormatter.vnd(total),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const TextSpan(text: ' để nhóm sạch nợ'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllSettledCard extends StatelessWidget {
  const _AllSettledCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.successSubtle,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.successBorder),
      ),
      child: Column(
        children: [
          Text(
            'Nhóm đã sạch nợ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.successText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Không còn khoản nào cần xử lý.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiêu đề chuẩn cho mỗi panel tab của màn chi tiết nhóm.
class _PanelHead extends StatelessWidget {
  const _PanelHead({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => GroupPanelHead(title: title, subtitle: subtitle);
}

/// Head dùng chung cho các panel (có thể kèm nút hành động bên phải).
class GroupPanelHead extends StatelessWidget {
  const GroupPanelHead({super.key, required this.title, required this.subtitle, this.trailing});

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}
