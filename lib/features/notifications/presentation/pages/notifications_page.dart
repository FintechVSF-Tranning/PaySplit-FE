import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/notification_route_resolver.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notifications_notifier.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final ScrollController _scrollController = ScrollController();
  int _selectedFilterIndex = 0; // 0: Tất cả, 1: Chưa đọc

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NotificationsState>(notificationsProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    const primaryTeal = Color(0xFF0F766E);

    // Lọc theo tab
    final displayedItems = _selectedFilterIndex == 1
        ? state.items.where((n) => !n.isRead).toList()
        : state.items;

    // Gom nhóm theo ngày
    final grouped = _groupByDate(displayedItems);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Icon(
                        HugeIcons.strokeRoundedArrowLeft01,
                        color: textMain,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Thông báo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textMain,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (state.unreadCount > 0) ...[
                    InkWell(
                      onTap: () => notifier.markAllAsRead(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primaryTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Đọc tất cả',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryTeal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 2. Segmented Filter Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _FilterTabButton(
                    label: 'Tất cả (${state.items.length})',
                    isSelected: _selectedFilterIndex == 0,
                    onTap: () => setState(() => _selectedFilterIndex = 0),
                  ),
                  const SizedBox(width: 8),
                  _FilterTabButton(
                    label: 'Chưa đọc (${state.unreadCount})',
                    isSelected: _selectedFilterIndex == 1,
                    hasUnreadBadge: state.unreadCount > 0,
                    onTap: () => setState(() => _selectedFilterIndex = 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 3. Notification List with Pull-to-Refresh & Infinite Scroll
            Expanded(
              child: state.isLoading && state.items.isEmpty
                  ? _buildLoadingSkeleton(isDark)
                  : RefreshIndicator(
                      color: primaryTeal,
                      onRefresh: () => notifier.refresh(),
                      child: displayedItems.isEmpty
                          ? _buildEmptyState(isDark, _selectedFilterIndex == 1)
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                              itemCount:
                                  grouped.keys.length +
                                  (state.isLoadingMore ? 1 : 1),
                              itemBuilder: (context, index) {
                                final keys = grouped.keys.toList();

                                // Spinner ở cuối danh sách khi đang tải thêm hoặc thông báo đã hết
                                if (index == keys.length) {
                                  if (state.isLoadingMore) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: primaryTeal,
                                          ),
                                        ),
                                      ),
                                    );
                                  } else if (!state.hasMore &&
                                      displayedItems.length >= 10) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 24,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '— Bạn đã xem hết thông báo —',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: textMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }

                                final groupTitle = keys[index];
                                final notifs = grouped[groupTitle]!;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 14,
                                        bottom: 8,
                                        left: 4,
                                      ),
                                      child: Text(
                                        groupTitle.toUpperCase(),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: textMuted,
                                        ),
                                      ),
                                    ),
                                    for (final notif in notifs) ...[
                                      _NotificationCard(
                                        notification: notif,
                                        isDark: isDark,
                                        onTap: () {
                                          if (!notif.isRead) {
                                            notifier.markAsRead(notif.id);
                                          }
                                          _handleNotificationAction(
                                            context,
                                            notif,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ],
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationAction(
    BuildContext context,
    NotificationEntity notif,
  ) {
    final resolved = NotificationRouteResolver.resolve(
      type: notif.type,
      payload: notif.payload,
    );
    if (resolved != null) {
      context.push(resolved.path, extra: resolved.extra);
      return;
    }

    final payload = notif.payload;
    final billId = (payload['bill_id'] ?? payload['billId']) as String?;
    final groupId = (payload['group_id'] ?? payload['groupId']) as String?;
    final paymentId =
        (payload['payment_id'] ?? payload['paymentId']) as String?;

    if (billId != null && billId.isNotEmpty) {
      context.push(
        AppRoutes.billDetail,
        extra: {
          'billId': billId,
          if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
        },
      );
    } else if (paymentId != null && paymentId.isNotEmpty) {
      context.push(AppRoutes.settlement);
    } else if (groupId != null && groupId.isNotEmpty) {
      context.push(AppRoutes.groupDetail(groupId));
    }
  }

  Map<String, List<NotificationEntity>> _groupByDate(
    List<NotificationEntity> list,
  ) {
    final Map<String, List<NotificationEntity>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final item in list) {
      final date = item.createdAt;
      final itemDay = DateTime(date.year, date.month, date.day);
      final key = itemDay.isAtSameMomentAs(today) ? 'Hôm nay' : 'Trước đó';

      grouped.putIfAbsent(key, () => []).add(item);
    }

    return grouped;
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(5, (index) => _buildSkeletonItem(isDark)),
    );
  }

  Widget _buildSkeletonItem(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
            width: 38,
            height: 38,
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
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
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

  Widget _buildEmptyState(bool isDark, bool isFilteredUnread) {
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0F766E).withValues(alpha: 0.1),
              ),
              child: const Center(
                child: Icon(
                  HugeIcons.strokeRoundedNotification01,
                  size: 36,
                  color: Color(0xFF0F766E),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFilteredUnread
                  ? 'Không có thông báo chưa đọc'
                  : 'Hộp thư thông báo trống',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFilteredUnread
                  ? 'Tuyệt vời! Bạn đã xử lý và đọc hết mọi thông báo.'
                  : 'Các thông báo nhắc nợ, chia bill và thanh toán sẽ xuất hiện tại đây.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
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

class _FilterTabButton extends StatelessWidget {
  const _FilterTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.hasUnreadBadge = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool hasUnreadBadge;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryTeal = Color(0xFF0F766E);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryTeal
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? primaryTeal
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
              ),
            ),
            if (hasUnreadBadge && !isSelected) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  final NotificationEntity notification;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? (notification.isRead
              ? const Color(0xFF1E293B)
              : const Color(0xFF1E293B).withValues(alpha: 0.8))
        : (notification.isRead ? Colors.white : const Color(0xFFF0FDFA));

    final border = isDark
        ? (notification.isRead
              ? const Color(0xFF334155)
              : const Color(0xFF0F766E).withValues(alpha: 0.5))
        : (notification.isRead
              ? const Color(0xFFE2E8F0)
              : const Color(0xFF99F6E4));

    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    const primaryTeal = Color(0xFF0F766E);

    final style = _getStyle(notification.type);
    final timeAgo = _formatTimeAgo(notification.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: border,
            width: notification.isRead ? 1 : 1.2,
          ),
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
            // Icon Hugeicons
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? style.color.withValues(alpha: 0.15) : style.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(style.icon, size: 19, color: style.color),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.displayTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead) ...[
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryTeal,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.displayBody,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
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
      ),
    );
  }

  static ({IconData icon, Color color, Color bg}) _getStyle(String type) {
    switch (type) {
      case 'debt_reminder':
      case 'debt_reminded':
      case 'payment_reminder':
        return (
          icon: HugeIcons.strokeRoundedNotification03,
          color: const Color(0xFFD97706),
          bg: const Color(0xFFFEF3C7),
        );
      case 'stalled_payment_reminder':
      case 'payment_stalled_confirmation':
        return (
          icon: HugeIcons.strokeRoundedClock01,
          color: const Color(0xFFD97706),
          bg: const Color(0xFFFEF3C7),
        );
      case 'bill_finalized':
      case 'created_bill':
      case 'new_bill':
        return (
          icon: HugeIcons.strokeRoundedInvoice01,
          color: const Color(0xFF0F766E),
          bg: const Color(0xFFF0FDFA),
        );
      case 'bill_updated':
        return (
          icon: HugeIcons.strokeRoundedEdit02,
          color: const Color(0xFF0F766E),
          bg: const Color(0xFFF0FDFA),
        );
      case 'bill_bulk_finalize_completed':
        return (
          icon: HugeIcons.strokeRoundedReceiptDollar,
          color: const Color(0xFF0F766E),
          bg: const Color(0xFFF0FDFA),
        );
      case 'payment_created':
        return (
          icon: HugeIcons.strokeRoundedQrCode,
          color: const Color(0xFF0F766E),
          bg: const Color(0xFFF0FDFA),
        );
      case 'proof_submitted':
      case 'payment_submitted':
        return (
          icon: HugeIcons.strokeRoundedImage01,
          color: const Color(0xFF2563EB),
          bg: const Color(0xFFEFF6FF),
        );
      case 'payment_confirmed':
        return (
          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
          color: const Color(0xFF059669),
          bg: const Color(0xFFECFDF5),
        );
      case 'payment_rejected':
        return (
          icon: HugeIcons.strokeRoundedCancelCircle,
          color: const Color(0xFFDC2626),
          bg: const Color(0xFFFEF2F2),
        );
      case 'group_invite':
      case 'group_invitation':
      case 'member_joined':
        return (
          icon: HugeIcons.strokeRoundedUserGroup,
          color: const Color(0xFF7C3AED),
          bg: const Color(0xFFF5F3FF),
        );
      default:
        return (
          icon: HugeIcons.strokeRoundedNotification01,
          color: const Color(0xFF64748B),
          bg: const Color(0xFFF1F5F9),
        );
    }
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
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
