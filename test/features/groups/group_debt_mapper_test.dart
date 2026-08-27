import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/groups/data/models/group_debt_mapper.dart';
import 'package:paysplit/features/groups/domain/entities/group_debt_entity.dart';

const _me = 'member-me';
const _lam = 'member-lam';
const _an = 'member-an';

RawGroupDebt debt({
  required String id,
  required String debtor,
  required String creditor,
  required int amount,
  String status = 'awaiting',
}) {
  return RawGroupDebt(
    id: id,
    debtorId: debtor,
    debtorName: debtor == _me
        ? 'Tôi'
        : debtor == _lam
        ? 'Lâm'
        : 'An',
    creditorId: creditor,
    creditorName: creditor == _me
        ? 'Tôi'
        : creditor == _lam
        ? 'Lâm'
        : 'An',
    amount: amount,
    status: status,
    billTitle: 'Hóa đơn',
  );
}

void main() {
  group('buildGroupDebtsView', () {
    test('cộng dồn nhiều hóa đơn của cùng một người thành một dòng', () {
      final view = buildGroupDebtsView(
        raw: [
          debt(id: 'd1', debtor: _me, creditor: _lam, amount: 50000),
          debt(id: 'd2', debtor: _me, creditor: _lam, amount: 30000),
        ],
        callerMembershipId: _me,
      );

      expect(view.debts, hasLength(1));
      expect(view.debts.single.amount, 80000);
      expect(view.debts.single.direction, DebtDirection.iOwe);
      expect(view.debtIdsByCounterpart[_lam], ['d1', 'd2']);
    });

    test('nợ hai chiều với cùng một người được bù trừ, chỉ còn một dòng', () {
      final view = buildGroupDebtsView(
        raw: [
          debt(id: 'd1', debtor: _me, creditor: _lam, amount: 100000),
          debt(id: 'd2', debtor: _lam, creditor: _me, amount: 30000),
        ],
        callerMembershipId: _me,
      );

      expect(view.debts, hasLength(1));
      expect(view.debts.single.direction, DebtDirection.iOwe);
      expect(view.debts.single.amount, 70000);
    });

    test('khoản đã tất toán hoặc đã hủy không còn là việc phải làm', () {
      final view = buildGroupDebtsView(
        raw: [
          debt(id: 'd1', debtor: _me, creditor: _lam, amount: 50000, status: 'settled'),
          debt(id: 'd2', debtor: _me, creditor: _lam, amount: 20000, status: 'voided'),
        ],
        callerMembershipId: _me,
      );

      expect(view.debts, isEmpty);
      expect(view.matrix, isEmpty);
    });

    test('minh chứng chờ duyệt chỉ đánh dấu khi người khác trả tôi', () {
      final view = buildGroupDebtsView(
        raw: [
          debt(
            id: 'd1',
            debtor: _lam,
            creditor: _me,
            amount: 60000,
            status: 'pending_confirmation',
          ),
        ],
        callerMembershipId: _me,
      );

      expect(view.debts.single.direction, DebtDirection.owesMe);
      expect(view.debts.single.hasPendingProof, isTrue);
    });

    test('ma trận gồm cả khoản giữa hai người khác, nhãn "Bạn" cho chính tôi', () {
      final view = buildGroupDebtsView(
        raw: [
          debt(id: 'd1', debtor: _me, creditor: _lam, amount: 40000),
          debt(id: 'd2', debtor: _an, creditor: _lam, amount: 25000),
        ],
        callerMembershipId: _me,
      );

      // Danh sách của tôi chỉ có khoản liên quan tới tôi...
      expect(view.debts, hasLength(1));
      // ...còn ma trận là bức tranh của cả nhóm.
      expect(view.matrix, hasLength(2));
      expect(view.matrix.first.from, kMeLabel);
      expect(view.matrix.first.amount, 40000);
      expect(view.matrix.last.from, 'An');
      expect(view.matrix.last.to, 'Lâm');
    });

    test('số dư từng thành viên tính đúng công thức của backend', () {
      // v_member_balances: tổng khoản được nhận trừ tổng khoản phải trả, chỉ
      // tính khoản còn sống.
      final view = buildGroupDebtsView(
        raw: [
          debt(id: 'd1', debtor: _me, creditor: _lam, amount: 40000),
          debt(id: 'd2', debtor: _an, creditor: _lam, amount: 25000),
          debt(id: 'd3', debtor: _lam, creditor: _me, amount: 10000),
          debt(id: 'd4', debtor: _an, creditor: _me, amount: 5000, status: 'settled'),
        ],
        callerMembershipId: _me,
      );

      expect(view.netBalanceByMember[_lam], 40000 + 25000 - 10000);
      expect(view.netBalanceByMember[_me], 10000 - 40000);
      expect(view.netBalanceByMember[_an], -25000, reason: 'khoản settled bị bỏ qua');
    });

    test('amount dạng chuỗi từ backend vẫn đọc được', () {
      final raw = RawGroupDebt.fromJson({
        'id': 'd1',
        'debtor_member_id': _me,
        'debtor_display_name': 'Tôi',
        'creditor_member_id': _lam,
        'creditor_display_name': 'Lâm',
        'amount': '125000',
        'status': 'awaiting',
      });

      expect(raw.amount, 125000);
      expect(raw.isActive, isTrue);
    });
  });
}
