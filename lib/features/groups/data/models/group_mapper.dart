import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_member_entity.dart';
import 'group_models.dart';

extension GroupModelMapper on GroupModel {
  /// Quy đổi sang [GroupEntity]. Các thông tin không nằm trong một response
  /// nhóm đơn lẻ ([memberCount], [myBalance], [inviteCode]...) phải được truyền
  /// vào từ ngữ cảnh gọi.
  GroupEntity toEntity({
    int memberCount = 0,
    int myBalance = 0,
    bool isCaptain = false,
    String? inviteCode,
    String? lastActivity,
    DateTime? lastActivityAt,
    int pendingBillCount = 0,
  }) {
    return GroupEntity(
      id: id,
      name: name,
      memberCount: memberCount,
      myBalance: myBalance,
      inviteCode: inviteCode,
      isCaptain: isCaptain,
      lastActivity: lastActivity,
      lastActivityAt: lastActivityAt,
      pendingBillCount: pendingBillCount,
      // Khóa gửi hóa đơn của backend là một chiều; FE ánh xạ sang trạng thái
      // "đã khóa bill" của UI.
      status: billSubmissionLocked ? GroupStatus.closed : GroupStatus.active,
      closedAtText: billSubmissionLockedAt == null ? null : _formatDate(billSubmissionLockedAt!),
    );
  }
}

extension GroupListItemModelMapper on GroupListItemModel {
  GroupEntity toEntity() => group.toEntity(
    memberCount: activeMemberCount,
    myBalance: int.tryParse(callerNetBalance) ?? 0,
    isCaptain: callerRole == 'captain',
    lastActivity: lastActivity?.description,
    lastActivityAt: lastActivity?.createdAt,
    pendingBillCount: pendingBillCount,
  );
}

extension MemberModelMapper on MemberModel {
  GroupMemberEntity toEntity() => GroupMemberEntity(
    // UI thao tác trên thành viên qua membership_id (xóa thành viên, chuyển
    // quyền), nên đó mới là định danh đúng, không phải user_id.
    id: membershipId,
    name: displayName,
    avatarUrl: avatarUrl,
    role: role == 'captain' ? GroupMemberRole.captain : GroupMemberRole.member,
  );
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d/$m/${local.year}';
}
