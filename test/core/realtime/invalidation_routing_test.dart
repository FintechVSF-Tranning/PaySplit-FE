import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/realtime/realtime_interest.dart';
import 'package:paysplit/core/realtime/realtime_interest_registry.dart';
import 'package:paysplit/core/realtime/sse_frame.dart';
import 'package:paysplit/core/realtime/user_realtime_owner.dart';

const _groupId = 'g1';
const _billId = 'b1';

/// Mọi surface mà app có thể đăng ký, cùng gắn vào một nhóm và một hóa đơn.
///
/// Dựng đủ bộ chứ không chỉ surface đang quan tâm: một mapping bị thiếu chỉ lộ
/// ra khi surface đó thực sự có mặt trong registry lúc sự kiện tới.
RealtimeInterestRegistry _fullRegistry() {
  final registry = RealtimeInterestRegistry();
  for (final key in <RealtimeInterestKey>[
    RealtimeInterestKey.homeGroups(),
    RealtimeInterestKey.homeActivities(),
    RealtimeInterestKey.groupsIndex(),
    RealtimeInterestKey.settlementOverview(),
    RealtimeInterestKey.groupRoster(_groupId),
    RealtimeInterestKey.groupDetail(_groupId),
    RealtimeInterestKey.groupDebts(_groupId),
    RealtimeInterestKey.groupActivities(_groupId),
    RealtimeInterestKey.groupBills(_groupId, 'all'),
    RealtimeInterestKey.billDetail(_groupId, _billId),
    RealtimeInterestKey.ocrWaiter(_groupId, _billId),
  ]) {
    registry.register(RealtimeInterest(key: key, refresh: () async {}));
  }
  return registry;
}

Set<String> _surfacesFor(String type) {
  final registry = _fullRegistry();
  return UserRealtimeOwner()
      .targetsFor(
        SseFrame(
          event: 'invalidate',
          data: {
            'scope': 'group',
            'group_id': _groupId,
            'resource_id': _billId,
            'type': type,
          },
        ),
        registryOverride: registry,
      )
      .map((interest) => interest.key.surface)
      .toSet();
}

/// Mutation hóa đơn làm đổi `pending_bill_count`, tức số bill mở mà danh sách
/// nhóm hiển thị. Backend đếm `status NOT IN ('finalized','voided')`, nên tạo
/// mới cộng một, còn xóa/chốt/hủy trừ một.
const _openBillCountChangingMutations = <String>[
  'bill.created',
  'bill.deleted',
  'bill.finalized',
  'bill.voided',
];

/// Mọi loại sự kiện bảng định tuyến biết xử lý.
const _allEventTypes = <String>[
  'bill.created',
  'bill.content_changed',
  'bill.reviewed',
  'bill.deleted',
  'bill.finalized',
  'bill.voided',
  'group.bill_submission_locked',
  'home.balance_changed',
  'group.debts_changed',
  'bill.settlement_changed',
  'settlement.payment_changed',
  'settlement.debt_reminded',
  'group.activity_changed',
  'some.unknown.type',
];

void main() {
  test('bill version filters echoes without suppressing dependent changes', () {
    final registry = _fullRegistry();
    var currentVersion = 5;
    registry.register(
      RealtimeInterest(
        key: RealtimeInterestKey.billDetail(_groupId, _billId),
        resourceVersion: () => currentVersion,
      ),
    );
    Set<String> targets(
      String type, {
      int? version,
      String event = 'invalidate',
    }) => UserRealtimeOwner()
        .targetsFor(
          SseFrame(
            event: event,
            data: {
              'type': type,
              'group_id': _groupId,
              'resource_id': _billId,
              'bill_id': _billId,
              'resource_version': ?version,
            },
          ),
          registryOverride: registry,
        )
        .map((i) => i.key.surface)
        .toSet();
    for (final version in [4, 5]) {
      expect(
        targets('bill.content_changed', version: version),
        isNot(contains('bill.detail')),
      );
      expect(
        targets('bill.content_changed', version: version),
        contains('group.bills'),
      );
    }
    expect(
      targets('bill.content_changed', version: 6),
      contains('bill.detail'),
    );
    currentVersion = 6;
    expect(
      targets('bill.content_changed', version: 6),
      isNot(contains('bill.detail')),
    );
    expect(targets('bill.content_changed'), contains('bill.detail'));
    expect(targets('bill.deleted', version: 6), contains('bill.detail'));
    expect(
      targets('bill.settlement_changed', version: 6),
      contains('bill.detail'),
    );
    expect(
      targets('', event: 'ocr.updated', version: 6),
      contains('bill.detail'),
    );
  });

  group('bảng định tuyến invalidation', () {
    test('mọi mutation làm đổi số bill mở đều làm mới danh sách nhóm', () {
      // covers: AC-18, AC-22
      for (final type in _openBillCountChangingMutations) {
        final surfaces = _surfacesFor(type);
        expect(
          surfaces,
          contains('groups.index'),
          reason:
              '$type đổi pending_bill_count; màn Danh sách nhóm đọc chính con '
              'số đó nên phải được làm mới',
        );
        expect(
          surfaces,
          contains('home.groups'),
          reason: '$type cũng đổi tóm tắt nhóm trên màn hình chính',
        );
      }
    });

    test('home.groups và groups.index luôn đi cùng nhau', () {
      // covers: AC-18
      // Hai surface này gọi đúng cùng một endpoint `GET /groups` và hiển thị
      // cùng một payload; chỉ khác `limit`. Làm mới cái này mà bỏ cái kia là
      // để một trong hai màn hình đứng yên với số liệu cũ.
      for (final type in _allEventTypes) {
        final surfaces = _surfacesFor(type);
        if (!surfaces.contains('home.groups')) continue;
        expect(
          surfaces,
          contains('groups.index'),
          reason: '$type làm mới home.groups nhưng bỏ quên groups.index',
        );
      }
    });

    test('xóa hóa đơn làm mới cả danh sách hóa đơn của nhóm', () {
      // covers: AC-18
      expect(_surfacesFor('bill.deleted'), contains('group.bills'));
    });

    test('ocr.updated làm mới cả tab hóa đơn của nhóm', () {
      // covers: AC-18
      // Thẻ hóa đơn trong tab nhóm hiện spinner "Đang quét..." theo `ocr_status`.
      // Job OCR kết thúc không đụng vào bảng `bills` nên không có mutation nào
      // khác được phát; `ocr.updated` là sự kiện duy nhất tắt được spinner đó.
      final surfaces = UserRealtimeOwner()
          .targetsFor(
            SseFrame(
              event: 'ocr.updated',
              data: {
                'group_id': _groupId,
                'bill_id': _billId,
                'status': 'failed',
              },
            ),
            registryOverride: _fullRegistry(),
          )
          .map((interest) => interest.key.surface)
          .toSet();

      expect(surfaces, contains('group.bills'));
      expect(surfaces, contains('ocr.waiter'));
      expect(surfaces, contains('bill.detail'));
    });

    test('mọi mutation hóa đơn đều làm mới danh sách hóa đơn của nhóm', () {
      // covers: AC-18
      for (final type in const [
        'bill.created',
        'bill.content_changed',
        'bill.reviewed',
        'bill.deleted',
        'bill.finalized',
        'bill.voided',
        'bill.settlement_changed',
      ]) {
        expect(
          _surfacesFor(type),
          contains('group.bills'),
          reason: '$type phải làm mới danh sách hóa đơn đang mở',
        );
      }
    });
  });
}
