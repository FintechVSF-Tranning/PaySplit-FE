import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

class ActionableDebtsSection extends StatefulWidget {
  const ActionableDebtsSection({
    this.onViewAll,
    this.onPayQr,
    this.onReviewProof,
    this.onRemind,
    super.key,
  });

  final VoidCallback? onViewAll;
  final void Function(String name, String amount, String context)? onPayQr;
  final void Function(String name, String amount)? onReviewProof;
  final void Function(String name)? onRemind;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Khoản nợ cần xử lý',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textMain,
                letterSpacing: -0.2,
              ),
            ),
            InkWell(
              onTap: widget.onViewAll,
              child: Text(
                'Xem tất cả (5)',
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
              _buildTabButton(title: 'Cần trả (2)', index: 0, isDark: isDark),
              _buildTabButton(title: 'Cần thu (3)', index: 1, isDark: isDark),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Debt Items
        if (_selectedTab == 0) ...[
          _DebtCardItem(
            emoji: '🍕',
            emojiBg: const Color(0xFFFEF3C7),
            name: 'Minh Trần',
            contextDesc: 'Cơm trưa phòng Dev • Lẩu gà',
            amount: '-120.000 đ',
            isPayable: true,
            onAction: () => widget.onPayQr?.call('Minh Trần', '120.000 đ', 'Cơm trưa phòng Dev'),
          ),
          const SizedBox(height: 8),
          _DebtCardItem(
            emoji: '🏖',
            emojiBg: const Color(0xFFE0E7FF),
            name: 'Hải Đăng',
            contextDesc: 'Du lịch Đà Lạt • Xe Limousine',
            amount: '-280.000 đ',
            isPayable: true,
            onAction: () => widget.onPayQr?.call('Hải Đăng', '280.000 đ', 'Du lịch Đà Lạt'),
          ),
        ] else ...[
          _DebtCardItem(
            emoji: '🍕',
            emojiBg: const Color(0xFFFEF3C7),
            name: 'Trần Lâm',
            contextDesc: 'Cơm trưa phòng Dev • Đã gửi bill',
            amount: '+120.000 đ',
            isPayable: false,
            isReviewProof: true,
            onAction: () => widget.onReviewProof?.call('Trần Lâm', '120.000 đ'),
          ),
          const SizedBox(height: 8),
          _DebtCardItem(
            emoji: '🍜',
            emojiBg: const Color(0xFFDCFCE7),
            name: 'Nguyễn Khoa',
            contextDesc: 'Phở sáng Cty • Chờ chuyển',
            amount: '+80.000 đ',
            isPayable: false,
            onAction: () => widget.onRemind?.call('Nguyễn Khoa'),
          ),
          const SizedBox(height: 8),
          _DebtCardItem(
            emoji: '🏖',
            emojiBg: const Color(0xFFE0E7FF),
            name: 'Bảo Hưng',
            contextDesc: 'Du lịch Đà Lạt • Homestay',
            amount: '+1.050.000 đ',
            isPayable: false,
            onAction: () => widget.onRemind?.call('Bảo Hưng'),
          ),
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
}

class _DebtCardItem extends StatelessWidget {
  const _DebtCardItem({
    required this.emoji,
    required this.emojiBg,
    required this.name,
    required this.contextDesc,
    required this.amount,
    required this.isPayable,
    this.isReviewProof = false,
    this.onAction,
  });

  final String emoji;
  final Color emojiBg;
  final String name;
  final String contextDesc;
  final String amount;
  final bool isPayable;
  final bool isReviewProof;
  final VoidCallback? onAction;

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
          // Emoji avatar box
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: emojiBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
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
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(HugeIcons.strokeRoundedNotification03, size: 12, color: textMuted),
                        const SizedBox(width: 4),
                        Text(
                          'Nhắc nợ',
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
