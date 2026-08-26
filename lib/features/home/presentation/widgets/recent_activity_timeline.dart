import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/home_activity_entity.dart';
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          ],
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
                  _ActivityCardItem(
                    activity: activities[i],
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
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
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
}

class _ActivityCardItem extends StatelessWidget {
  const _ActivityCardItem({
    required this.activity,
  });

  final HomeActivityEntity activity;

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

  ({
    String actionTitle,
    String? highlightedText,
    IconData actionIcon,
    Color iconColor,
    Color iconBgColor,
  }) _parseActivityDisplay() {
    final actor = activity.actorName.isNotEmpty ? activity.actorName : 'Thành viên';
    final amount = activity.amount;
    final formattedAmount = amount != null && amount > 0 ? CurrencyFormatter.formatVND(amount.toDouble()) : null;

    switch (activity.actionType) {
      case 'finalized_bill':
      case 'bill_finalized':
      case 'bill_closed':
        return (
          actionTitle: '$actor đã chốt sổ hóa đơn',
          highlightedText: formattedAmount != null ? ' ($formattedAmount)' : null,
          actionIcon: HugeIcons.strokeRoundedCheckmarkCircle02,
          iconColor: const Color(0xFF059669),
          iconBgColor: const Color(0xFFECFDF5),
        );

      case 'reviewed_bill':
      case 'bill_reviewed':
        return (
          actionTitle: '$actor đã gửi đối soát hóa đơn',
          highlightedText: null,
          actionIcon: HugeIcons.strokeRoundedFileValidation,
          iconColor: const Color(0xFF2563EB),
          iconBgColor: const Color(0xFFEFF6FF),
        );

      case 'updated_bill':
      case 'bill_updated':
        return (
          actionTitle: '$actor đã cập nhật hóa đơn',
          highlightedText: null,
          actionIcon: HugeIcons.strokeRoundedEdit02,
          iconColor: const Color(0xFFD97706),
          iconBgColor: const Color(0xFFFFFBEB),
        );

      case 'created_bill':
      case 'bill_created':
        return (
          actionTitle: '$actor đã tạo hóa đơn mới',
          highlightedText: null,
          actionIcon: HugeIcons.strokeRoundedPlusSignSquare,
          iconColor: const Color(0xFF0D9488),
          iconBgColor: const Color(0xFFF0FDFA),
        );

      case 'voided_bill':
      case 'bill_voided':
        return (
          actionTitle: '$actor đã huỷ hóa đơn',
          highlightedText: null,
          actionIcon: HugeIcons.strokeRoundedDelete02,
          iconColor: const Color(0xFFDC2626),
          iconBgColor: const Color(0xFFFEF2F2),
        );

      case 'payment_submitted':
      case 'proof_submitted':
        return (
          actionTitle: '$actor đã gửi minh chứng thanh toán',
          highlightedText: formattedAmount != null ? ' ($formattedAmount)' : null,
          actionIcon: HugeIcons.strokeRoundedInvoice,
          iconColor: const Color(0xFF2563EB),
          iconBgColor: const Color(0xFFEFF6FF),
        );

      case 'payment_confirmed':
      case 'payment_settled':
        return (
          actionTitle: '$actor đã xác nhận thanh toán',
          highlightedText: formattedAmount != null ? ' ($formattedAmount)' : null,
          actionIcon: HugeIcons.strokeRoundedCreditCard,
          iconColor: const Color(0xFF059669),
          iconBgColor: const Color(0xFFECFDF5),
        );

      case 'debt_reminded':
        return (
          actionTitle: '$actor đã gửi lời nhắc thanh toán',
          highlightedText: null,
          actionIcon: HugeIcons.strokeRoundedAlertCircle,
          iconColor: const Color(0xFFD97706),
          iconBgColor: const Color(0xFFFFFBEB),
        );

      case 'member_joined':
        return (
          actionTitle: '$actor đã tham gia nhóm',
          highlightedText: null,
          actionIcon: HugeIcons.strokeRoundedUserAdd01,
          iconColor: const Color(0xFF7C3AED),
          iconBgColor: const Color(0xFFF5F3FF),
        );

      case 'member_removed':
      case 'member_left':
        return (
          actionTitle: '$actor đã rời khỏi nhóm',
          highlightedText: null,
          actionIcon: HugeIcons.strokeRoundedUserRemove01,
          iconColor: const Color(0xFF64748B),
          iconBgColor: const Color(0xFFF1F5F9),
        );

      case 'captain_transferred':
        return (
          actionTitle: '$actor đã chuyển quyền Trưởng nhóm',
          highlightedText: null,
          actionIcon: HugeIcons.strokeRoundedCrown,
          iconColor: const Color(0xFFD97706),
          iconBgColor: const Color(0xFFFFFBEB),
        );

      case 'group_renamed':
        return (
          actionTitle: '$actor đã đổi tên nhóm',
          highlightedText: null,
          actionIcon: HugeIcons.strokeRoundedEdit02,
          iconColor: const Color(0xFF7C3AED),
          iconBgColor: const Color(0xFFF5F3FF),
        );

      default:
        return (
          actionTitle: activity.description.isNotEmpty ? activity.description : '$actor có hoạt động mới',
          highlightedText: null,
          actionIcon: HugeIcons.strokeRoundedNotification01,
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primarySubtle,
        );
    }
  }

  void _handleTap(BuildContext context) {
    if (activity.billId != null && activity.billId!.isNotEmpty) {
      context.push(
        AppRoutes.billDetail,
        extra: {
          'billId': activity.billId,
          'groupId': activity.groupId,
          'groupName': activity.groupName.isNotEmpty ? activity.groupName : 'Chi tiết nhóm',
        },
      );
    } else if (activity.groupId.isNotEmpty) {
      context.go(
        AppRoutes.groupDetail(activity.groupId),
        extra: {
          'groupId': activity.groupId,
          'groupName': activity.groupName.isNotEmpty ? activity.groupName : 'Chi tiết nhóm',
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final displayInfo = _parseActivityDisplay();
    final timeAgo = _formatTimeAgo(activity.createdAt);
    final groupLabel = activity.groupName.isNotEmpty ? activity.groupName : 'Nhóm';

    final initials = activity.actorName.isNotEmpty
        ? activity.actorName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'TV';

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(context),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar with Action Badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: isDark ? const Color(0xFF334155) : AppColors.primarySubtle,
                      backgroundImage: activity.actorAvatarUrl != null && activity.actorAvatarUrl!.isNotEmpty
                          ? NetworkImage(activity.actorAvatarUrl!)
                          : null,
                      child: activity.actorAvatarUrl == null || activity.actorAvatarUrl!.isEmpty
                          ? Text(
                              initials,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isDark ? displayInfo.iconColor.withValues(alpha: 0.2) : displayInfo.iconBgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            displayInfo.actionIcon,
                            size: 11,
                            color: displayInfo.iconColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: textMain,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                          children: [
                            TextSpan(text: displayInfo.actionTitle),
                            if (displayInfo.highlightedText != null)
                              TextSpan(
                                text: displayInfo.highlightedText,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: displayInfo.iconColor,
                                ),
                              ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            timeAgo,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: textMuted,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              groupLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Arrow indicator
                Icon(
                  HugeIcons.strokeRoundedArrowRight01,
                  size: 16,
                  color: textMuted.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
