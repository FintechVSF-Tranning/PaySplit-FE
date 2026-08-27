import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../di/injection.dart';
import '../../../bills/domain/entities/bill_detail_entity.dart';
import '../../../bills/domain/repositories/bill_repository.dart';
import '../../../home/presentation/widgets/group_settings_bottom_sheet.dart';
import '../../../settlement/presentation/providers/settlement_controller.dart';
import '../../../settlement/presentation/widgets/proof_review_sheet.dart';
import '../../../settlement/presentation/widgets/reject_proof_dialog.dart';
import '../../../home/presentation/widgets/invite_code_bottom_sheet.dart';
import '../../domain/entities/group_bill_entity.dart';
import '../../domain/entities/group_debt_entity.dart';
import '../../domain/entities/group_detail_entity.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_member_entity.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/usecases/create_invite_usecase.dart';
import '../../domain/usecases/leave_or_remove_member_usecase.dart';
import '../../domain/usecases/lock_bill_submissions_usecase.dart';
import '../../domain/usecases/unlock_bill_submissions_usecase.dart';
import '../../domain/usecases/list_invites_usecase.dart';
import '../../domain/usecases/revoke_invite_usecase.dart';
import '../../domain/usecases/transfer_captain_usecase.dart';
import '../providers/group_activities_provider.dart';
import '../providers/group_bills_provider.dart';
import '../providers/group_bill_close_provider.dart';
import '../providers/group_debts_provider.dart';
import '../providers/group_detail_provider.dart';
import '../providers/group_roster_provider.dart';
import '../providers/groups_provider.dart';
import '../widgets/bill_speed_dial.dart';
import '../widgets/bulk_finalize_progress_sheet.dart';
import '../widgets/group_activity_panel.dart';
import '../widgets/group_balance_banner.dart';
import '../widgets/group_bill_card.dart';
import '../widgets/group_debts_panel.dart';
import '../widgets/group_members_panel.dart';
import '../widgets/invite_qr_bottom_sheet.dart';

/// 4 tab của màn Chi tiết nhóm (Group Hub).
enum GroupHubTab { bills, debts, members, activity }

/// Màn hình Chi tiết nhóm — bám theo prototype `#screen-group-hub`
/// của `PaySplit-UI`.
class GroupDetailPage extends ConsumerStatefulWidget {
  const GroupDetailPage({
    super.key,
    required this.group,
    this.openBatchId,
    this.initialTab,
  });

  final GroupEntity group;
  final String? openBatchId;
  final GroupHubTab? initialTab;

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage> {
  GroupHubTab _tab = GroupHubTab.bills;
  GroupBillFilter _billFilter = GroupBillFilter.all;
  bool _disbanded = false;
  bool _batchAutoOpened = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) {
      _tab = widget.initialTab!;
    }
  }

  GroupDetailKey get _detailKey => GroupDetailKey(widget.group);

  /// Bộ lọc trạng thái được gửi thẳng lên backend, nên mỗi chip là một khóa
  /// provider riêng.
  GroupBillsKey get _billsKey =>
      GroupBillsKey(groupId: widget.group.id, filter: _billFilter);

  /// Thay danh sách thành viên và số dư của [detail] bằng roster realtime.
  ///
  /// Số dư đến từ `balances` của `GET /groups/{id}` — cùng một lần đọc với danh
  /// sách thành viên. Nó đổi theo hóa đơn và thanh toán chứ không theo
  /// roster_version, nên stream roster không mang số dư mới; màn hình tải lại
  /// khi có thao tác hóa đơn / công nợ.
  GroupDetailEntity _withLiveRoster(
    GroupDetailEntity detail,
    GroupRosterState roster,
    Map<String, int> balanceByMember,
  ) {
    if (roster.isLoading && roster.members.isEmpty) return detail;

    final members = [
      for (final member in roster.members)
        GroupMemberBalance(
          member: member,
          balance: balanceByMember[member.id] ?? 0,
          isMe: member.id == roster.callerMembershipId,
        ),
    ];

    return GroupDetailEntity(
      group: _groupWithRoster(detail.group, roster, members.length),
      createdAtText: detail.createdAtText,
      bills: detail.bills,
      debts: detail.debts,
      debtMatrix: detail.debtMatrix,
      members: members,
      activities: detail.activities,
    );
  }

  /// Thay danh sách hóa đơn mock bằng dữ liệu thật từ `GET /api/v1/bills`.
  ///
  /// Trong lúc tải (hoặc khi lỗi) trả về danh sách rỗng để tab đếm đúng và
  /// panel tự hiển thị trạng thái loading/error, thay vì lộ dữ liệu mock.
  GroupDetailEntity _withLiveBills(
    GroupDetailEntity detail,
    GroupBillsState billsState,
  ) {
    final bills = billsState.bills;
    return GroupDetailEntity(
      group: detail.group,
      createdAtText: detail.createdAtText,
      bills: bills,
      debts: detail.debts,
      debtMatrix: detail.debtMatrix,
      members: detail.members,
      activities: detail.activities,
    );
  }

  /// Thay công nợ mock bằng dữ liệu thật từ `GET /groups/{id}/debts`.
  GroupDetailEntity _withLiveDebts(
    GroupDetailEntity detail,
    GroupDebtsState debtsState,
  ) {
    return GroupDetailEntity(
      group: _groupWithBalance(detail.group, debtsState),
      createdAtText: detail.createdAtText,
      bills: detail.bills,
      debts: debtsState.debts,
      debtMatrix: debtsState.matrix,
      members: detail.members,
      activities: detail.activities,
    );
  }

  /// Thay nhật ký mock bằng `GET /groups/{id}/activities`.
  GroupDetailEntity _withLiveActivities(
    GroupDetailEntity detail,
    GroupActivitiesState activitiesState,
  ) {
    return GroupDetailEntity(
      group: detail.group,
      createdAtText: detail.createdAtText,
      bills: detail.bills,
      debts: detail.debts,
      debtMatrix: detail.debtMatrix,
      members: detail.members,
      activities: activitiesState.activities,
    );
  }

  /// Số dư trên banner suy ra từ chính các khoản nợ đang hiển thị, nên con số
  /// và danh sách bên dưới luôn kể cùng một câu chuyện.
  GroupEntity _groupWithBalance(GroupEntity group, GroupDebtsState debtsState) {
    if (debtsState.isLoading && debtsState.debts.isEmpty) return group;
    return GroupEntity(
      id: group.id,
      name: group.name,
      memberCount: group.memberCount,
      myBalance: debtsState.myNetBalance,
      inviteCode: group.inviteCode,
      isCaptain: group.isCaptain,
      lastActivity: group.lastActivity,
      lastActivityAt: group.lastActivityAt,
      pendingBillCount: group.pendingBillCount,
      status: group.status,
      billSubmissionLocked: group.billSubmissionLocked,
      closedAtText: group.closedAtText,
      createdAt: group.createdAt,
    );
  }

  GroupEntity _groupWithRoster(
    GroupEntity group,
    GroupRosterState roster,
    int memberCount,
  ) {
    return GroupEntity(
      id: group.id,
      name: roster.groupName ?? group.name,
      memberCount: memberCount,
      myBalance: group.myBalance,
      inviteCode: group.inviteCode,
      isCaptain: roster.callerRole.isEmpty ? group.isCaptain : roster.isCaptain,
      lastActivity: group.lastActivity,
      lastActivityAt: group.lastActivityAt,
      pendingBillCount: group.pendingBillCount,
      status: group.status,
      billSubmissionLocked: roster.billSubmissionLocked,
      closedAtText: roster.billSubmissionLockedAtText ?? group.closedAtText,
      createdAt: group.createdAt,
    );
  }

  GroupDetailNotifier get _notifier =>
      ref.read(groupDetailProvider(_detailKey).notifier);

  /// Ba mutation roster (đổi tên, chuyển quyền, xóa thành viên) trả 204 hoặc
  /// body không kèm version, nên đường chắc chắn nhất sau khi chúng thành công
  /// là để roster tự catch-up thay vì đoán version mới.
  GroupRosterNotifier get _roster =>
      ref.read(groupRosterProvider(widget.group.id).notifier);

  @override
  Widget build(BuildContext context) {
    // Roster là nguồn sự thật realtime cho danh sách thành viên; phần còn lại
    // của màn hình (hóa đơn, công nợ, hoạt động) vẫn đến từ store cũ.
    final roster = ref.watch(groupRosterProvider(widget.group.id));

    // Trả dữ liệu tươi về cho danh sách nhóm. Danh sách chỉ tải một lần mỗi
    // phiên nên nếu người khác đổi tên nhóm, mở nhóm ra thấy tên mới mà back
    // lại vẫn thấy tên cũ. `listen` chứ không phải ghi thẳng trong `build`:
    // đổi state của provider khác giữa lúc dựng widget là lỗi.
    ref.listen<GroupRosterState>(groupRosterProvider(widget.group.id), (
      previous,
      next,
    ) {
      // Nhóm bị giải tán hoặc mình bị xóa khỏi nhóm trong lúc đang mở: mọi
      // thao tác từ đây sẽ là 403/404, nên đưa người dùng ra thay vì để họ bấm
      // vào một màn hình đã chết.
      if (next.endedReason != null && previous?.endedReason == null) {
        _handleGroupEnded(next.endedReason!);
        return;
      }

      if (next.isLoading || next.groupName == null) return;
      ref
          .read(groupsProvider.notifier)
          .applyGroupSnapshot(
            groupId: widget.group.id,
            name: next.groupName,
            memberCount: next.members.isEmpty ? null : next.members.length,
            isCaptain: next.callerRole.isEmpty ? null : next.isCaptain,
          );
    });
    final billsState = ref.watch(groupBillsProvider(_billsKey));
    final debtsState = ref.watch(groupDebtsProvider(widget.group.id));
    final activitiesState = ref.watch(groupActivitiesProvider(widget.group.id));
    // Số dư từng thành viên: ưu tiên tính lại từ công nợ vừa tải (cùng công
    // thức với backend) để nó đi theo mọi lần chốt hóa đơn / xác nhận thanh
    // toán; `GET /groups/{id}` chỉ là giá trị khởi đầu.
    final balances = debtsState.netBalanceByMember.isNotEmpty
        ? debtsState.netBalanceByMember
        : roster.balances;

    final detail = _withLiveActivities(
      _withLiveDebts(
        _withLiveBills(
          _withLiveRoster(
            ref.watch(groupDetailProvider(_detailKey)),
            roster,
            balances,
          ),
          billsState,
        ),
        debtsState,
      ),
      activitiesState,
    );

    _checkAutoOpenBatch(detail, roster);

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
                if (detail.group.billSubmissionLocked)
                  _ClosedRibbon(closedAtText: detail.group.closedAtText),
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
                          onReviewProof: _reviewProof,
                          onRemind: (debt) => _remindDebt(detail, debt),
                        ),
                        // Không tải được nhóm (mất mạng, 403 vì vừa bị xóa
                        // khỏi nhóm) thì nói ra, thay vì hiện một tab Thành
                        // viên trống trông như nhóm không có ai.
                        GroupHubTab.members =>
                          roster.failure != null && roster.members.isEmpty
                              ? _BillsPlaceholder(
                                  message: roster.failure!.message,
                                  onRetry: () => ref
                                      .read(
                                        groupRosterProvider(
                                          widget.group.id,
                                        ).notifier,
                                      )
                                      .resync(),
                                )
                              : GroupMembersPanel(
                                  detail: detail,
                                  canAddMember: detail.group.isCaptain,
                                  onAddMember: () =>
                                      _openAddMemberOptions(detail),
                                  onLeaveGroup: () => _leaveGroup(detail),
                                ),
                        GroupHubTab.activity => GroupActivityPanel(
                          detail: detail,
                          hasMore: activitiesState.hasMore,
                          onLoadMore: () => ref
                              .read(
                                groupActivitiesProvider(
                                  widget.group.id,
                                ).notifier,
                              )
                              .loadMore(),
                        ),
                      },
                    ],
                  ),
                ),
              ],
            ),

            // FAB tạo hóa đơn chỉ xuất hiện trên tab Hóa đơn.
            if (_tab == GroupHubTab.bills && !detail.group.billSubmissionLocked)
              Positioned(
                right: 0,
                bottom: 12,
                left: 0,
                top: 0,
                child: IgnorePointer(
                  ignoring: false,
                  child: BillSpeedDial(
                    onScanOcr: () => _openOcrScan(detail),
                    onManualEntry: () => _openManualEntry(detail),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Tab Hóa đơn ---------------------------------------------------------

  Widget _buildBillsPanel(GroupDetailEntity detail) {
    // Backend đã lọc theo `status`, client không lọc lại. Badge của các chip
    // lấy từ `counts` của toàn nhóm nên không phụ thuộc trang đang tải.
    final billsState = ref.watch(groupBillsProvider(_billsKey));
    final bills = detail.bills;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupPanelHead(
          title: 'Hóa đơn trong nhóm',
          subtitle: 'Được cập nhật theo tiến trình chia tiền',
          trailing: detail.group.isCaptain
              ? _BulkFinalizeButton(
                  isActive:
                      ref
                          .watch(groupBillCloseProvider(detail.group.id))
                          .batch
                          ?.isComplete ==
                      false,
                  hasExistingBatch:
                      ref
                          .watch(groupRosterProvider(detail.group.id))
                          .activeBillFinalizeBatchId !=
                      null,
                  isLoading: ref
                      .watch(groupBillCloseProvider(detail.group.id))
                      .isStarting,
                  onTap: () => _openBulkFinalize(detail),
                )
              : null,
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
                count: billsState.countFor(filter),
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

        if (billsState.isLoading && bills.isEmpty)
          const _BillsPlaceholder(message: 'Đang tải hóa đơn của nhóm...')
        else if (billsState.errorMessage != null && bills.isEmpty)
          _BillsPlaceholder(
            message: billsState.errorMessage!,
            onRetry: () =>
                ref.read(groupBillsProvider(_billsKey).notifier).load(),
          )
        else if (bills.isEmpty)
          _EmptyBills(filter: _billFilter)
        else ...[
          for (final bill in bills)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GroupBillCard(
                bill: bill,
                onTap: () => _openBillDetail(detail, bill),
                // Chỉ trưởng nhóm mới gỡ được hóa đơn khỏi nhóm.
                onDelete: detail.group.isCaptain
                    ? () => _removeBill(detail, bill)
                    : null,
              ),
            ),

          // Backend phân trang theo cursor: chỉ hiện nút khi còn trang sau.
          if (billsState.hasMore)
            _LoadMoreBillsButton(
              isLoading: billsState.isLoadingMore,
              onTap: () =>
                  ref.read(groupBillsProvider(_billsKey).notifier).loadMore(),
            ),

          // Lỗi khi tải thêm không được xóa danh sách đang hiển thị.
          if (billsState.errorMessage != null && bills.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                billsState.errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.danger,
                ),
              ),
            ),
        ],
      ],
    );
  }

  // --- Hành động -----------------------------------------------------------

  void _checkAutoOpenBatch(GroupDetailEntity detail, GroupRosterState roster) {
    if (_batchAutoOpened) return;
    final batchId =
        widget.openBatchId ??
        roster.activeBillFinalizeBatchId ??
        roster.latestBillFinalizeBatchId;

    if (batchId != null) {
      _batchAutoOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showBulkProgress(detail, batchId);
      });
    }
  }

  Future<void> _openBulkFinalize(GroupDetailEntity detail) async {
    final roster = ref.read(groupRosterProvider(detail.group.id));
    final current = ref.read(groupBillCloseProvider(detail.group.id)).batch;
    final existingId = current?.isComplete == false
        ? current!.id
        : roster.activeBillFinalizeBatchId;

    if (existingId != null) {
      await _showBulkProgress(detail, existingId);
      return;
    }

    final billsState = ref.read(groupBillsProvider(_billsKey));
    final reviewed = billsState.countFor(GroupBillFilter.reviewed);
    final drafts = billsState.countFor(GroupBillFilter.draft);
    final excluded =
        billsState.countFor(GroupBillFilter.finalized) +
        billsState.countFor(GroupBillFilter.voided);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chốt toàn bộ hóa đơn?'),
        content: Text(
          'Thao tác này sẽ khóa nhận bill mới và xử lý $reviewed bill đã đối soát cùng $drafts bill cần kiểm tra. $excluded bill đã chốt hoặc đã hủy sẽ được bỏ qua. Các bill lỗi vẫn có thể sửa sau đó.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Khóa và chốt'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final notifier = ref.read(groupBillCloseProvider(detail.group.id).notifier);
    final started = await notifier.start();
    if (!mounted) return;
    if (!started) {
      final message = ref
          .read(groupBillCloseProvider(detail.group.id))
          .errorMessage;
      showErrorSnackBar(context, message ?? 'Không thể bắt đầu chốt toàn bộ');
      return;
    }

    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    _notifier.closeBook(date);
    ref
        .read(groupsProvider.notifier)
        .markGroupClosedLocally(detail.group.id, date);
    final batch = ref.read(groupBillCloseProvider(detail.group.id)).batch;
    _roster.applyLocalBillLock(date, activeBatchId: batch?.id);
    if (batch != null) await _showBulkProgress(detail, batch.id);
    _refreshBills();
  }

  Future<void> _showBulkProgress(
    GroupDetailEntity detail,
    String batchId,
  ) async {
    await BulkFinalizeProgressSheet.show(
      context,
      groupId: detail.group.id,
      batchId: batchId,
      onOpenBill: (billId) => context.push(
        AppRoutes.billDetail,
        extra: {
          'billId': billId,
          'groupId': detail.group.id,
          'groupName': detail.group.name,
        },
      ),
    );
    if (!mounted) return;
    _refreshBills();
  }

  /// Hóa đơn mới chưa tồn tại trên server: dựng draft rỗng để màn chia tiền
  /// khởi tạo (cùng khuôn với luồng quét bill ở màn Tổng quan).
  BillDetailEntity _draftBillFor(GroupDetailEntity detail) {
    return BillDetailEntity(
      id: '',
      groupId: detail.group.id,
      groupName: detail.group.name,
      creditorMemberId: '',
      creditorName: '',
      status: 'draft',
      merchantName: 'Hoá đơn ${detail.group.name}',
      subtotal: 0,
      serviceCharge: 0,
      vat: 0,
      totalItemDiscount: 0,
      generalDiscount: 0,
      total: 0,
    );
  }

  /// Quét OCR: vào thẳng màn chụp hóa đơn với nhóm hiện tại (bỏ qua bước chọn
  /// nhóm của luồng ở màn Tổng quan vì ta đã ở trong nhóm).
  Future<void> _openOcrScan(GroupDetailEntity detail) async {
    await context.push(
      AppRoutes.scanBill,
      extra: {'groupId': detail.group.id, 'groupName': detail.group.name},
    );
    _refreshBills();
  }

  /// Nhập tay: mở thẳng màn chia tiền với hóa đơn draft rỗng — chính là nhánh
  /// "Nhập thủ công" của màn chụp hóa đơn.
  Future<void> _openManualEntry(GroupDetailEntity detail) async {
    await context.push(
      AppRoutes.billDetail,
      extra: {'bill': _draftBillFor(detail), 'autoStartOcr': false},
    );
    _refreshBills();
  }

  /// Mở lại một hóa đơn đã có: màn chia tiền tự gọi `GET /api/v1/bills/{id}`
  /// và hiển thị đúng phần đã chia (read-only nếu hóa đơn đã chốt/hủy).
  Future<void> _openBillDetail(
    GroupDetailEntity detail,
    GroupBillEntity bill,
  ) async {
    await context.push(
      AppRoutes.billDetail,
      extra: {
        'billId': bill.id,
        'groupId': detail.group.id,
        'groupName': detail.group.name,
        'merchantName': bill.title,
      },
    );
    _refreshBills();
  }

  /// Rời khỏi màn nhóm khi quyền đọc không còn: nhóm bị giải tán, hoặc mình
  /// vừa bị xóa khỏi nhóm.
  void _handleGroupEnded(String reason) {
    if (!mounted || _disbanded) return;
    _disbanded = true;

    ref.read(groupsProvider.notifier).removeGroupLocally(widget.group.id);
    showErrorSnackBar(
      context,
      reason == 'group_archived'
          ? 'Nhóm "${widget.group.name}" đã được giải tán'
          : 'Bạn không còn là thành viên của nhóm "${widget.group.name}"',
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.groups);
    }
  }

  /// Gỡ bỏ một hóa đơn khỏi nhóm. Backend có hai đường khác hẳn nhau:
  ///
  /// - `draft` → `DELETE /bills/{id}`: xóa hẳn, kèm ảnh, vì hóa đơn chưa sinh
  ///   công nợ nên không có gì để giữ lại.
  /// - `finalized` → `POST /bills/{id}/void`: **huỷ**, giữ lại bản ghi và lý do
  ///   vì các khoản nợ đã phát sinh, bắt buộc có lý do và chỉ Captain được làm.
  /// - `reviewed` → backend chặn cả hai đường; phải mở hóa đơn bấm "Sửa lại"
  ///   để đưa về nháp trước.
  Future<void> _removeBill(
    GroupDetailEntity detail,
    GroupBillEntity bill,
  ) async {
    switch (bill.status) {
      case GroupBillStatus.draft:
        await _deleteDraftBill(detail, bill);
      case GroupBillStatus.finalized:
        await _voidFinalizedBill(detail, bill);
      case GroupBillStatus.reviewed:
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hóa đơn đang chờ duyệt'),
            content: Text(
              '"${bill.title}" đã được đối soát nên không xóa trực tiếp được. '
              'Mở hóa đơn và bấm "Sửa lại" để đưa về nháp, rồi xóa.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Đã hiểu'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  unawaited(_openBillDetail(detail, bill));
                },
                child: const Text('Mở hóa đơn'),
              ),
            ],
          ),
        );
      case GroupBillStatus.voided:
        showErrorSnackBar(context, 'Hóa đơn này đã bị hủy trước đó');
    }
  }

  Future<void> _deleteDraftBill(
    GroupDetailEntity detail,
    GroupBillEntity bill,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa hóa đơn nháp?'),
        content: Text(
          'Toàn bộ nội dung và ảnh của "${bill.title}" sẽ bị xóa vĩnh viễn. '
          'Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Giữ lại'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Xóa hóa đơn'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await getIt<BillRepository>().deleteDraftBill(
      billId: bill.id,
      groupId: detail.group.id,
    );
    if (!mounted) return;

    result.match(
      (failure) => showErrorSnackBar(
        context,
        'Xóa hóa đơn thất bại: ${failure.message}',
      ),
      (_) {
        showSuccessSnackBar(context, 'Đã xóa hóa đơn "${bill.title}"');
        _refreshBills();
      },
    );
  }

  Future<void> _voidFinalizedBill(
    GroupDetailEntity detail,
    GroupBillEntity bill,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _VoidBillDialog(billTitle: bill.title),
    );
    if (reason == null || !mounted) return;

    final result = await getIt<BillRepository>().voidBill(
      billId: bill.id,
      groupId: detail.group.id,
      version: bill.version,
      reason: reason,
    );
    if (!mounted) return;

    result.match(
      (failure) => showErrorSnackBar(
        context,
        'Hủy hóa đơn thất bại: ${failure.message}',
      ),
      (_) {
        showSuccessSnackBar(context, 'Đã hủy hóa đơn "${bill.title}"');
        _refreshBills();
      },
    );
  }

  /// Làm mới sau một thao tác hóa đơn.
  ///
  /// Chốt hoặc hủy một hóa đơn đổi luôn công nợ và số dư của cả nhóm, nên
  /// không chỉ danh sách hóa đơn cần tải lại: mọi bộ lọc (kể cả `counts` của
  /// chip khác), công nợ và nhật ký đều phải đi theo.
  void _refreshBills() {
    if (!mounted) return;

    unawaited(ref.read(groupDebtsProvider(widget.group.id).notifier).load());
    unawaited(
      ref.read(groupActivitiesProvider(widget.group.id).notifier).load(),
    );

    // Chỉ tải lại chip đang mở. Các chip khác là provider `autoDispose` chưa ai
    // xem nên đã bị hủy — bấm vào là tự tải mới. Gọi `invalidate` cho chúng ở
    // đây sẽ dựng cả 5 provider dậy và bắn 5 request cho một thao tác, đúng
    // kiểu làm chạm ngưỡng rate limit.
    unawaited(ref.read(groupBillsProvider(_billsKey).notifier).load());
  }

  /// Nút trên banner số dư: tôi đang nợ → sang màn Công nợ, nơi có luồng
  /// VietQR gộp khoản và nộp minh chứng đầy đủ.
  Future<void> _settleMyBalance(GroupDetailEntity detail) async {
    final owed = detail.debts
        .where((d) => d.direction == DebtDirection.iOwe)
        .toList();
    if (owed.isEmpty) {
      showSuccessSnackBar(
        context,
        'Bạn không còn khoản nào phải trả trong nhóm này',
      );
      return;
    }
    _openSettlement(SettlementTab.payable);
  }

  /// Trả tiền và duyệt minh chứng là luồng nhiều bước (tạo QR gộp khoản, tải
  /// ảnh minh chứng, đối bên xác nhận) đã có sẵn ở màn Công nợ. Màn nhóm chỉ
  /// đưa người dùng sang đúng tab thay vì dựng lại một bản rút gọn.
  void _payDebt(GroupDetailEntity detail, GroupDebtEntity debt) {
    _openSettlement(SettlementTab.payable);
  }

  Future<void> _reviewProof(GroupDebtEntity debt) async {
    // 1. Tải danh sách pending proofs từ settlement controller
    await ref.read(settlementControllerProvider.notifier).loadData();
    if (!mounted) return;
    final settlementState = ref.read(settlementControllerProvider);

    // 2. Tìm proof tương ứng với nhóm này và thành viên này
    final proof = settlementState.pendingProofs
        .where(
          (p) =>
              p.groupId == widget.group.id &&
              (p.debtorName == debt.counterpartName ||
                  debt.note.contains(p.debtorName)),
        )
        .firstOrNull ??
        settlementState.pendingProofs
            .where((p) => p.groupId == widget.group.id)
            .firstOrNull;

    if (proof == null) {
      showErrorSnackBar(
        context,
        'Không tìm thấy minh chứng thanh toán chờ duyệt của ${debt.counterpartName}',
      );
      return;
    }

    // 3. Mở Bottom Sheet duyệt bằng chứng chuyển tiền
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProofReviewSheet(
        proof: proof,
        onConfirm: () async {
          await ref
              .read(settlementControllerProvider.notifier)
              .confirmPendingPayment(
                groupId: proof.groupId,
                paymentId: proof.paymentId,
              );
          if (!mounted) return;
          await HapticFeedback.mediumImpact();
          if (!mounted) return;
          ref.invalidate(groupDebtsProvider(widget.group.id));
          ref.invalidate(groupDetailProvider(_detailKey));
          showSuccessSnackBar(
            context,
            'Đã xác nhận thanh toán từ ${proof.debtorName}! Số dư đã được cập nhật.',
          );
        },
        onReject: () {
          if (!mounted) return;
          showDialog<void>(
            context: context,
            builder: (_) => RejectProofDialog(
              onRejectSubmitted: (reason) async {
                await ref
                    .read(settlementControllerProvider.notifier)
                    .rejectPendingPayment(
                      groupId: proof.groupId,
                      paymentId: proof.paymentId,
                      reason: reason,
                    );
                if (!mounted) return;
                ref.invalidate(groupDebtsProvider(widget.group.id));
                ref.invalidate(groupDetailProvider(_detailKey));
                showErrorSnackBar(
                  context,
                  'Đã từ chối minh chứng. Khoản nợ đã được chuyển về trạng thái chờ thanh toán.',
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openSettlement(SettlementTab tab) {
    context.go(AppRoutes.settlement, extra: tab);
  }

  /// Nhắc nợ thật: gọi `POST /groups/{id}/debts/{debtId}/remind` cho khoản cũ
  /// nhất của người đó. Backend chặn ở 3 lần mỗi khoản nên không cần đếm lại ở
  /// client, chỉ cần hiển thị đúng lỗi trả về.
  Future<void> _remindDebt(
    GroupDetailEntity detail,
    GroupDebtEntity debt,
  ) async {
    final debtIds =
        ref
            .read(groupDebtsProvider(widget.group.id))
            .debtIdsByCounterpart[debt.id] ??
        const <String>[];
    if (debtIds.isEmpty) {
      showErrorSnackBar(context, 'Không tìm thấy khoản nợ để nhắc');
      return;
    }

    try {
      await ref
          .read(settlementRepositoryProvider)
          .remindDebt(groupId: detail.group.id, debtId: debtIds.first);
      if (!mounted) return;
      showSuccessSnackBar(
        context,
        'Đã gửi nhắc nợ tới ${debt.counterpartName}',
      );
      unawaited(
        ref.read(groupActivitiesProvider(widget.group.id).notifier).load(),
      );
    } catch (_) {
      if (!mounted) return;
      showErrorSnackBar(
        context,
        'Không gửi được nhắc nợ tới ${debt.counterpartName}',
      );
    }
  }

  /// Khóa hóa đơn: chốt bảng chia tiền, cố định phần tiền mỗi người phải trả.
  /// Không đòi hỏi nhóm đã sạch nợ — các khoản nợ vẫn trả tiếp sau khi chốt.
  /// Gọi từ sheet Cài đặt nhóm; trả về `true` khi đã chốt xong để sheet tự
  /// chuyển sang trạng thái khóa.
  Future<bool> _closeBook(GroupDetailEntity detail) async {
    // Đếm theo `counts` của cả nhóm, không theo danh sách đang hiển thị: chip
    // lọc chỉ tải hóa đơn của một trạng thái, dựa vào nó thì đứng ở tab "Đã
    // chốt" sẽ tưởng nhóm không còn hóa đơn nào dang dở.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _CloseBookDialog(detail: detail),
    );
    if (confirmed != true || !mounted) return false;

    final result = await getIt<LockBillSubmissionsUseCase>().call(
      detail.group.id,
    );
    if (!mounted) return false;

    return result.match(
      (failure) {
        showErrorSnackBar(context, 'Khóa hóa đơn thất bại: ${failure.message}');
        return false;
      },
      (lockedAt) {
        final closedAt =
            '${lockedAt.day.toString().padLeft(2, '0')}/${lockedAt.month.toString().padLeft(2, '0')}/${lockedAt.year}';
        _notifier.closeBook(closedAt);
        ref
            .read(groupsProvider.notifier)
            .markGroupClosedLocally(detail.group.id, closedAt);
        _roster.applyLocalBillLock(closedAt);
        unawaited(HapticFeedback.mediumImpact());
        showSuccessSnackBar(
          context,
          'Đã khóa nhận hóa đơn mới cho nhóm ${detail.group.name}',
        );
        return true;
      },
    );
  }

  /// Mở khóa nhận hóa đơn mới cho nhóm (chỉ Captain).
  Future<bool> _unlockBook(GroupDetailEntity detail) async {
    final result = await getIt<UnlockBillSubmissionsUseCase>().call(
      detail.group.id,
    );
    if (!mounted) return false;

    return result.match(
      (failure) {
        showErrorSnackBar(
          context,
          'Mở khóa nhận hóa đơn thất bại: ${failure.message}',
        );
        return false;
      },
      (_) {
        _notifier.unlockBook();
        ref
            .read(groupsProvider.notifier)
            .markGroupUnlockedLocally(detail.group.id);
        _roster.applyLocalBillUnlock();
        unawaited(HapticFeedback.mediumImpact());
        showSuccessSnackBar(
          context,
          'Đã mở khóa nhận hóa đơn nhóm ${detail.group.name}',
        );
        return true;
      },
    );
  }

  /// Số hóa đơn chưa chốt của **cả nhóm**, lấy từ `counts` mà backend trả kèm
  /// mọi trang danh sách.
  int _pendingBillCount() {
    final billsState = ref.read(groupBillsProvider(_billsKey));
    return billsState.countFor(GroupBillFilter.draft) +
        billsState.countFor(GroupBillFilter.reviewed);
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
      case _AddMemberChoice.inviteHub:
        await context.push(
          AppRoutes.addMembers(detail.group.id),
          extra: detail.group,
        );
    }
  }

  /// Sheet mã mời chạy trên API thật: liệt kê `GET /groups/{id}/invites`, tạo
  /// `POST .../invites`, thu hồi `DELETE .../invites/{inviteId}`.
  Future<void> _openInviteCodes(GroupDetailEntity detail) async {
    final groupId = detail.group.id;
    final listed = await getIt<ListInvitesUseCase>().call(groupId);
    if (!mounted) return;
    final invites = listed.fold<List<GroupInvite>>(
      (_) => const [],
      (items) => items,
    );
    final failure = listed.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      showErrorSnackBar(context, failure.message);
      return;
    }

    await InviteCodeBottomSheet.show(
      context: context,
      initialInvites: invites.map(_toInviteItem).toList(),
      onCreateInvite: () async {
        final created = await getIt<CreateInviteUseCase>().call(
          CreateInviteParams(groupId: groupId),
        );
        return created.fold((_) => null, _toInviteItem);
      },
      onRevokeInvite: (inviteId) async {
        final revoked = await getIt<RevokeInviteUseCase>().call(
          RevokeInviteParams(groupId: groupId, inviteId: inviteId),
        );
        return revoked.isRight();
      },
    );
  }

  InviteCodeItem _toInviteItem(GroupInvite invite) {
    final hoursLeft = invite.expiresAt.difference(DateTime.now()).inHours;
    final uses = invite.maxUses == null
        ? '${invite.useCount} lượt'
        : '${invite.useCount}/${invite.maxUses} lượt';
    return InviteCodeItem(
      id: invite.id,
      code: invite.code,
      statusText: hoursLeft <= 0
          ? 'Đã hết hạn, $uses'
          : 'Còn $hoursLeft giờ, $uses',
      inviteUrl: invite.inviteUrl,
    );
  }

  Future<void> _openSettings(GroupDetailEntity detail) async {
    await GroupSettingsBottomSheet.show(
      context: context,
      groupId: detail.group.id,
      initialGroupName: detail.group.name,
      createdAtText: detail.createdAtText,
      isCaptain: detail.group.isCaptain,
      currentUserNetBalance: detail.group.myBalance,
      isClosed: detail.group.billSubmissionLocked,
      closedAtText: detail.group.closedAtText,
      pendingBillCount: _pendingBillCount(),
      members: [
        for (final m in detail.members)
          GroupMemberSettingItem(
            membershipId: m.member.id,
            userId: m.member.id,
            displayName: m.member.name,
            role: m.member.role == GroupMemberRole.captain
                ? 'captain'
                : 'member',
            isCurrentUser: m.isMe,
          ),
      ],
      onRenameGroup: (newName) async {
        final failure = await ref
            .read(groupsProvider.notifier)
            .renameGroup(detail.group.id, newName);
        if (failure != null) {
          if (mounted) showErrorSnackBar(context, failure.message);
          return false;
        }
        _notifier.renameGroup(newName);
        // Áp tên mới vào roster ngay: header đọc tên từ đó, chờ sự kiện SSE
        // quay về thì màn hình còn hiện tên cũ.
        _roster.applyLocalRename(newName);
        unawaited(_roster.resync());
        return true;
      },
      onTransferCaptain: (membershipId) async {
        final result = await getIt<TransferCaptainUseCase>().call(
          MemberParams(groupId: detail.group.id, membershipId: membershipId),
        );
        final failure = result.fold<Failure?>((f) => f, (_) => null);
        if (failure != null) {
          if (mounted) showErrorSnackBar(context, failure.message);
          return false;
        }
        _notifier.transferCaptain(membershipId);
        unawaited(_roster.resync());
        return true;
      },
      onRemoveMember: (membershipId) async {
        final result = await getIt<LeaveOrRemoveMemberUseCase>().call(
          MemberParams(groupId: detail.group.id, membershipId: membershipId),
        );
        final failure = result.fold<Failure?>((f) => f, (_) => null);
        if (failure != null) {
          if (mounted) showErrorSnackBar(context, failure.message);
          return false;
        }
        _notifier.removeMember(membershipId);
        unawaited(_roster.resync());
        return true;
      },
      onCloseBook: () async => _closeBook(detail),
      onUnlockBook: () async => _unlockBook(detail),
      onLeaveGroup: () async => _tryLeaveGroup(detail),
      onDisbandGroup: () async {
        final failure = await ref
            .read(groupsProvider.notifier)
            .disbandGroup(detail.group.id);
        if (failure != null) {
          if (mounted) showErrorSnackBar(context, failure.message);
          return false;
        }
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

  /// Chặn sớm khi còn công nợ để không phải chờ 409 của backend, rồi gọi
  /// `DELETE /groups/{id}/members/{membershipId}` với membership của chính mình.
  Future<bool> _tryLeaveGroup(GroupDetailEntity detail) async {
    if (detail.group.myBalance != 0) {
      showErrorSnackBar(
        context,
        'Bạn còn công nợ mở. Hãy tất toán trước khi rời nhóm.',
      );
      return false;
    }
    final myMembershipId = detail.members
        .firstWhere((m) => m.isMe, orElse: () => detail.members.first)
        .member
        .id;
    final failure = await ref
        .read(groupsProvider.notifier)
        .leaveGroup(detail.group.id, myMembershipId);
    if (!mounted) return false;
    if (failure != null) {
      showErrorSnackBar(context, failure.message);
      return false;
    }
    showSuccessSnackBar(context, 'Đã rời nhóm ${detail.group.name}');
    return true;
  }
}

// --- Widget con -----------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.detail,
    required this.onBack,
    required this.onSettings,
  });

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
                  // Ngày tạo chỉ có sau khi tải danh sách nhóm; nhóm mở thẳng
                  // từ deep link chưa có nó, và "3 thành viên, " cụt đuôi thì
                  // xấu hơn là không nói gì.
                  detail.createdAtText.isEmpty
                      ? '${group.memberCount} thành viên'
                      : '${group.memberCount} thành viên, ${detail.createdAtText}',
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
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'PS';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

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
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
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
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
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
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.textSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút "Tải thêm" cho phân trang cursor của danh sách hóa đơn.
class _LoadMoreBillsButton extends StatelessWidget {
  const _LoadMoreBillsButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        onPressed: isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 13),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                'Tải thêm hóa đơn',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }
}

class _BulkFinalizeButton extends StatelessWidget {
  const _BulkFinalizeButton({
    required this.isActive,
    required this.hasExistingBatch,
    required this.isLoading,
    required this.onTap,
  });

  final bool isActive;
  final bool hasExistingBatch;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showProgress = isActive || hasExistingBatch;
    final label = showProgress ? 'Xem tiến trình' : 'Chốt toàn bộ';

    return Tooltip(
      message: showProgress
          ? 'Xem tiến trình chốt toàn bộ hóa đơn'
          : 'Khóa nhận bill và chốt tất cả hóa đơn hợp lệ',
      child: OutlinedButton(
        onPressed: isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 36),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}

/// Ô thông báo trạng thái tải / lỗi dùng chung cho các panel trong màn nhóm.
class _BillsPlaceholder extends StatelessWidget {
  const _BillsPlaceholder({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (onRetry == null)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          if (onRetry == null) const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ],
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
enum _AddMemberChoice { inviteCode, inviteQr, inviteHub }

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
                    onTap: () =>
                        Navigator.of(context).pop(_AddMemberChoice.inviteCode),
                  ),
                  const SizedBox(height: 10),
                  _OptionTile(
                    icon: HugeIcons.strokeRoundedQrCode,
                    title: 'Tạo QR mời',
                    subtitle: 'Cho người bên cạnh quét trực tiếp',
                    onTap: () =>
                        Navigator.of(context).pop(_AddMemberChoice.inviteQr),
                  ),
                  const SizedBox(height: 10),
                  _OptionTile(
                    icon: HugeIcons.strokeRoundedUserAdd01,
                    title: 'Xem tất cả cách mời',
                    subtitle: 'Link, QR và hướng dẫn cho người được mời',
                    onTap: () =>
                        Navigator.of(context).pop(_AddMemberChoice.inviteHub),
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
            const Icon(
              HugeIcons.strokeRoundedArrowRight01,
              size: 18,
              color: AppColors.textSubtle,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dải ribbon dưới header khi nhóm tạm khóa nhận hóa đơn: nói rõ nhóm đang tạm dừng
/// nhận bill mới và các hóa đơn hiện có vẫn xử lý bình thường.
class _ClosedRibbon extends StatelessWidget {
  const _ClosedRibbon({required this.closedAtText});

  final String? closedAtText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.warningSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.warningBorder),
            ),
            child: const Icon(
              HugeIcons.strokeRoundedLock,
              size: 18,
              color: AppColors.warningText,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  closedAtText == null
                      ? 'Nhóm đang tạm khóa nhận hóa đơn mới'
                      : 'Nhóm đang tạm khóa nhận hóa đơn từ $closedAtText',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warningText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Không tạo thêm hóa đơn mới. Các hóa đơn hiện có và công nợ vẫn xử lý bình thường.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
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

/// Hộp thoại nhập lý do huỷ hóa đơn đã chốt. Backend bắt buộc lý do 1-500 ký
/// tự và ghi nó vào nhật ký nhóm, nên đây không phải ô cho có.
class _VoidBillDialog extends StatefulWidget {
  const _VoidBillDialog({required this.billTitle});

  final String billTitle;

  @override
  State<_VoidBillDialog> createState() => _VoidBillDialogState();
}

class _VoidBillDialogState extends State<_VoidBillDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _controller.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Vui lòng nhập lý do hủy');
      return;
    }
    if (reason.length > 500) {
      setState(() => _error = 'Lý do tối đa 500 ký tự');
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hủy hóa đơn đã chốt?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Các khoản nợ phát sinh từ "${widget.billTitle}" sẽ được gỡ bỏ. '
            'Hóa đơn vẫn được giữ lại trong lịch sử kèm lý do hủy.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.45),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 2,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Lý do hủy',
              hintText: 'Ví dụ: nhập nhầm hóa đơn của nhóm khác',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Giữ lại'),
        ),
        TextButton(
          onPressed: _submit,
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('Hủy hóa đơn'),
        ),
      ],
    );
  }
}

/// Dialog xác nhận khóa nhận hóa đơn mới.
class _CloseBookDialog extends StatelessWidget {
  const _CloseBookDialog({required this.detail});

  final GroupDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Khóa nhận hóa đơn mới?',
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
            'Sau khi khóa, nhóm sẽ không thể tạo hoặc quét thêm hóa đơn mới.\n\nCác hóa đơn hiện có trong nhóm vẫn tiếp tục được xem, chỉnh sửa và chốt bình thường.',
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
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bạn có thể gạt mở khóa nhận hóa đơn lại bất cứ lúc nào trong Cài đặt nhóm.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
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
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F766E),
          ),
          child: Text(
            'Khóa nhận hóa đơn',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
