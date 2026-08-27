import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/utils/currency_formatter.dart';
import 'package:paysplit/features/groups/data/models/activity_mapper.dart';
import 'package:paysplit/features/groups/data/models/group_mapper.dart';
import 'package:paysplit/features/groups/data/models/group_models.dart';
import 'package:paysplit/features/groups/domain/entities/group_activity_entity.dart';

void main() {
  group('formatActivityTitle', () {
    test('formats historical bill activities to Vietnamese', () {
      expect(
        formatActivityTitle('finalized bill (total 207021 VND)'),
        'Đã chốt hóa đơn (tổng ${CurrencyFormatter.formatVND(207021)})',
      );
      expect(
        formatActivityTitle('reviewed bill (version 6)'),
        'Đã duyệt hóa đơn (phiên bản 6)',
      );
      expect(
        formatActivityTitle('updated bill draft (version 5)'),
        'Đã cập nhật hóa đơn (phiên bản 5)',
      );
      expect(
        formatActivityTitle('created bill draft "Highlands Coffee"'),
        'Đã tạo hóa đơn nháp "Highlands Coffee"',
      );
      expect(
        formatActivityTitle('voided bill: Wrong receipt'),
        'Đã hủy hóa đơn: Wrong receipt',
      );
    });

    test('formats debt reminders and payment activities to Vietnamese', () {
      expect(
        formatActivityTitle('Debt reminder sent'),
        'Đã gửi lời nhắc thanh toán',
      );
      expect(
        formatActivityTitle('Automated debt reminder sent'),
        'Hệ thống đã tự động gửi nhắc nợ',
      );
      expect(
        formatActivityTitle('Payment QR created'),
        'Đã tạo mã QR thanh toán',
      );
      expect(
        formatActivityTitle('Payment proof submitted'),
        'Đã gửi minh chứng thanh toán',
      );
      expect(
        formatActivityTitle('Payment confirmed'),
        'Đã xác nhận thanh toán',
      );
      expect(
        formatActivityTitle('Payment rejected: Invalid transfer'),
        'Đã từ chối minh chứng thanh toán: Invalid transfer',
      );
    });

    test('formats group lifecycle and member activities to Vietnamese', () {
      expect(
        formatActivityTitle('Alice created the group "Trip Đà Lạt"'),
        'Alice đã tạo nhóm "Trip Đà Lạt"',
      );
      expect(
        formatActivityTitle('Bob joined the group'),
        'Bob đã tham gia nhóm',
      );
      expect(
        formatActivityTitle('Charlie left the group'),
        'Charlie đã rời nhóm',
      );
      expect(
        formatActivityTitle('Alice transferred the Captain role'),
        'Alice đã chuyển quyền Trưởng nhóm',
      );
    });

    test('capitalizes first letter for Vietnamese descriptions', () {
      expect(
        formatActivityTitle('đã khóa gửi hóa đơn mới cho nhóm'),
        'Đã tạm khóa nhận hóa đơn mới cho nhóm',
      );
      expect(
        formatActivityTitle('đã mở khóa gửi hóa đơn cho nhóm'),
        'Đã mở khóa nhận hóa đơn cho nhóm',
      );
      expect(
        formatActivityTitle('đã chốt hóa đơn "Ăn trưa" (tổng 207.021 đ)'),
        'Đã chốt hóa đơn "Ăn trưa" (tổng 207.021 đ)',
      );
      expect(
        formatActivityTitle('Đã cập nhật hóa đơn "Highlands" (phiên bản 3)'),
        'Đã cập nhật hóa đơn "Highlands" (phiên bản 3)',
      );
    });
  });

  group('ActivityModelMapper.toEntity', () {
    test('maps model to entity with formatted title and proper kind', () {
      final model = ActivityModel(
        id: 'act-1',
        actionType: 'finalized_bill',
        description: 'finalized bill (total 207021 VND)',
        actor: const ActivityActorModel(
          memberId: 'mem-1',
          userId: 'usr-1',
          displayName: 'User 1',
        ),
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      final entity = model.toEntity();
      expect(entity.id, 'act-1');
      expect(entity.title, 'Đã chốt hóa đơn (tổng ${CurrencyFormatter.formatVND(207021)})');
      expect(entity.subtitle, 'User 1');
      expect(entity.kind, GroupActivityKind.bill);
      expect(entity.timeText, '5 phút trước');
    });
  });

  group('GroupListItemModelMapper.toEntity', () {
    test('formats card preview lastActivity to Vietnamese and sentence case', () {
      final now = DateTime.now();
      final item1 = GroupListItemModel(
        group: GroupModel(
          id: 'grp-1',
          name: 'Ăn trưa 27/8',
          currency: 'VND',
          createdAt: now,
        ),
        callerMembershipId: 'mem-1',
        activeMemberCount: 3,
        callerRole: 'member',
        callerNetBalance: '-47983',
        pendingBillCount: 1,
        lastActivity: ActivitySummaryModel(
          description: 'đã khóa gửi hóa đơn mới cho nhóm',
          createdAt: now,
        ),
      );

      final entity1 = item1.toEntity();
      expect(entity1.lastActivity, 'Đã tạm khóa nhận hóa đơn mới cho nhóm');

      final item2 = GroupListItemModel(
        group: GroupModel(
          id: 'grp-2',
          name: 'Du lịch tháng 8',
          currency: 'VND',
          createdAt: now,
        ),
        callerMembershipId: 'mem-2',
        activeMemberCount: 2,
        callerRole: 'captain',
        callerNetBalance: '5000000',
        lastActivity: ActivitySummaryModel(
          description: 'Payment QR created',
          createdAt: now,
        ),
      );

      final entity2 = item2.toEntity();
      expect(entity2.lastActivity, 'Đã tạo mã QR thanh toán');
    });
  });
}
