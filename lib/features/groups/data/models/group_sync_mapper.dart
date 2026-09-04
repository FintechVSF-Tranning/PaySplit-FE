import '../../domain/entities/group_member_entity.dart';
import '../../domain/entities/group_sync_entity.dart';
import 'group_mapper.dart';
import 'group_models.dart';
import 'group_sync_models.dart';

/// Quy đổi DTO đồng bộ sang entity. Payload của sự kiện là map không định kiểu
/// vì hình dạng phụ thuộc `type`, nên mọi truy cập ở đây đều phải chịu được
/// field thiếu: một envelope bị cắt vẫn phải tạo ra event hợp lệ mang version.
extension GroupSyncEventModelMapper on GroupSyncEventModel {
  GroupSyncEvent toEntity() {
    final parsed = GroupSyncEventType.parse(type);
    return GroupSyncEvent(
      version: version,
      type: parsed,
      member: _member(),
      membershipId: data['membership_id'] as String?,
      userId: data['user_id'] as String?,
      previousCaptainMembershipId: data['previous_captain_membership_id'] as String?,
      currentCaptainMembershipId: data['current_captain_membership_id'] as String?,
      groupName: data['name'] as String?,
      activeMemberCount: (data['active_member_count'] as num?)?.toInt(),
    );
  }

  GroupMemberEntity? _member() {
    final raw = data['member'];
    if (raw is! Map<String, dynamic>) return null;
    final membershipId = raw['membership_id'] as String?;
    final displayName = raw['display_name'] as String?;
    if (membershipId == null || displayName == null) return null;
    return GroupMemberEntity(
      // UI thao tác trên thành viên qua membership_id, giống MemberModelMapper.
      id: membershipId,
      name: displayName,
      avatarUrl: raw['avatar_url'] as String?,
      role: raw['role'] == 'captain' ? GroupMemberRole.captain : GroupMemberRole.member,
    );
  }
}

extension GroupDetailSnapshotMapper on GroupDetailResponseModel {
  GroupRosterSnapshot toRosterSnapshot() => GroupRosterSnapshot(
    version: version,
    members: members.map((m) => m.toEntity()).toList(),
    callerRole: callerRole,
    callerMembershipId: callerMembershipId,
    groupName: group.name,
  );
}

extension GroupSyncResponseModelMapper on GroupSyncResponseModel {
  GroupSyncResult toEntity() {
    final snapshot = this.snapshot;
    if (mode == GroupSyncResponseModel.modeSnapshot && snapshot != null) {
      return GroupSyncResult.snapshot(version: version, snapshot: snapshot.toRosterSnapshot());
    }
    return GroupSyncResult.delta(
      version: version,
      events: events.map((e) => e.toEntity()).toList(),
    );
  }
}
