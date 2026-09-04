import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import '../../../../app/session/session_scope.dart';
import '../../domain/entities/group_activity_entity.dart';
import '../../domain/entities/group_debt_entity.dart';
import '../../domain/entities/group_detail_entity.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_member_entity.dart';

/// State store của màn Chi tiết nhóm cho phần chưa có API riêng (đổi tên, khóa
/// hóa đơn). Hóa đơn, công nợ, hoạt động, thành viên và số dư đều đến từ
/// backend qua các provider riêng và được ghép vào lúc dựng màn hình.
///
/// State khởi tạo cố tình **rỗng**: mọi danh sách ở đây sẽ bị dữ liệu thật thay
/// thế, nên nếu seed bằng dữ liệu mẫu thì trong lúc chờ tải xong người dùng sẽ
/// thấy thành viên và hóa đơn không có thật.
class GroupDetailNotifier extends StateNotifier<GroupDetailEntity> {
  GroupDetailNotifier(GroupEntity group)
    : super(
        GroupDetailEntity(
          group: group,
          createdAtText: _formatCreatedAt(group.createdAt),
          bills: const [],
          debts: const [],
          debtMatrix: const [],
          members: const [],
          activities: const [],
        ),
      );

  static final DateFormat _createdAtFormat = DateFormat('dd/MM/yyyy');

  static String _formatCreatedAt(DateTime? createdAt) =>
      createdAt == null ? '' : 'tạo ngày ${_createdAtFormat.format(createdAt)}';

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
              m.member.id == memberId
                  ? GroupMemberRole.captain
                  : GroupMemberRole.member,
            ),
            balance: m.balance,
            isMe: m.isMe,
          ),
      ],
      // Tôi chỉ còn là trưởng nhóm nếu quyền được chuyển về chính mình.
      group: _copyGroup(
        isCaptain: state.members.any((m) => m.isMe && m.member.id == memberId),
      ),
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
    final remaining = state.members
        .where((m) => m.member.id != memberId)
        .toList();
    state = _copy(
      members: remaining,
      group: _copyGroup(memberCount: remaining.length),
    );
  }

  /// Khóa nhận hóa đơn mới: chặn thêm/quét hóa đơn mới.
  void closeBook(String closedAtText) {
    state = _copy(
      group: _copyGroup(billSubmissionLocked: true, closedAtText: closedAtText),
      activities: [
        GroupActivityEntity(
          id: 'a_close_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Nhóm đã khóa nhận hóa đơn mới',
          subtitle: 'Không thể thêm bill mới. Các hóa đơn hiện có vẫn tiếp tục được xử lý.',
          timeText: 'Vừa xong',
          kind: GroupActivityKind.system,
        ),
        ...state.activities,
      ],
    );
  }

  /// Mở khóa nhận hóa đơn mới: cho phép thêm/quét hóa đơn trở lại.
  void unlockBook() {
    state = _copy(
      group: _copyGroup(billSubmissionLocked: false, clearClosedAt: true),
      activities: [
        GroupActivityEntity(
          id: 'a_unlock_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Nhóm đã mở khóa nhận hóa đơn',
          subtitle: 'Thành viên có thể tiếp tục tạo và quét hóa đơn mới.',
          timeText: 'Vừa xong',
          kind: GroupActivityKind.system,
        ),
        ...state.activities,
      ],
    );
  }

  GroupEntity _copyGroup({
    String? name,
    int? memberCount,
    int? myBalance,
    bool? isCaptain,
    GroupStatus? status,
    bool? billSubmissionLocked,
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
      billSubmissionLocked: billSubmissionLocked ?? g.billSubmissionLocked,
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
/// (đổi tên, khóa hóa đơn...) đồng bộ ngược về `groupsProvider` nên entity truyền
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
    StateNotifierProvider.family<
      GroupDetailNotifier,
      GroupDetailEntity,
      GroupDetailKey
    >((ref, key) {
      ref.watch(sessionRevisionProvider);
      return GroupDetailNotifier(key.group);
    });
