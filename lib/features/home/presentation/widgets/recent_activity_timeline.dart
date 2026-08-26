import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/home_activities_provider.dart';

class RecentActivityTimeline extends ConsumerWidget {
  const RecentActivityTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    final activitiesAsync = ref.watch(homeActivitiesProvider);

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
        activitiesAsync.when(
          loading: () => Column(
            children: [
              _buildSkeletonCard(isDark),
              const SizedBox(height: 8),
              _buildSkeletonCard(isDark),
            ],
          ),
          error: (error, stackTrace) => _buildEmptyState(isDark),
          data: (activities) {
            if (activities.isEmpty) {
              return _buildEmptyState(isDark);
            }

            return Column(
              children: [
                for (int i = 0; i < activities.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final act = activities[i];
                      final style = _getStyleForActionType(act.actionType);
                      final timeAgo = _formatTimeAgo(act.createdAt);

                      return _ActivityCardItem(
                        icon: style.icon,
                        iconBg: style.bg,
                        iconColor: style.color,
                        description: act.description,
                        timeAgo: '$timeAgo • ${style.tag}',
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
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
                  width: 100,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
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

  Widget _buildEmptyState(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Center(
        child: Column(
          children: [
            const Text('🌱', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              'Chưa có hoạt động mới',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Các hoạt động chia bill, thanh toán và thành viên mới sẽ hiển thị tại đây.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    }
    return '${dateTime.day}/${dateTime.month}';
  }

  static ({String icon, Color bg, Color color, String tag})
  _getStyleForActionType(String actionType) {
    switch (actionType) {
      case 'bill_finalized':
      case 'bill_created':
      case 'bill_closed':
        return (
          icon: '🧾',
          bg: const Color(0xFFECFDF5),
          color: const Color(0xFF10B981),
          tag: 'Hóa đơn',
        );
      case 'proof_submitted':
      case 'payment_settled':
      case 'payment_confirmed':
        return (
          icon: '💳',
          bg: const Color(0xFFEFF6FF),
          color: const Color(0xFF3B82F6),
          tag: 'Thanh toán',
        );
      case 'member_joined':
      case 'member_removed':
        return (
          icon: '👥',
          bg: const Color(0xFFF5F3FF),
          color: const Color(0xFF8B5CF6),
          tag: 'Thành viên',
        );
      case 'group_created':
      case 'invite_created':
      case 'captain_transferred':
      case 'group_renamed':
      default:
        return (
          icon: '🎉',
          bg: const Color(0xFFFEF3C7),
          color: const Color(0xFFD97706),
          tag: 'Nhóm',
        );
    }
  }
}

class _ActivityCardItem extends StatelessWidget {
  const _ActivityCardItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.description,
    required this.timeAgo,
  });

  final String icon;
  final Color iconBg;
  final Color iconColor;
  final String description;
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
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: textMain,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
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
