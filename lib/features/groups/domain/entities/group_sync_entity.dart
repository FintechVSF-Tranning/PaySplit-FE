import 'package:equatable/equatable.dart';

import 'group_member_entity.dart';

/// Các loại sự kiện đồng bộ nhóm. Khớp đúng hằng số phía backend.
enum GroupSyncEventType {
  memberJoined,
  memberReactivated,
  memberLeft,
  memberRemoved,
  captainTransferred,
  groupRenamed,
  groupArchived,

  /// Loại sự kiện backend thêm sau này mà client chưa biết. Vẫn phải tiến
  /// version, nếu không client sẽ tưởng mình đang có lỗ hổng và gọi `/sync`
  /// vô hạn.
  unknown;

  static GroupSyncEventType parse(String raw) => switch (raw) {
    'member_joined' => GroupSyncEventType.memberJoined,
    'member_reactivated' => GroupSyncEventType.memberReactivated,
    'member_left' => GroupSyncEventType.memberLeft,
    'member_removed' => GroupSyncEventType.memberRemoved,
    'captain_transferred' => GroupSyncEventType.captainTransferred,
    'group_renamed' => GroupSyncEventType.groupRenamed,
    'group_archived' => GroupSyncEventType.groupArchived,
    _ => GroupSyncEventType.unknown,
  };
}

/// Một sự kiện đã giải mã, đủ để áp thẳng vào state mà không cần gọi lại API.
class GroupSyncEvent extends Equatable {
  const GroupSyncEvent({
    required this.version,
    required this.type,
    this.member,
    this.membershipId,
    this.userId,
    this.previousCaptainMembershipId,
    this.currentCaptainMembershipId,
    this.groupName,
    this.activeMemberCount,
  });

  final int version;
  final GroupSyncEventType type;

  /// Có ở [GroupSyncEventType.memberJoined] và [GroupSyncEventType.memberReactivated].
  final GroupMemberEntity? member;

  /// Có ở [GroupSyncEventType.memberLeft] và [GroupSyncEventType.memberRemoved].
  final String? membershipId;
  final String? userId;

  final String? previousCaptainMembershipId;
  final String? currentCaptainMembershipId;
  final String? groupName;

  /// Sĩ số sau khi sự kiện đã áp — để màn danh sách nhóm không phải gọi thêm API.
  final int? activeMemberCount;

  /// Payload bị cắt (envelope quá lớn) hoặc loại sự kiện chưa biết: chỉ tiến
  /// version, mọi thay đổi thật sẽ đến qua một lần `/sync`.
  bool get isOpaque =>
      type == GroupSyncEventType.unknown ||
      (member == null &&
          membershipId == null &&
          groupName == null &&
          type != GroupSyncEventType.groupArchived);

  @override
  List<Object?> get props => [version, type, membershipId, member];
}

/// Trạng thái roster của một nhóm tại một version xác định.
class GroupRosterSnapshot extends Equatable {
  const GroupRosterSnapshot({
    required this.version,
    required this.members,
    required this.callerRole,
    this.callerMembershipId = '',
    this.groupName,
  });

  final int version;
  final List<GroupMemberEntity> members;
  final String callerRole;
  final String callerMembershipId;
  final String? groupName;

  bool get isCaptain => callerRole == 'captain';

  @override
  List<Object?> get props => [version, members, callerRole, callerMembershipId, groupName];
}

/// Kết quả một lần catch-up: hoặc các sự kiện còn thiếu, hoặc một snapshot thay
/// thế toàn bộ state.
class GroupSyncResult extends Equatable {
  const GroupSyncResult.delta({required this.version, required this.events}) : snapshot = null;

  const GroupSyncResult.snapshot({
    required this.version,
    required GroupRosterSnapshot this.snapshot,
  }) : events = const <GroupSyncEvent>[];

  final int version;
  final List<GroupSyncEvent> events;
  final GroupRosterSnapshot? snapshot;

  bool get isSnapshot => snapshot != null;

  @override
  List<Object?> get props => [version, events, snapshot];
}
