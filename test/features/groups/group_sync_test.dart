import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/groups/data/datasources/group_event_stream_datasource.dart';
import 'package:paysplit/features/groups/data/models/group_sync_mapper.dart';
import 'package:paysplit/features/groups/data/models/group_sync_models.dart';
import 'package:paysplit/features/groups/domain/entities/group_member_entity.dart';
import 'package:paysplit/features/groups/domain/entities/group_sync_entity.dart';

void main() {
  group('parseSseLines', () {
    test('tách đúng nhiều frame liên tiếp và bỏ qua id/comment', () async {
      final frames = await parseSseLines(
        Stream.fromIterable([
          ': keep-alive',
          'id: 43',
          'event: member_joined',
          'data: {"version":43,"type":"member_joined","data":{"member":{"display_name":"Nam"}}}',
          '',
          'id: 44',
          'event: member_left',
          'data: {"version":44,"type":"member_left","data":{"membership_id":"m1"}}',
          '',
        ]),
      ).toList();

      expect(frames.length, 2);
      expect(frames.first.event, 'member_joined');
      expect(frames.first.data['version'], 43);
      expect(frames.last.event, 'member_left');
      expect(frames.last.data['version'], 44);
    });

    test('frame chưa kết thúc bằng dòng trống thì không được phát ra', () async {
      final frames = await parseSseLines(
        Stream.fromIterable(['event: member_joined', 'data: {"version":1,"type":"x"}']),
      ).toList();

      // Kết nối đứt giữa chừng: phát ra một frame chưa trọn vẹn còn tệ hơn là
      // không phát gì, vì client sẽ tiến version dựa trên dữ liệu thiếu.
      expect(frames, isEmpty);
    });

    test('heartbeat không được lẫn vào frame sự kiện phía sau', () async {
      final frames = await parseSseLines(
        Stream.fromIterable([
          'event: heartbeat',
          'data: {"timestamp":1}',
          '',
          'data: {"version":9,"type":"group_renamed","data":{"name":"Mới"}}',
          '',
        ]),
      ).toList();

      expect(frames.map((f) => f.event).toList(), ['heartbeat', 'message']);
      expect(frames.last.data['version'], 9);
    });
  });

  group('GroupSyncEventModel.toEntity', () {
    test('member_joined mang đủ dữ liệu để chèn thẳng vào danh sách', () {
      final event = GroupSyncEventModel(
        version: 12,
        type: 'member_joined',
        data: const {
          'member': {
            'membership_id': 'm-1',
            'user_id': 'u-1',
            'display_name': 'Nam',
            'avatar_url': 'https://cdn.test/nam.webp',
            'role': 'member',
          },
          'active_member_count': 4,
        },
      ).toEntity();

      expect(event.type, GroupSyncEventType.memberJoined);
      expect(event.isOpaque, isFalse);
      // UI thao tác qua membership_id, nên đó phải là id của entity.
      expect(event.member!.id, 'm-1');
      expect(event.member!.name, 'Nam');
      expect(event.member!.role, GroupMemberRole.member);
      expect(event.activeMemberCount, 4);
    });

    test('loại sự kiện chưa biết vẫn giữ version và bị đánh dấu opaque', () {
      final event = GroupSyncEventModel(version: 30, type: 'emoji_changed').toEntity();

      expect(event.version, 30);
      expect(event.type, GroupSyncEventType.unknown);
      // Opaque nghĩa là "tiến version rồi catch-up", không phải "bỏ qua".
      expect(event.isOpaque, isTrue);
    });

    test('payload bị cắt vẫn tạo ra event hợp lệ mang version', () {
      final event = GroupSyncEventModel(version: 31, type: 'member_joined').toEntity();

      expect(event.version, 31);
      expect(event.type, GroupSyncEventType.memberJoined);
      expect(event.member, isNull);
      expect(event.isOpaque, isTrue);
    });
  });

  group('GroupSyncResponseModel.toEntity', () {
    test('mode snapshot mang roster thay thế toàn bộ', () {
      final result = GroupSyncResponseModel.fromJson(const {
        'version': 8,
        'mode': 'snapshot',
        'snapshot': {
          'group': {'id': 'g1', 'name': 'Đà Lạt', 'currency': 'VND', 'created_at': '2026-08-01T00:00:00Z'},
          'members': [
            {
              'membership_id': 'm-1',
              'user_id': 'u-1',
              'display_name': 'Captain',
              'role': 'captain',
              'joined_at': '2026-08-01T00:00:00Z',
            },
          ],
          'caller_role': 'captain',
          'caller_membership_id': 'm-1',
          'version': 8,
        },
      }).toEntity();

      expect(result.isSnapshot, isTrue);
      expect(result.version, 8);
      expect(result.snapshot!.members.single.id, 'm-1');
      expect(result.snapshot!.callerMembershipId, 'm-1');
      expect(result.snapshot!.isCaptain, isTrue);
    });

    test('mode delta rỗng nghĩa là client đã bắt kịp', () {
      final result = GroupSyncResponseModel.fromJson(const {
        'version': 8,
        'mode': 'delta',
        'events': <Map<String, dynamic>>[],
      }).toEntity();

      expect(result.isSnapshot, isFalse);
      expect(result.events, isEmpty);
      expect(result.version, 8);
    });
  });
}
