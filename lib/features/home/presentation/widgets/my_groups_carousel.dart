import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

class MyGroupsCarousel extends StatelessWidget {
  const MyGroupsCarousel({
    this.onViewAll,
    this.onTapGroup,
    this.onCreateGroup,
    super.key,
  });

  final VoidCallback? onViewAll;
  final void Function(String groupName)? onTapGroup;
  final VoidCallback? onCreateGroup;

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
              'Nhóm của tôi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textMain,
                letterSpacing: -0.2,
              ),
            ),
            InkWell(
              onTap: onViewAll,
              child: Text(
                'Xem tất cả',
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

        // Horizontal scrolling group cards
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _GroupCardItem(
                emoji: '🍜',
                memberCount: 5,
                title: 'Phòng Dev Cty',
                balanceText: '+350.000 đ',
                isPositive: true,
                onTap: () => onTapGroup?.call('Phòng Dev Cty'),
              ),
              const SizedBox(width: 10),
              _GroupCardItem(
                emoji: '🏖',
                memberCount: 8,
                title: 'Du lịch Đà Lạt',
                balanceText: '-120.000 đ',
                onTap: () => onTapGroup?.call('Du lịch Đà Lạt'),
              ),
              const SizedBox(width: 10),
              _GroupCardItem(
                emoji: '🏠',
                memberCount: 3,
                title: 'Nhà Trọ Tân Bình',
                balanceText: '0 đ',
                isNeutral: true,
                onTap: () => onTapGroup?.call('Nhà Trọ Tân Bình'),
              ),
              const SizedBox(width: 10),
              // Add Group Card
              _AddGroupCard(onTap: onCreateGroup),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupCardItem extends StatelessWidget {
  const _GroupCardItem({
    required this.emoji,
    required this.memberCount,
    required this.title,
    required this.balanceText,
    this.isPositive = false,
    this.isNeutral = false,
    this.onTap,
  });

  final String emoji;
  final int memberCount;
  final String title;
  final String balanceText;
  final bool isPositive;
  final bool isNeutral;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);

    final emeraldGreen = const Color(0xFF10B981);
    final dangerRed = const Color(0xFFEF4444);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 142,
        padding: const EdgeInsets.all(12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: Emoji + Member Count Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$memberCount TV',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),

            // Title
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textMain,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Balance
            Text(
              balanceText,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isNeutral
                    ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                    : (isPositive ? emeraldGreen : dangerRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddGroupCard extends StatelessWidget {
  const _AddGroupCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTeal = const Color(0xFF0F766E);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? primaryTeal.withValues(alpha: 0.1)
              : const Color(0xFFF0FDFA).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryTeal.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryTeal.withValues(alpha: 0.15),
              ),
              child: const Center(
                child: Icon(HugeIcons.strokeRoundedAdd01, size: 18, color: Color(0xFF0F766E)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tạo nhóm',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primaryTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
