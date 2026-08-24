import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../home/presentation/widgets/app_bottom_nav_bar.dart';
import '../../../home/presentation/widgets/group_settings_bottom_sheet.dart';
import '../../../home/presentation/widgets/invite_code_bottom_sheet.dart';
import '../../domain/entities/group_bill_entity.dart';
import '../../domain/entities/group_debt_entity.dart';
import '../../domain/entities/group_detail_entity.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_member_entity.dart';
import '../providers/group_detail_provider.dart';
import '../providers/groups_provider.dart';
import '../widgets/bill_speed_dial.dart';
import '../widgets/group_activity_panel.dart';
import '../widgets/group_balance_banner.dart';
import '../widgets/group_bill_card.dart';
import '../widgets/group_debts_panel.dart';
import '../widgets/group_members_panel.dart';
import '../widgets/invite_qr_bottom_sheet.dart';
import '../widgets/proof_review_sheet.dart';
import '../widgets/vietqr_payment_sheet.dart';

/// 4 tab của màn Chi tiết nhóm (Group Hub).
enum GroupHubTab { bills, debts, members, activity }

/// Màn hình Chi tiết nhóm — bám theo prototype `#screen-group-hub`
/// của `PaySplit-UI`.
class GroupDetailPage extends ConsumerStatefulWidget {
  const GroupDetailPage({super.key, required this.group});

  final GroupEntity group;

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage> {
  GroupHubTab _tab = GroupHubTab.bills;
  GroupBillFilter _billFilter = GroupBillFilter.all;
  bool _hasMoreActivities = true;
  bool _disbanded = false;

  GroupDetailNotifier get _notifier => ref.read(groupDetailProvider(widget.group).notifier);

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(groupDetailProvider(widget.group));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  detail: detail,
                  onBack: () => Navigator.of(context).maybePop(),
                  onSettings: () => _openSettings(detail),
                ),
                if (detail.group.isClosed)
                  _ClosedRibbon(
                    closedAtText: detail.group.closedAtText,
                    canReopen: detail.group.isCaptain,
                    onReopen: () => _reopenBook(detail),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                    children: [
                      GroupBalanceBanner(
                        group: detail.group,
                        onSettle: () => _settleMyBalance(detail),
                      ),
                      const SizedBox(height: 16),
                      _TabBar(
                        current: _tab,
                        billCount: detail.bills.length,
                        memberCount: detail.members.length,
                        onChanged: (tab) {
                          HapticFeedback.selectionClick();
                          setState(() => _tab = tab);
                        },
                      ),
                      const SizedBox(height: 18),
                      switch (_tab) {
                        GroupHubTab.bills => _buildBillsPanel(detail),
                        GroupHubTab.debts => GroupDebtsPanel(
                          detail: detail,
                          onPayQr: (debt) => _payDebt(detail, debt),
                          onReviewProof: (debt) => _reviewProof(debt),
                          onRemind: (debt) => showSuccessSnackBar(
                            context,
                            'Đã gửi nhắc nợ tới ${debt.counterpartName}',
                          ),
                        ),
                        GroupHubTab.members => GroupMembersPanel(
                          detail: detail,
                          canAddMember: !detail.group.isClosed,
                          onAddMember: () => _openAddMemberOptions(detail),
                          onLeaveGroup: () => _leaveGroup(detail),
                        ),
                        GroupHubTab.activity => GroupActivityPanel(
                          detail: detail,
                          hasMore: _hasMoreActivities,
                          onLoadMore: _loadMoreActivities,
                        ),
                      },
                    ],
                  ),
                ),
              ],
            ),

            // FAB tạo hóa đơn chỉ xuất hiện trên tab Hóa đơn.
            if (_tab == GroupHubTab.bills && !detail.group.isClosed)
              Positioned(
                right: 0,
                bottom: 62,
                left: 0,
                top: 0,
                child: IgnorePointer(
                  ignoring: false,
                  child: BillSpeedDial(
                    onScanOcr: () => showComingSoonSnackBar(context, 'Quét hóa đơn AI OCR'),
                    onManualEntry: () => showComingSoonSnackBar(context, 'Tạo hóa đơn thủ công'),
                  ),
                ),
              ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AppBottomNavBar(
                currentIndex: 1,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      context.go(AppRoutes.home);
                    case 1:
                      Navigator.of(context).maybePop();
                    case 2:
                      context.push(AppRoutes.bills);
                    case 3:
                      context.push(AppRoutes.profile);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tab Hóa đơn ---------------------------------------------------------

  Widget _buildBillsPanel(GroupDetailEntity detail) {
    final bills = detail.bills.where((b) => _billFilter.matches(b.status)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupPanelHead(
          title: 'Hóa đơn trong nhóm',
          subtitle: 'Được cập nhật theo tiến trình chia tiền',
          trailing: _DemoBalanceButton(
            state: detail.group.balanceState,
            onTap: () {
              HapticFeedback.selectionClick();
              _notifier.cycleDemoBalance();
            },
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: GroupBillFilter.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = GroupBillFilter.values[index];
              return _FilterChip(
                label: filter.label,
                count: detail.countBills(filter),
                isSelected: filter == _billFilter,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _billFilter = filter);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        if (bills.isEmpty)
          _EmptyBills(filter: _billFilter)
        else
          for (final bill in bills)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GroupBillCard(
                bill: bill,
                onTap: () => showComingSoonSnackBar(context, 'Chi tiết ${bill.title}'),
              ),
            ),

        if (!detail.group.isClosed) ...[
          const SizedBox(height: 6),
          _CloseBookCard(
            pendingCount: detail.bills.where((b) => b.status.isActive).length,
            onCloseBook: () => _closeBook(detail),
          ),
        ],
      ],
    );
  }

  // --- Hành động -----------------------------------------------------------

  /// Nút trên banner số dư: tôi đang nợ → mở VietQR cho khoản nợ đầu tiên.
  Future<void> _settleMyBalance(GroupDetailEntity detail) async {
    final owed = detail.debts.where((d) => d.direction == DebtDirection.iOwe).toList();
    if (owed.isEmpty) {
      showComingSoonSnackBar(context, 'Thanh toán VietQR');
      return;
    }
    await _payDebt(detail, owed.first);
  }

  Future<void> _payDebt(GroupDetailEntity detail, GroupDebtEntity debt) async {
    final submitted = await VietQrPaymentSheet.show(
      context,
      debt: debt,
      groupName: detail.group.name,
    );
    if (submitted != true || !mounted) return;

    _notifier.submitProof(debt.id);
    showSuccessSnackBar(context, 'Đã gửi minh chứng, chờ ${debt.counterpartName} xác nhận');
  }

  Future<void> _reviewProof(GroupDebtEntity debt) async {
    final result = await ProofReviewSheet.show(context, debt);
    if (result == null || !mounted) return;

    switch (result) {
      case ProofApproved():
        _notifier.approveProof(debt.id);
        showSuccessSnackBar(context, 'Đã xác nhận nhận tiền từ ${debt.counterpartName}');
      case ProofRejected(:final reason):
        _notifier.rejectProof(debt.id, reason);
        showErrorSnackBar(context, 'Đã từ chối minh chứng: $reason');
    }
  }

  /// Khóa bill: chốt bảng chia tiền, cố định phần tiền mỗi người phải trả.
  /// Không đòi hỏi nhóm đã sạch nợ — các khoản nợ vẫn trả tiếp sau khi chốt.
  Future<void> _closeBook(GroupDetailEntity detail) async {
    final pending = detail.bills.where((b) => b.status.isActive).toList();
    if (pending.isNotEmpty) {
      showErrorSnackBar(
        context,
        'Còn ${pending.length} hóa đơn chưa chia xong. Hoàn tất trước khi khóa bill.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _CloseBookDialog(detail: detail),
    );
    if (confirmed != true || !mounted) return;

    final now = DateTime.now();
    final closedAt =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    _notifier.closeBook(closedAt);
    ref
        .read(groupsProvider.notifier)
        .setGroupStatus(detail.group.id, GroupStatus.closed, closedAtText: closedAt);
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    showSuccessSnackBar(context, 'Đã khóa bill nhóm ${detail.group.name}');
  }

  Future<void> _reopenBook(GroupDetailEntity detail) async {
    _notifier.reopenBook();
    ref.read(groupsProvider.notifier).setGroupStatus(detail.group.id, GroupStatus.active);
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    showSuccessSnackBar(context, 'Đã mở khóa bill, có thể thêm hóa đơn mới');
  }

  void _loadMoreActivities() {
    final loaded = _notifier.loadMoreActivities();
    setState(() => _hasMoreActivities = loaded);
    if (!loaded) {
      showComingSoonSnackBar(context, 'Lịch sử hoạt động cũ hơn');
    }
  }

  /// Menu 3 lối thêm người: mã mời, QR mời, hoặc chọn từ danh bạ gần đây.
  Future<void> _openAddMemberOptions(GroupDetailEntity detail) async {
    final choice = await showModalBottomSheet<_AddMemberChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddMemberOptionsSheet(),
    );
    if (choice == null || !mounted) return;

    switch (choice) {
      case _AddMemberChoice.inviteCode:
        await _openInviteCodes(detail);
      case _AddMemberChoice.inviteQr:
        await InviteQrBottomSheet.show(context, detail.group);
      case _AddMemberChoice.contacts:
        await context.push(AppRoutes.addMembers(detail.group.id), extra: detail.group);
    }
  }

  Future<void> _openInviteCodes(GroupDetailEntity detail) async {
    await InviteCodeBottomSheet.show(
      context: context,
      initialInvites: [
        InviteCodeItem(
          id: 'inv_1',
          code: detail.group.inviteCode,
          statusText: 'Còn 23 giờ, 12/50 lượt',
          inviteUrl: detail.group.inviteLink,
        ),
      ],
      onCreateInvite: () async => InviteCodeItem(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
        code: detail.group.inviteCode,
        statusText: 'Còn 24 giờ, 0/50 lượt',
        inviteUrl: detail.group.inviteLink,
      ),
      onRevokeInvite: (_) async => true,
    );
  }

  Future<void> _openSettings(GroupDetailEntity detail) async {
    await GroupSettingsBottomSheet.show(
      context: context,
      groupId: detail.group.id,
      initialGroupName: detail.group.name,
      createdAtText: '15/08/2026',
      isCaptain: detail.group.isCaptain,
      currentUserNetBalance: detail.group.myBalance,
      members: [
        for (final m in detail.members)
          GroupMemberSettingItem(
            membershipId: m.member.id,
            userId: m.member.id,
            displayName: m.member.name,
            role: m.member.role == GroupMemberRole.captain ? 'captain' : 'member',
            isCurrentUser: m.isMe,
          ),
      ],
      onRenameGroup: (newName) async {
        _notifier.renameGroup(newName);
        ref.read(groupsProvider.notifier).renameGroup(detail.group.id, newName);
        return true;
      },
      onTransferCaptain: (membershipId) async {
        _notifier.transferCaptain(membershipId);
        return true;
      },
      onRemoveMember: (membershipId) async {
        _notifier.removeMember(membershipId);
        return true;
      },
      onLeaveGroup: () async => _tryLeaveGroup(detail),
      onDisbandGroup: () async {
        ref.read(groupsProvider.notifier).deleteGroup(detail.group.id);
        _disbanded = true;
        return true;
      },
    );

    // Nhóm đã bị giải tán thì màn chi tiết không còn gì để hiển thị.
    if (_disbanded && mounted) await Navigator.of(context).maybePop();
  }

  Future<void> _leaveGroup(GroupDetailEntity detail) async {
    final ok = await _tryLeaveGroup(detail);
    if (!ok || !mounted) return;
    await Navigator.of(context).maybePop();
  }

  /// Chỉ cho rời nhóm khi đã sạch nợ — khớp ràng buộc 409 của backend.
  Future<bool> _tryLeaveGroup(GroupDetailEntity detail) async {
    if (detail.group.myBalance != 0) {
      showErrorSnackBar(context, 'Bạn còn công nợ mở. Hãy tất toán trước khi rời nhóm.');
      return false;
    }
    ref.read(groupsProvider.notifier).deleteGroup(detail.group.id);
    showSuccessSnackBar(context, 'Đã rời nhóm ${detail.group.name}');
    return true;
  }
}

// --- Widget con -----------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.detail, required this.onBack, required this.onSettings});

  final GroupDetailEntity detail;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final group = detail.group;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          _CircleIconButton(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            tooltip: 'Quay lại',
            onTap: onBack,
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySubtle,
              border: Border.all(color: AppColors.primaryBorder),
            ),
            alignment: Alignment.center,
            child: Text(
              _monogram(group.name),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMain,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (group.isCaptain) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.warningSubtle,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.warningBorder),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'C',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.warningText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${group.memberCount} thành viên, ${detail.createdAtText}',
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
          _CircleIconButton(
            icon: HugeIcons.strokeRoundedSettings01,
            tooltip: 'Cài đặt nhóm',
            onTap: onSettings,
          ),
        ],
      ),
    );
  }

  static String _monogram(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'PS';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 20, color: AppColors.textMain),
        ),
      ),
    );
  }
}

/// Thanh tab gạch chân, cuộn ngang khi tên tab dài.
class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.current,
    required this.billCount,
    required this.memberCount,
    required this.onChanged,
  });

  final GroupHubTab current;
  final int billCount;
  final int memberCount;
  final ValueChanged<GroupHubTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <(GroupHubTab, String, int?)>[
      (GroupHubTab.bills, 'Hóa đơn', billCount),
      (GroupHubTab.debts, 'Công nợ', null),
      (GroupHubTab.members, 'Thành viên', memberCount),
      (GroupHubTab.activity, 'Hoạt động', null),
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (tab, label, count) in items)
              _TabItem(
                label: label,
                count: count,
                isActive: tab == current,
                onTap: () => onChanged(tab),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: isActive ? AppColors.primary : Colors.transparent, width: 2),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? AppColors.textMain : AppColors.textMuted,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              Text(
                '$count',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.primary : AppColors.textSubtle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white.withValues(alpha: 0.85) : AppColors.textSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút prototype xoay vòng 3 trạng thái số dư để demo giao diện.
class _DemoBalanceButton extends StatelessWidget {
  const _DemoBalanceButton({required this.state, required this.onTap});

  final GroupBalanceState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      GroupBalanceState.positive => 'Demo số dư',
      GroupBalanceState.negative => 'Demo cần trả',
      GroupBalanceState.settled => 'Demo sạch nợ',
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _EmptyBills extends StatelessWidget {
  const _EmptyBills({required this.filter});

  final GroupBillFilter filter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            'Chưa có hóa đơn theo bộ lọc "${filter.label}"',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Thử một bộ lọc khác hoặc tạo hóa đơn đầu tiên.',
            textAlign: TextAlign.center,
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

/// Các lối thêm thành viên mở từ tab "Thành viên".
enum _AddMemberChoice { inviteCode, inviteQr, contacts }

class _AddMemberOptionsSheet extends StatelessWidget {
  const _AddMemberOptionsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Thêm thành viên',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _OptionTile(
                    icon: HugeIcons.strokeRoundedLink01,
                    title: 'Quản lý mã mời',
                    subtitle: 'Sao chép, thu hồi hoặc tạo mã mới',
                    onTap: () => Navigator.of(context).pop(_AddMemberChoice.inviteCode),
                  ),
                  const SizedBox(height: 10),
                  _OptionTile(
                    icon: HugeIcons.strokeRoundedQrCode,
                    title: 'Tạo QR mời',
                    subtitle: 'Cho người bên cạnh quét trực tiếp',
                    onTap: () => Navigator.of(context).pop(_AddMemberChoice.inviteQr),
                  ),
                  const SizedBox(height: 10),
                  _OptionTile(
                    icon: HugeIcons.strokeRoundedUserAdd01,
                    title: 'Chọn từ danh bạ gần đây',
                    subtitle: 'Thêm nhanh những người hay đi chung',
                    onTap: () => Navigator.of(context).pop(_AddMemberChoice.contacts),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryBorder),
              ),
              child: Icon(icon, size: 19, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(HugeIcons.strokeRoundedArrowRight01, size: 18, color: AppColors.textSubtle),
          ],
        ),
      ),
    );
  }
}

/// Dải ribbon dưới header khi nhóm đã khóa bill: nói rõ cái gì bị khóa và cái
/// gì vẫn chạy tiếp (công nợ), kèm lối mở khóa cho trưởng nhóm.
class _ClosedRibbon extends StatelessWidget {
  const _ClosedRibbon({
    required this.closedAtText,
    required this.canReopen,
    required this.onReopen,
  });

  final String? closedAtText;
  final bool canReopen;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              HugeIcons.strokeRoundedCheckmarkCircle02,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  closedAtText == null
                      ? 'Nhóm đã khóa bill'
                      : 'Nhóm đã khóa bill ngày $closedAtText',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Không thêm hóa đơn mới. Công nợ vẫn tiếp tục thanh toán.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (canReopen) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onReopen,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Mở khóa bill',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Thẻ CTA cuối tab Hóa đơn: khóa bill khi mọi hóa đơn đã chia xong.
class _CloseBookCard extends StatelessWidget {
  const _CloseBookCard({required this.pendingCount, required this.onCloseBook});

  final int pendingCount;
  final VoidCallback onCloseBook;

  @override
  Widget build(BuildContext context) {
    final isReady = pendingCount == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReady ? AppColors.primarySubtle : AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isReady ? AppColors.primaryBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Khóa bill nhóm',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isReady
                ? 'Khóa bảng chia tiền và cố định phần mỗi người phải trả. Các khoản nợ vẫn thanh toán bình thường sau khi chốt.'
                : 'Còn $pendingCount hóa đơn chưa chia xong. Hoàn tất chia tiền rồi mới khóa bill được.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Khóa bill nhóm',
            variant: isReady ? AppButtonVariant.primary : AppButtonVariant.outline,
            icon: Icon(
              HugeIcons.strokeRoundedCheckmarkCircle02,
              size: 18,
              color: isReady ? Colors.white : AppColors.textMuted,
            ),
            onPressed: isReady ? onCloseBook : null,
          ),
        ],
      ),
    );
  }
}

/// Dialog xác nhận khóa bill: liệt kê phần tiền chốt của từng thành viên.
class _CloseBookDialog extends StatelessWidget {
  const _CloseBookDialog({required this.detail});

  final GroupDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Khóa bill nhóm?',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.textMain,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sau khi chốt, nhóm không thêm hoặc sửa hóa đơn được nữa. Số tiền dưới đây được giữ nguyên cho tới khi thanh toán xong.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (final m in detail.members)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            m.isMe ? '${m.member.name} (Bạn)' : m.member.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                        Text(
                          m.balance == 0
                              ? CurrencyFormatter.vnd(0)
                              : CurrencyFormatter.vndSigned(m.balance),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: m.balance > 0
                                ? AppColors.balancePositive
                                : m.balance < 0
                                ? AppColors.balanceNegative
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Để sau',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Khóa bill',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
