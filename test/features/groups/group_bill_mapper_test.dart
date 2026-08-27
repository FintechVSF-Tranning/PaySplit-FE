import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/bills/data/models/bill_list_page_model.dart';
import 'package:paysplit/features/bills/data/models/bill_model.dart';
import 'package:paysplit/features/bills/domain/entities/bill_entity.dart';
import 'package:paysplit/features/groups/data/models/group_bill_mapper.dart';
import 'package:paysplit/features/groups/domain/entities/group_bill_entity.dart';

void main() {
  group('BillListPageModel (counts của chip lọc)', () {
    test('đọc counts và next_cursor từ data của GET /api/v1/bills', () {
      final page = BillListPageModel.fromJson({
        'bills': [
          {
            'id': 'bill-1',
            'merchant_name': 'Quán ăn',
            'total': 100000,
            'status': 'voided',
            'created_at': '2026-08-26T14:24:00Z',
          },
        ],
        'counts': {
          'draft': 45,
          'reviewed': 0,
          'finalized': 40,
          'voided': 9,
          'total': 94,
        },
        'next_cursor': 'abc',
      }).toEntity().toGroupBillsPage();

      expect(page.bills.single.status, GroupBillStatus.voided);
      expect(page.countFor(GroupBillFilter.all), 94);
      expect(page.countFor(GroupBillFilter.draft), 45);
      expect(page.countFor(GroupBillFilter.reviewed), 0);
      expect(page.countFor(GroupBillFilter.finalized), 40);
      expect(page.countFor(GroupBillFilter.voided), 9);
      expect(page.nextCursor, 'abc');
    });

    test('BE chưa trả counts thì tổng lấy theo số bản ghi đã tải', () {
      final page = BillListPageModel.fromJson({
        'bills': [
          {'id': 'b1', 'status': 'draft', 'created_at': '2026-08-26T14:24:00Z'},
          {'id': 'b2', 'status': 'draft', 'created_at': '2026-08-26T14:24:00Z'},
        ],
      }).toEntity().toGroupBillsPage();

      expect(page.countFor(GroupBillFilter.all), 2);
      expect(page.countFor(GroupBillFilter.finalized), 0);
    });
  });

  group('BillModel.fromJson (contract GET /api/v1/bills)', () {
    test('đọc đúng các field của BillListItem từ backend', () {
      final model = BillModel.fromJson({
        'id': 'bill-1',
        'group_id': 'group-1',
        'merchant_name': 'BÁCH HÓA XANH',
        'total': 322130,
        'status': 'finalized',
        'created_at': '2026-08-26T14:24:00Z',
        'payer_display_name': 'Le Van Cuong',
        'paid_member_count': 2,
        'member_count': 3,
      });

      final entity = model.toEntity();
      expect(entity.title, 'BÁCH HÓA XANH');
      expect(entity.totalAmount, 322130);
      expect(entity.status, BillStatus.finalized);
      expect(entity.payerName, 'Le Van Cuong');
      expect(entity.paidMemberCount, 2);
      expect(entity.memberCount, 3);
    });

    test('hóa đơn chưa có tên quán vẫn có tiêu đề hiển thị', () {
      final entity = BillModel.fromJson({
        'id': 'bill-2',
        'status': 'draft',
        'created_at': '2026-08-26T14:24:00Z',
      }).toEntity();

      expect(entity.title, 'Hóa đơn chưa đặt tên');
      expect(entity.status, BillStatus.draft);
    });
  });

  group('BillEntity.toGroupBill', () {
    BillEntity billWith(BillStatus status) => BillEntity(
      id: 'b',
      groupId: 'g',
      title: 'Quán ăn',
      totalAmount: 100000,
      status: status,
      createdAt: DateTime(2026, 8, 26, 14, 24),
      payerName: 'Cuong',
      paidMemberCount: 1,
      memberCount: 3,
    );

    test('4 trạng thái backend map 1-1 sang trạng thái hiển thị', () {
      expect(
        billWith(BillStatus.draft).toGroupBill().status,
        GroupBillStatus.draft,
      );
      expect(
        billWith(BillStatus.reviewed).toGroupBill().status,
        GroupBillStatus.reviewed,
      );
      expect(
        billWith(BillStatus.finalized).toGroupBill().status,
        GroupBillStatus.finalized,
      );
      expect(
        billWith(BillStatus.voided).toGroupBill().status,
        GroupBillStatus.voided,
      );
    });

    test('nhãn tiếng Việt của từng trạng thái', () {
      expect(GroupBillStatus.draft.label, 'Nháp');
      expect(GroupBillStatus.reviewed.label, 'Chờ duyệt');
      expect(GroupBillStatus.finalized.label, 'Đã chốt');
      expect(GroupBillStatus.voided.label, 'Đã hủy');
    });

    test('bộ lọc có đủ 5 chip và gửi đúng ?status= lên backend', () {
      expect(GroupBillFilter.values.map((f) => f.label).toList(), [
        'Tất cả',
        'Nháp',
        'Chờ duyệt',
        'Đã chốt',
        'Đã hủy',
      ]);
      expect(GroupBillFilter.all.apiStatuses, isEmpty);
      expect(GroupBillFilter.draft.apiStatuses, ['draft']);
      expect(GroupBillFilter.reviewed.apiStatuses, ['reviewed']);
      expect(GroupBillFilter.finalized.apiStatuses, ['finalized']);
      expect(GroupBillFilter.voided.apiStatuses, ['voided']);
    });

    test('thiếu tên người trả thì hiển thị nhãn mặc định', () {
      final bill = billWith(BillStatus.draft).copyWith(payerName: '');
      expect(bill.toGroupBill().payerName, 'Thành viên nhóm');
    });
  });
}
