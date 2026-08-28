import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../settlement/domain/entities/settlement_entities.dart';

class ActionableDebtsSection extends StatefulWidget {
  const ActionableDebtsSection({
    this.payableDebts = const [],
    this.receivableDebts = const [],
    this.pendingProofs = const [],
    this.remindedCooldowns = const {},
    this.isLoading = false,
    this.onViewAll,
    this.onPayQr,
    this.onReviewProof,
    this.onRemind,
    super.key,
  });

  final List<DebtItemEntity> payableDebts;
  final List<DebtItemEntity> receivableDebts;
  final List<ProofDetailEntity> pendingProofs;
  final Map<String, int> remindedCooldowns;
  final bool isLoading;

  final void Function(int selectedTab)? onViewAll;
  final void Function(DebtItemEntity debt)? onPayQr;
  final void Function(ProofDetailEntity proof)? onReviewProof;
  final void Function(DebtItemEntity debt)? onRemind;

  @override
  State<ActionableDebtsSection> createState() => _ActionableDebtsSectionState();
}

class _ActionableDebtsSectionState extends State<ActionableDebtsSection> {
  int _selectedTab = 0; // 0: Cần trả, 1: Cần thu

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTeal = const Color(0xFF0F766E);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    final totalCount = widget.payableDebts.length + widget.receivableDebts.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Khoản nợ cần xử lý',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textMain,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            InkWell(
              onTap: () => widget.onViewAll?.call(_selectedTab),
              child: Text(
                'Xem tất cả ($totalCount)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: primaryTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Segmented Pill Tabs
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabButton(
                title: 'Cần trả (${widget.payableDebts.length})',
                index: 0,
                isDark: isDark,
              ),
              _buildTabButton(
                title: 'Cần thu (${widget.receivableDebts.length})',
                index: 1,
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Debt Items
        if (widget.isLoading) ...[
          _buildSkeletonCard(isDark),
          const SizedBox(height: 8),
          _buildSkeletonCard(isDark),
        ] else if (_selectedTab == 0) ...[
          if (widget.payableDebts.isEmpty)
            _buildEmptyState(
              icon: HugeIcons.strokeRoundedCheckmarkBadge01,
              title: 'Không có khoản nợ nào cần trả',
              subtitle: 'Bạn đã hoàn tất tất cả các khoản thanh toán',
              isDark: isDark,
            )
          else ...[
            for (int i = 0; i < widget.payableDebts.take(3).length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _DebtCardItem(
                name: widget.payableDebts[i].creditorName,
                avatarUrl: widget.payableDebts[i].creditorAvatar,
                contextDesc: '${widget.payableDebts[i].groupName} • ${widget.payableDebts[i].billTitle}',
                amount: '-${CurrencyFormatter.formatVND(widget.payableDebts[i].amount)}',
                isPayable: true,
                onAction: () => widget.onPayQr?.call(widget.payableDebts[i]),
              ),
            ],
          ],
        ] else ...[
          if (widget.receivableDebts.isEmpty)
            _buildEmptyState(
              icon: HugeIcons.strokeRoundedCoins01,
              title: 'Không có khoản nào cần thu',
              subtitle: 'Mọi người đã thanh toán đầy đủ cho bạn',
              isDark: isDark,
            )
          else ...[
            for (int i = 0; i < widget.receivableDebts.take(3).length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              () {
                final debt = widget.receivableDebts[i];
                final isPendingProof = debt.status == DebtStatus.pendingConfirmation;
                ProofDetailEntity? matchedProof;
                if (isPendingProof) {
                  matchedProof = widget.pendingProofs
                      .where(
                        (p) =>
                            p.paymentId == debt.paymentId ||
                            (p.groupId == debt.groupId && p.debtorName == debt.debtorName),
                      )
                      .firstOrNull;
                }

                final cooldown = widget.remindedCooldowns[debt.id] ??
                    (debt.lastRemindedAt != null
                        ? ((24 * 3600) -
                            DateTime.now()
                                .difference(debt.lastRemindedAt!)
                                .inSeconds)
                        : 0);

                return _DebtCardItem(
                  name: debt.debtorName,
                  avatarUrl: debt.debtorAvatar,
                  contextDesc: '${debt.groupName} • ${debt.billTitle}',
                  amount: '+${CurrencyFormatter.formatVND(debt.amount)}',
                  isPayable: false,
                  isReviewProof: isPendingProof,
                  cooldownSeconds: cooldown > 0 ? cooldown : 0,
                  onAction: () {
                    if (isPendingProof && matchedProof != null) {
                      widget.onReviewProof?.call(matchedProof);
                    } else if (isPendingProof && widget.onViewAll != null) {
                      widget.onViewAll?.call(1);
                    } else {
                      widget.onRemind?.call(debt);
                    }
                  },
                );
              }(),
            ],
          ],
        ],
      ],
    );
  }

  Widget _buildTabButton({
    required String title,
    required int index,
    required bool isDark,
  }) {
    final isSelected = _selectedTab == index;
    final primaryTeal = const Color(0xFF0F766E);

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? (isDark ? Colors.white : primaryTeal)
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0F766E), size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: textMain,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 120,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtCardItem extends StatelessWidget {
  const _DebtCardItem({
    required this.name,
    this.avatarUrl,
    required this.contextDesc,
    required this.amount,
    required this.isPayable,
    this.isReviewProof = false,
    this.cooldownSeconds = 0,
    this.onAction,
  });

  final String name;
  final String? avatarUrl;
  final String contextDesc;
  final String amount;
  final bool isPayable;
  final bool isReviewProof;
  final int cooldownSeconds;
  final VoidCallback? onAction;

  static String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final emeraldGreen = const Color(0xFF10B981);
    final dangerRed = const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar box
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPayable
                    ? const [Color(0xFFFEF3C7), Color(0xFFFDE68A)]
                    : const [Color(0xFFE0E7FF), Color(0xFFC7D2FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        avatarUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Text(
                          _getInitials(name),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isPayable ? const Color(0xFFB45309) : const Color(0xFF4338CA),
                          ),
                        ),
                      ),
                    )
                  : Text(
                      _getInitials(name),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isPayable ? const Color(0xFFB45309) : const Color(0xFF4338CA),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and context
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contextDesc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Amount and Action button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isPayable ? dangerRed : emeraldGreen,
                ),
              ),
              const SizedBox(height: 4),
              if (isPayable)
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onAction,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(HugeIcons.strokeRoundedQrCode, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Trả QR',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else if (isReviewProof)
                InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(HugeIcons.strokeRoundedInvoice02, size: 12, color: Color(0xFFB45309)),
                        SizedBox(width: 4),
                        Text(
                          'Duyệt proof',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cooldownSeconds > 0
                          ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cooldownSeconds > 0
                              ? HugeIcons.strokeRoundedClock01
                              : HugeIcons.strokeRoundedNotification03,
                          size: 12,
                          color: textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cooldownSeconds > 0
                              ? TimeFormatter.formatRemainingCooldown(cooldownSeconds)
                              : 'Nhắc nợ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                          ),
                        ),
                      ],
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
