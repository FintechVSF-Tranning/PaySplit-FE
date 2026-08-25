import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/group_detail_mock_data.dart';
import '../../domain/entities/group_activity_entity.dart';
import '../../domain/entities/group_debt_entity.dart';
import '../../domain/entities/group_detail_entity.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_member_entity.dart';

/// State store của màn Chi tiết nhóm. Mọi thao tác hiện thao tác trên mock
/// in-memory; chữ ký method giữ nguyên khi thay bằng UseCase thật.
class GroupDetailNotifier extends StateNotifier<GroupDetailEntity> {
  GroupDetailNotifier(GroupEntity group) : super(GroupDetailMockData.detailOf(group));

  /// 3 trạng thái số dư dùng cho nút "Demo số dư" của prototype.
  static const _demoBalances = [350000, -120000, 0];

  void renameGroup(String newName) {
    state = _copy(group: _copyGroup(name: newName.trim()));
  }

  /// Chuyển quyền trưởng nhóm sang một thành viên khác.
  void transferCaptain(String memberId) {
    state = _copy(
      members: [
        for (final m in state.members)
          GroupMemberBalance(
            member: _withRole(
              m.member,
              m.member.id == memberId ? GroupMemberRole.captain : GroupMemberRole.member,
            ),
            balance: m.balance,
            isMe: m.isMe,
          ),
      ],
      // Tôi chỉ còn là trưởng nhóm nếu quyền được chuyển về chính mình.
      group: _copyGroup(isCaptain: state.members.any((m) => m.isMe && m.member.id == memberId)),
    );
  }

  GroupMemberEntity _withRole(GroupMemberEntity member, GroupMemberRole role) {
    return GroupMemberEntity(
      id: member.id,
      name: member.name,
      phone: member.phone,
      avatarUrl: member.avatarUrl,
      role: role,
      sharedGroupCount: member.sharedGroupCount,
    );
  }

  void removeMember(String memberId) {
    final remaining = state.members.where((m) => m.member.id != memberId).toList();
    state = _copy(
      members: remaining,
      group: _copyGroup(memberCount: remaining.length),
    );
  }

  /// Chủ nợ duyệt minh chứng: khoản nợ biến mất khỏi danh sách và ma trận.
  void approveProof(String debtId) {
    final matches = state.debts.where((d) => d.id == debtId).toList();
    if (matches.isEmpty) return;
    final debt = matches.first;

    state = _copy(
      debts: state.debts.where((d) => d.id != debtId).toList(),
      debtMatrix: _matrixWithout(debt),
      activities: [
        GroupActivityEntity(
          id: 'a_approve_${debt.id}',
          title: 'Bạn đã xác nhận nhận tiền từ ${debt.counterpartName}',
          subtitle: 'Khoản nợ đã được tất toán',
          timeText: 'Vừa xong',
          kind: GroupActivityKind.payment,
        ),
        ...state.activities,
      ],
    );
  }

  /// Gỡ đúng **một** dòng ma trận ứng với [debt] đã tất toán. [DebtMatrixRow]
  /// chưa tham chiếu tới `debt.id` nên phải khớp theo cặp (from, to) suy ra từ
  /// chiều nợ, và chỉ gỡ dòng khớp đầu tiên — một người có thể nợ tôi ở nhiều
  /// khoản, duyệt khoản này không được xóa các khoản còn lại.
  List<DebtMatrixRow> _matrixWithout(GroupDebtEntity debt) {
    final from = debt.direction == DebtDirection.iOwe ? _meLabel : debt.counterpartName;
    final to = debt.direction == DebtDirection.iOwe ? debt.counterpartName : _meLabel;

    final remaining = <DebtMatrixRow>[];
    var removed = false;
    for (final row in state.debtMatrix) {
      if (!removed && row.from == from && row.to == to && row.amount == debt.amount) {
        removed = true;
        continue;
      }
      remaining.add(row);
    }
    return remaining;
  }

  /// Nhãn đại diện người dùng hiện tại trong ma trận công nợ.
  static const _meLabel = 'Bạn';

  /// Chủ nợ từ chối minh chứng — khoản nợ quay lại trạng thái chờ trả.
  void rejectProof(String debtId, String reason) {
    state = _copy(
      debts: [
        for (final d in state.debts)
          if (d.id == debtId)
            GroupDebtEntity(
              id: d.id,
              counterpartName: d.counterpartName,
              direction: d.direction,
              amount: d.amount,
              note: 'Đã từ chối: $reason',
              transferRef: d.transferRef,
            )
          else
            d,
      ],
    );
  }

  /// Người nợ nộp minh chứng sau khi chuyển khoản qua VietQR.
  void submitProof(String debtId) {
    state = _copy(
      debts: [
        for (final d in state.debts)
          if (d.id == debtId)
            GroupDebtEntity(
              id: d.id,
              counterpartName: d.counterpartName,
              direction: d.direction,
              amount: d.amount,
              note: 'Chờ ${d.counterpartName} xác nhận',
              hasPendingProof: true,
              transferRef: d.transferRef,
            )
          else
            d,
      ],
    );
  }

  /// Nạp thêm một lô hoạt động cũ hơn vào cuối timeline.
  bool loadMoreActivities() {
    final existing = state.activities.map((a) => a.id).toSet();
    final next = GroupDetailMockData.moreActivities.where((a) => !existing.contains(a.id)).toList();
    if (next.isEmpty) return false;
    state = _copy(activities: [...state.activities, ...next]);
    return true;
  }

  /// Xoay vòng số dư demo (dương → âm → cân bằng) như nút "Demo số dư".
  void cycleDemoBalance() {
    final index = _demoBalances.indexOf(state.group.myBalance);
    final next = _demoBalances[(index + 1) % _demoBalances.length];
    state = _copy(group: _copyGroup(myBalance: next));
  }

  /// Khóa bill: chặn thêm/sửa hóa đơn và cố định số tiền mỗi người phải trả.
  /// Công nợ vẫn tiếp tục được thanh toán sau khi khóa.
  void closeBook(String closedAtText) {
    state = _copy(
      group: _copyGroup(status: GroupStatus.closed, closedAtText: closedAtText),
      activities: [
        GroupActivityEntity(
          id: 'a_close_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Nhóm đã được khóa bill',
          subtitle: 'Bảng chia tiền đã khóa, phần của mỗi người được giữ nguyên',
          timeText: 'Vừa xong',
          kind: GroupActivityKind.system,
        ),
        ...state.activities,
      ],
    );
  }

  /// Mở khóa bill để tiếp tục thêm hóa đơn (chỉ trưởng nhóm).

  GroupEntity _copyGroup({
    String? name,
    int? memberCount,
    int? myBalance,
    bool? isCaptain,
    GroupStatus? status,
    String? closedAtText,
    bool clearClosedAt = false,
  }) {
    final g = state.group;
    return GroupEntity(
      id: g.id,
      name: name ?? g.name,
      memberCount: memberCount ?? g.memberCount,
      myBalance: myBalance ?? g.myBalance,
      inviteCode: g.inviteCode,
      isCaptain: isCaptain ?? g.isCaptain,
      lastActivity: g.lastActivity,
      lastActivityAt: g.lastActivityAt,
      pendingBillCount: g.pendingBillCount,
      status: status ?? g.status,
      closedAtText: clearClosedAt ? null : (closedAtText ?? g.closedAtText),
    );
  }

  GroupDetailEntity _copy({
    GroupEntity? group,
    List<GroupDebtEntity>? debts,
    List<DebtMatrixRow>? debtMatrix,
    List<GroupMemberBalance>? members,
    List<GroupActivityEntity>? activities,
  }) {
    return GroupDetailEntity(
      group: group ?? state.group,
      createdAtText: state.createdAtText,
      bills: state.bills,
      debts: debts ?? state.debts,
      debtMatrix: debtMatrix ?? state.debtMatrix,
      members: members ?? state.members,
      activities: activities ?? state.activities,
    );
  }
}

/// Key của [groupDetailProvider]. Mang theo entity gốc để khởi tạo detail,
/// nhưng chỉ so sánh theo [GroupEntity.id]: các thao tác trên màn chi tiết
/// (đổi tên, khóa bill...) đồng bộ ngược về `groupsProvider` nên entity truyền
/// vào sẽ khác đi ở lần mở sau. Nếu key theo cả entity, family coi đó là nhóm
/// mới và dựng lại notifier từ mock, làm mất state đã thao tác.
class GroupDetailKey extends Equatable {
  const GroupDetailKey(this.group);

  final GroupEntity group;

  @override
  List<Object?> get props => [group.id];
}

/// Detail được key theo nhóm để mỗi nhóm giữ state riêng khi mở lại.
final groupDetailProvider =
    StateNotifierProvider.family<GroupDetailNotifier, GroupDetailEntity, GroupDetailKey>(
      (ref, key) => GroupDetailNotifier(key.group),
    );
