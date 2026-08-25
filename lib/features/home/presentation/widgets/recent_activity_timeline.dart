import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecentActivityTimeline extends StatelessWidget {
  const RecentActivityTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoạt động gần đây',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textMain,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        const _ActivityCardItem(
          icon: '🧾',
          iconBg: Color(0xFFECFDF5),
          iconColor: Color(0xFF10B981),
          richTextParts: [
            TextSpan(text: 'Hóa đơn '),
            TextSpan(
              text: '"Lẩu gà lá é"',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' đã chốt và chia đều ('),
            TextSpan(
              text: '529.200 đ',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ')'),
          ],
          timeAgo: '2 giờ trước • Đã chia bill',
        ),
        const SizedBox(height: 8),
        const _ActivityCardItem(
          icon: '₫',
          iconBg: Color(0xFFFEF3C7),
          iconColor: Color(0xFFD97706),
          richTextParts: [
            TextSpan(
              text: 'Minh Trần',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' đã nộp biên lai chuyển khoản '),
            TextSpan(
              text: '120.000 đ',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
          timeAgo: '5 phút trước • Chờ duyệt proof',
        ),
      ],
    );
  }
}

class _ActivityCardItem extends StatelessWidget {
  const _ActivityCardItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.richTextParts,
    required this.timeAgo,
  });

  final String icon;
  final Color iconBg;
  final Color iconColor;
  final List<TextSpan> richTextParts;
  final String timeAgo;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: textMain,
                      height: 1.4,
                    ),
                    children: richTextParts,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeAgo,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: textMuted,
                    fontWeight: FontWeight.w500,
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
