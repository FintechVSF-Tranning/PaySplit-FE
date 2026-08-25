import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/group_activity_entity.dart';
import '../entities/group_entity.dart';
import '../entities/group_member_entity.dart';

/// Một trang kết quả phân trang cursor của backend.
class GroupPage<T> {
  const GroupPage({required this.items, this.nextCursor});

  final List<T> items;

  /// `null` nghĩa là đã hết dữ liệu.
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}

/// Chi tiết nhóm trả về từ `GET /groups/{id}`.
class GroupDetailResult {
  const GroupDetailResult({
    required this.group,
    required this.members,
    required this.balances,
    required this.callerRole,
    this.activeBillFinalizeBatchId,
  });

  final GroupEntity group;
  final List<GroupMemberEntity> members;

  /// Số dư ròng theo `membership_id`.
  final Map<String, int> balances;
  final String callerRole;

  /// Chỉ Captain mới nhận được; `null` với thành viên thường hoặc khi không có
  /// batch chốt hóa đơn nào đang chạy.
  final String? activeBillFinalizeBatchId;

  bool get isCaptain => callerRole == 'captain';
}

/// Mã mời của nhóm.
class GroupInvite {
  const GroupInvite({
    required this.id,
    required this.code,
    required this.inviteUrl,
    required this.expiresAt,
    this.maxUses,
    this.useCount = 0,
  });

  final String id;
  final String code;
  final String inviteUrl;
  final DateTime expiresAt;
  final int? maxUses;
  final int useCount;
}

/// Thông tin xem trước nhóm trước khi tham gia bằng link/QR.
class GroupInvitePreview {
  const GroupInvitePreview({
    required this.groupName,
    required this.activeMemberCount,
    required this.captainDisplayName,
  });

  final String groupName;
  final int activeMemberCount;
  final String captainDisplayName;
}

/// Kết quả tham gia nhóm.
class GroupJoinResult {
  const GroupJoinResult({
    required this.groupId,
    required this.membershipId,
    required this.role,
    required this.result,
  });

  final String groupId;
  final String membershipId;
  final String role;

  /// `joined` | `already_member` | `reactivated`.
  final String result;
}

abstract class GroupRepository {
  Future<Either<Failure, GroupEntity>> createGroup({required String name});

  Future<Either<Failure, GroupPage<GroupEntity>>> listGroups({int? limit, String? cursor});

  Future<Either<Failure, GroupDetailResult>> getGroupDetail(String groupId);

  Future<Either<Failure, GroupEntity>> renameGroup(String groupId, String name);

  Future<Either<Failure, Unit>> disbandGroup(String groupId);

  Future<Either<Failure, List<GroupInvite>>> listInvites(String groupId);

  Future<Either<Failure, GroupInvite>> createInvite(
    String groupId, {
    int? expiresInHours,
    int? maxUses,
    bool? regenerate,
  });

  Future<Either<Failure, Unit>> revokeInvite(String groupId, String inviteId);

  Future<Either<Failure, GroupInvitePreview>> previewInvite(String code);

  Future<Either<Failure, GroupJoinResult>> joinGroup(String code);

  /// Dùng chung cho rời nhóm (tự xóa mình) và Captain xóa thành viên khác.
  Future<Either<Failure, Unit>> leaveOrRemoveMember(String groupId, String membershipId);

  Future<Either<Failure, Unit>> transferCaptain(String groupId, String membershipId);

  Future<Either<Failure, GroupPage<GroupActivityEntity>>> listActivities(
    String groupId, {
    int? limit,
    String? cursor,
  });
}
