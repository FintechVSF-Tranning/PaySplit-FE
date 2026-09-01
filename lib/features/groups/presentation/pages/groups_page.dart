import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/header_wave_painter.dart';
import '../../domain/entities/group_entity.dart';
import '../providers/groups_provider.dart';
import '../widgets/create_group_bottom_sheet.dart';
import '../widgets/group_list_card.dart';
import '../widgets/join_by_link_bottom_sheet.dart';
import '../widgets/group_avatar.dart';

/// Tab "Nhóm" — trung tâm điều phối mọi nhóm chi tiêu của người dùng.
class GroupsPage extends ConsumerStatefulWidget {
  const GroupsPage({super.key});

  @override
  ConsumerState<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends ConsumerState<GroupsPage> {
  /// Tách nhóm đang dùng khỏi nhóm đã khóa hóa đơn để danh sách chính không bị loãng.
  GroupStatus _lifecycle = GroupStatus.active;

  @override
  Widget build(BuildContext context) {
    final groupsState = ref.watch(groupsProvider);
    final groups = groupsState.groups;
    final recentGroups = ref.watch(recentGroupsProvider);

    final activeGroups = groups.where((g) => !g.isClosed).toList();
    final closedGroups = groups.where((g) => g.isClosed).toList();
    final visibleGroups = _lifecycle == GroupStatus.active
        ? activeGroups
        : closedGroups;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkPaper : const Color(0xFFF8FAF9);
    final statusBarHeight = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        onRefresh: () => ref.read(groupsProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  // Dải sóng Teal ở đầu màn hình (cuộn cùng nội dung)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: CustomPaint(
                      size: Size(double.infinity, 190 + statusBarHeight),
                      painter: HeaderWavePainter(isDark: isDark),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12 + statusBarHeight,
                      16,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(groupCount: groups.length),
                        const SizedBox(height: 18),

                        // Hàng ngang 2 nút tham gia nhóm
                        Row(
                          children: [
                            Expanded(
                              child: _JoinActionTile(
                                icon: HugeIcons.strokeRoundedLink01,
                                label: 'Nhập link vào nhóm',
                                onTap: () => _joinByLink(context, ref),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _JoinActionTile(
                                icon: HugeIcons.strokeRoundedQrCode,
                                label: 'Quét QR vào nhóm',
                                onTap: () => _joinByQr(context, ref),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        AppButton(
                          label: 'Tạo nhóm chi tiêu mới',
                          variant: AppButtonVariant.gradient,
                          icon: const Icon(
                            HugeIcons.strokeRoundedAdd01,
                            size: 18,
                            color: Colors.white,
                          ),
                          onPressed: () => _createGroup(context, ref),
                        ),
                        const SizedBox(height: 24),

                        if (recentGroups.isNotEmpty) ...[
                          _SectionTitle(
                            title: 'Nhóm gần đây',
                            trailing: 'Lịch sử truy cập',
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 44,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: recentGroups.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) => _RecentGroupChip(
                                group: recentGroups[index],
                                onTap: () =>
                                    _openDetail(context, recentGroups[index]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        _SectionTitle(
                          title: 'Nhóm của tôi',
                          trailing: '${visibleGroups.length} nhóm',
                        ),
                        const SizedBox(height: 10),
                        _LifecycleTabs(
                          current: _lifecycle,
                          activeCount: activeGroups.length,
                          closedCount: closedGroups.length,
                          onChanged: (value) {
                            HapticFeedback.selectionClick();
                            setState(() => _lifecycle = value);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (groupsState.isLoading && groups.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (groupsState.failure != null && groups.isEmpty)
              SliverToBoxAdapter(
                child: _GroupsErrorState(
                  message: groupsState.failure!.message,
                  onRetry: () => ref.read(groupsProvider.notifier).refresh(),
                ),
              )
            else if (groups.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyGroupsState(
                  onCreate: () => _createGroup(context, ref),
                ),
              )
            else if (visibleGroups.isEmpty)
              const SliverToBoxAdapter(child: _EmptyClosedState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                sliver: SliverList.separated(
                  itemCount: visibleGroups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => GroupListCard(
                    group: visibleGroups[index],
                    onTap: () => _openDetail(context, visibleGroups[index]),
                  ),
                ),
              ),

            // Backend phân trang 20 nhóm mỗi lần; thiếu chỗ này thì người
            // có nhiều nhóm không bao giờ thấy nhóm thứ 21.
            if (groupsState.nextCursor != null && groups.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: OutlinedButton(
                    onPressed: groupsState.isLoadingMore
                        ? null
                        : () => ref.read(groupsProvider.notifier).loadMore(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: groupsState.isLoadingMore
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Tải thêm nhóm',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, GroupEntity group) {
    context.push(AppRoutes.groupDetail(group.id), extra: group);
  }

  Future<void> _createGroup(BuildContext context, WidgetRef ref) async {
    final group = await CreateGroupBottomSheet.show(context);
    if (group == null || !context.mounted) return;

    // Tạo nhóm xong đi thẳng sang màn hình thêm thành viên.
    await context.push(AppRoutes.addMembers(group.id), extra: group);
  }

  Future<void> _joinByLink(BuildContext context, WidgetRef ref) async {
    final group = await JoinByLinkBottomSheet.show(context);
    if (group == null || !context.mounted) return;
    await _join(context, ref, group);
  }

  Future<void> _joinByQr(BuildContext context, WidgetRef ref) async {
    final group = await context.push<GroupEntity>(AppRoutes.scanGroupQr);
    if (group == null || !context.mounted) return;
    await _join(context, ref, group);
  }

  /// Sheet xem trước chỉ trả về thông tin hiển thị kèm mã mời; việc tham gia
  /// thật sự do `POST /groups/join` thực hiện, sau đó danh sách được tải lại.
  Future<void> _join(
    BuildContext context,
    WidgetRef ref,
    GroupEntity group,
  ) async {
    final code = group.inviteCode;
    if (code == null) return;
    final failure = await ref
        .read(groupsProvider.notifier)
        .joinGroupByCode(code);
    if (!context.mounted) return;
    if (failure != null) {
      showErrorSnackBar(context, failure.message);
      return;
    }
    showSuccessSnackBar(context, 'Đã tham gia nhóm ${group.name}');
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.groupCount});

  final int groupCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Nút quay lại — đồng bộ với header của tab Cài đặt và Hóa đơn.
        InkWell(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(
              HugeIcons.strokeRoundedArrowLeft01,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nhóm chi tiêu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bạn đang tham gia $groupCount nhóm',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => showComingSoonSnackBar(context, 'Tìm kiếm nhóm'),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(
              HugeIcons.strokeRoundedSearch01,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Ô hành động tham gia nhóm — nền trắng/slate nổi trên dải sóng Teal.
class _JoinActionTile extends StatelessWidget {
  const _JoinActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final iconBg = isDark
        ? const Color(0xFF0F766E).withValues(alpha: 0.25)
        : AppColors.primarySubtle;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDark ? const Color(0xFF14B8A6) : AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: textMain,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: textMain,
            letterSpacing: -0.2,
          ),
        ),
        Text(
          trailing,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}

class _RecentGroupChip extends StatelessWidget {
  const _RecentGroupChip({required this.group, required this.onTap});

  final GroupEntity group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSubtle = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GroupAvatar(group: group, size: 26),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                  ),
                ),
                Text(
                  group.lastActivityAt == null
                      ? ''
                      : formatRelativeTime(group.lastActivityAt!),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: textSubtle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGroupsState extends StatelessWidget {
  const _EmptyGroupsState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final iconBg = isDark
        ? const Color(0xFF0F766E).withValues(alpha: 0.25)
        : AppColors.primarySubtle;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: DottedBorderBox(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                HugeIcons.strokeRoundedUserGroup,
                size: 28,
                color: isDark ? const Color(0xFF14B8A6) : AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Chưa có nhóm nào',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textMain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tạo nhóm đầu tiên để bắt đầu chia hóa đơn,\nhoặc dùng link/QR mời từ bạn bè.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            AppButton(label: 'Tạo nhóm đầu tiên', onPressed: onCreate),
          ],
        ),
      ),
    );
  }
}

/// Khung viền nét đứt cho các trạng thái rỗng / ô "thêm mới".
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? const Color(0xFF475569)
        : const Color(0xFFCBD5E1);

    return CustomPaint(
      painter: _DashedBorderPainter(color: borderColor),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      const Radius.circular(20),
    );

    final path = Path()..addRRect(rrect);

    // Cắt path viền thành các đoạn 6px vẽ / 5px trống.
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Segmented pill lọc nhóm theo vòng đời: đang hoạt động vs đã khóa hóa đơn.
class _LifecycleTabs extends StatelessWidget {
  const _LifecycleTabs({
    required this.current,
    required this.activeCount,
    required this.closedCount,
    required this.onChanged,
  });

  final GroupStatus current;
  final int activeCount;
  final int closedCount;
  final ValueChanged<GroupStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LifecycleTabItem(
              label: 'Đang hoạt động',
              count: activeCount,
              isActive: current == GroupStatus.active,
              onTap: () => onChanged(GroupStatus.active),
            ),
          ),
          Expanded(
            child: _LifecycleTabItem(
              label: 'Tạm khóa nhận bill',
              count: closedCount,
              isActive: current == GroupStatus.closed,
              onTap: () => onChanged(GroupStatus.closed),
            ),
          ),
        ],
      ),
    );
  }
}

class _LifecycleTabItem extends StatelessWidget {
  const _LifecycleTabItem({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? const Color(0xFF334155) : Colors.white;
    final activeText = isDark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF0F172A);
    final inactiveText = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final primaryColor = isDark ? const Color(0xFF14B8A6) : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? activeText : inactiveText,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isActive ? primaryColor : inactiveText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trạng thái rỗng của tab "Tạm khóa nhận bill".
class _EmptyClosedState extends StatelessWidget {
  const _EmptyClosedState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.warningSubtle,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warningBorder),
              ),
              child: const Icon(
                HugeIcons.strokeRoundedLock,
                size: 22,
                color: AppColors.warningText,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Chưa có nhóm nào tạm khóa nhận bill',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Khi cần tạm dừng để đối soát số liệu, trưởng nhóm có thể\nbật tạm khóa nhận hóa đơn mới trong Cài đặt nhóm.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trạng thái lỗi khi không tải được danh sách nhóm.
class _GroupsErrorState extends StatelessWidget {
  const _GroupsErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
