import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/group_activity_entity.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_sync_entity.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/group_event_stream_datasource.dart';
import '../datasources/group_remote_datasource.dart';
import '../models/activity_mapper.dart';
import '../models/group_mapper.dart';
import '../models/group_models.dart';
import '../models/group_sync_models.dart';
import '../models/group_sync_mapper.dart';

@LazySingleton(as: GroupRepository)
class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl(this._remote, this._events);

  final GroupRemoteDataSource _remote;
  final GroupEventStreamDataSource _events;

  /// Bọc mọi lời gọi: [DioException] thành [Failure] tương ứng, còn body 2xx
  /// sai shape (ném [StateError]/[TypeError] khi đọc `data`) thành
  /// [invalidResponseFailure] thay vì thoát ra ngoài dưới dạng exception.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on DioException catch (e) {
      return Left(mapDioError(e));
    } catch (_) {
      return const Left(invalidResponseFailure);
    }
  }

  @override
  Future<Either<Failure, GroupEntity>> createGroup({required String name}) {
    return _guard(() async {
      final response = await _remote.createGroup({'name': name});
      final data = response.requireData;
      // Nhóm vừa tạo luôn có đúng người tạo làm Captain.
      return data.group.toEntity(memberCount: 1, isCaptain: true);
    });
  }

  @override
  Future<Either<Failure, GroupPage<GroupEntity>>> listGroups({
    int? limit,
    String? cursor,
  }) {
    return _guard(() async {
      final response = await _remote.listGroups(limit: limit, cursor: cursor);
      final data = response.requireData;
      return GroupPage(
        items: data.groups.map((item) => item.toEntity()).toList(),
        nextCursor: data.nextCursor,
      );
    });
  }

  @override
  Future<Either<Failure, GroupDetailResult>> getGroupDetail(String groupId) {
    return _guard(() async {
      final data = (await _remote.getGroupDetail(groupId)).requireData;
      final balances = <String, int>{
        for (final b in data.balances)
          b.memberId: int.tryParse(b.netBalance) ?? 0,
      };
      final isCaptain = data.callerRole == 'captain';
      // Số dư của chính người gọi: tìm membership của caller trong danh sách
      // thành viên qua vai trò là không đủ (nhiều member cùng vai trò), nên
      // dùng chênh lệch giữa balances và membership_id ở tầng gọi. Ở đây chỉ
      // dựng nhóm với sĩ số thật; myBalance do provider điền sau khi biết
      // membership_id của caller.
      return GroupDetailResult(
        group: data.group.toEntity(
          memberCount: data.members.length,
          isCaptain: isCaptain,
        ),
        members: data.members.map((m) => m.toEntity()).toList(),
        balances: balances,
        callerRole: data.callerRole,
        callerMembershipId: data.callerMembershipId,
        version: data.version,
        activeBillFinalizeBatchId: data.activeBillFinalizeBatchId,
        latestBillFinalizeBatchId: data.latestBillFinalizeBatchId,
      );
    });
  }

  @override
  Future<Either<Failure, GroupSyncResult>> syncGroup(
    String groupId, {
    required int since,
  }) {
    return _guard(() async {
      final data = (await _remote.syncGroup(groupId, since: since)).requireData;
      return data.toEntity();
    });
  }

  @override
  Stream<GroupSyncEvent> streamGroupEvents(
    String groupId, {
    required int since,
  }) {
    // Stream cố ý KHÔNG bọc Either: lỗi ở đây là "kết nối đứt", không phải một
    // kết quả nghiệp vụ. Tầng gọi bắt lỗi để quyết định backoff, và dữ liệu
    // đúng vẫn về được qua syncGroup.
    return _events.stream(groupId, since: since).expand((frame) {
      switch (frame.event) {
        case 'snapshot':
        case 'sync':
        case 'heartbeat':
        case 'close':
          // Ba loại này không phải sự kiện nhật ký. Snapshot ban đầu được lấy
          // qua getGroupDetail trước khi mở stream, nên ở đây chỉ cần bỏ qua.
          return const <GroupSyncEvent>[];
        default:
          // Thân frame mang đúng shape với phần tử events của /sync, nên dùng
          // lại một hàm giải mã cho cả hai kênh.
          if (frame.data['version'] is! num) return const <GroupSyncEvent>[];
          return [GroupSyncEventModel.fromJson(frame.data).toEntity()];
      }
    });
  }

  @override
  Future<Either<Failure, GroupEntity>> renameGroup(
    String groupId,
    String name,
  ) {
    return _guard(() async {
      final data = (await _remote.renameGroup(groupId, {
        'name': name,
      })).requireData;
      return data.group.toEntity();
    });
  }

  @override
  Future<Either<Failure, Unit>> disbandGroup(String groupId) {
    return _guard(() async {
      await _remote.disbandGroup(groupId);
      return unit;
    });
  }

  @override
  Future<Either<Failure, List<GroupInvite>>> listInvites(String groupId) {
    return _guard(() async {
      final data = (await _remote.listInvites(groupId)).requireData;
      return data.invites.map(_toInvite).toList();
    });
  }

  @override
  Future<Either<Failure, GroupInvite>> createInvite(
    String groupId, {
    int? expiresInHours,
    int? maxUses,
    bool? regenerate,
  }) {
    return _guard(() async {
      final body = <String, dynamic>{};
      if (expiresInHours != null) body['expires_in_hours'] = expiresInHours;
      if (maxUses != null) body['max_uses'] = maxUses;
      if (regenerate != null) body['regenerate'] = regenerate;
      final data = (await _remote.createInvite(groupId, body)).requireData;
      return _toInvite(data.invite);
    });
  }

  @override
  Future<Either<Failure, Unit>> revokeInvite(String groupId, String inviteId) {
    return _guard(() async {
      await _remote.revokeInvite(groupId, inviteId);
      return unit;
    });
  }

  @override
  Future<Either<Failure, GroupInvitePreview>> previewInvite(String code) {
    return _guard(() async {
      final data = (await _remote.previewInvite(code)).requireData;
      return GroupInvitePreview(
        groupName: data.preview.groupName,
        activeMemberCount: data.preview.activeMemberCount,
        captainDisplayName: data.preview.captainDisplayName,
      );
    });
  }

  @override
  Future<Either<Failure, GroupJoinResult>> joinGroup(String code) {
    return _guard(() async {
      final data = (await _remote.joinGroup({'code': code})).requireData;
      return GroupJoinResult(
        groupId: data.joinResult.groupId,
        membershipId: data.joinResult.membershipId,
        role: data.joinResult.role,
        result: data.joinResult.result,
      );
    });
  }

  @override
  Future<Either<Failure, Unit>> leaveOrRemoveMember(
    String groupId,
    String membershipId,
  ) {
    return _guard(() async {
      await _remote.leaveOrRemoveMember(groupId, membershipId);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> transferCaptain(
    String groupId,
    String membershipId,
  ) {
    return _guard(() async {
      await _remote.transferRole(groupId, membershipId, {'role': 'captain'});
      return unit;
    });
  }

  @override
  Future<Either<Failure, GroupPage<GroupActivityEntity>>> listActivities(
    String groupId, {
    int? limit,
    String? cursor,
  }) {
    return _guard(() async {
      final data = (await _remote.listActivities(
        groupId,
        limit: limit,
        cursor: cursor,
      )).requireData;
      return GroupPage(
        items: data.activities.map((a) => a.toEntity()).toList(),
        nextCursor: data.nextCursor,
      );
    });
  }

  @override
  Future<Either<Failure, DateTime>> lockBillSubmissions(String groupId) {
    return _guard(() async {
      final data = (await _remote.lockBillSubmissions(
        groupId,
        idempotencyKey: const Uuid().v4(),
      )).requireData;
      return data.lockedAt ?? DateTime.now();
    });
  }

  @override
  Future<Either<Failure, Unit>> unlockBillSubmissions(String groupId) {
    return _guard(() async {
      await _remote.unlockBillSubmissions(groupId);
      return unit;
    });
  }

  GroupInvite _toInvite(InviteModel m) => GroupInvite(
    id: m.id,
    code: m.code,
    inviteUrl: m.inviteUrl,
    expiresAt: m.expiresAt,
    maxUses: m.maxUses,
    useCount: m.useCount,
  );
}
