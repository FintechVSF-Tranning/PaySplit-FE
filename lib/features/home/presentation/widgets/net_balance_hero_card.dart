import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

class NetBalanceHeroCard extends StatelessWidget {
  const NetBalanceHeroCard({
    this.netAmount = '+850.000 đ',
    this.receivableAmount = '+1.250.000 đ',
    this.payableAmount = '-400.000 đ',
    this.isPositive = true,
    this.isBalanced = false,
    this.onPayVietQr,
    this.onScanBill,
    this.onCreateGroup,
    super.key,
  });

  final String netAmount;
  final String receivableAmount;
  final String payableAmount;
  final bool isPositive;
  final bool isBalanced;
  final VoidCallback? onPayVietQr;
  final VoidCallback? onScanBill;
  final VoidCallback? onCreateGroup;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final breakdownBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9);
    final primaryTeal = const Color(0xFF0F766E);
    final emeraldGreen = const Color(0xFF10B981);
    final dangerRed = const Color(0xFFEF4444);

    final String badgeText;
    final Color badgeBg;
    final Color badgeBorder;
    final Color badgeTextColor;
    final IconData badgeIcon;

    if (isBalanced) {
      badgeText = 'Đã cân bằng';
      badgeBg = isDark ? const Color(0xFF132E27) : const Color(0xFFECFDF5);
      badgeBorder = const Color(0xFFA7F3D0);
      badgeTextColor = const Color(0xFF059669);
      badgeIcon = HugeIcons.strokeRoundedCheckmarkCircle02;
    } else if (isPositive) {
      badgeText = 'Bạn được nhận lại';
      badgeBg = const Color(0xFFECFDF5);
      badgeBorder = const Color(0xFFA7F3D0);
      badgeTextColor = const Color(0xFF059669);
      badgeIcon = HugeIcons.strokeRoundedCheckmarkCircle02;
    } else {
      badgeText = 'Bạn cần trả';
      badgeBg = const Color(0xFFFEF2F2);
      badgeBorder = const Color(0xFFFECACA);
      badgeTextColor = dangerRed;
      badgeIcon = HugeIcons.strokeRoundedAlertCircle;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : primaryTeal.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Title + Status Pill Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'TỔNG SỐ DƯ CÔNG NỢ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      badgeIcon,
                      size: 13,
                      color: badgeTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Amount
          Text(
            netAmount,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: isBalanced
                  ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))
                  : (isPositive ? primaryTeal : dangerRed),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Breakdown Box (2 columns)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: breakdownBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đang cho nợ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        receivableAmount,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: emeraldGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: borderColor,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đang nợ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        payableAmount,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: dangerRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3 Quick Action Buttons
          Row(
            children: [
              // 1. Trả VietQR (Primary Gradient)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryTeal.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onPayVietQr,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              HugeIcons.strokeRoundedQrCode,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Trả VietQR',
                              style: GoogleFonts.plusJakartaSans(
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
                ),
              ),
              const SizedBox(width: 8),

              // 2. Quét bill OCR
              Expanded(
                child: _QuickActionButton(
                  icon: HugeIcons.strokeRoundedCamera01,
                  label: 'Quét bill',
                  onTap: onScanBill,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),

              // 3. Tạo nhóm
              Expanded(
                child: _QuickActionButton(
                  icon: HugeIcons.strokeRoundedUserGroup,
                  label: 'Tạo nhóm',
                  onTap: onCreateGroup,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final border = isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0);
    final text = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final iconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF0F766E);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
