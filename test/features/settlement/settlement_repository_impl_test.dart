import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paysplit/features/settlement/data/datasources/settlement_remote_data_source.dart';
import 'package:paysplit/features/settlement/data/repositories/settlement_repository_impl.dart';

class _MockRemoteDataSource extends Mock
    implements SettlementRemoteDataSource {}

void main() {
  group('SettlementRepositoryImpl', () {
    late _MockRemoteDataSource remote;
    late SettlementRepositoryImpl repository;

    setUp(() {
      remote = _MockRemoteDataSource();
      repository = SettlementRepositoryImpl(remote);
    });

    test(
      'loads real group data and keeps batches scoped to one group',
      () async {
        when(() => remote.listGroups()).thenAnswer(
          (_) async => [
            _group('group-1', 'Nhóm một', 'me-1'),
            _group('group-2', 'Nhóm hai', 'me-2'),
          ],
        );
        when(() => remote.listDebts('group-1')).thenAnswer(
          (_) async => [
            _debt(
              id: 'debt-1',
              debtorId: 'me-1',
              creditorId: 'creditor-common',
              amount: '100000',
            ),
            _debt(
              id: 'debt-proof',
              debtorId: 'debtor-1',
              creditorId: 'me-1',
              amount: '300000',
              status: 'pending_confirmation',
              paymentId: 'payment-1',
            ),
          ],
        );
        when(() => remote.listDebts('group-2')).thenAnswer(
          (_) async => [
            _debt(
              id: 'debt-2',
              debtorId: 'me-2',
              creditorId: 'creditor-common',
              amount: '200000',
            ),
          ],
        );
        when(
          () => remote.listBills('group-1'),
        ).thenAnswer((_) async => [_bill('bill-1', 'Bữa trưa', 400000)]);
        when(
          () => remote.listBills('group-2'),
        ).thenAnswer((_) async => [_bill('bill-2', 'Khách sạn', 800000)]);
        when(
          () => remote.getPayment('group-1', 'payment-1'),
        ).thenAnswer((_) async => _payment());

        final data = await repository.loadSettlement();

        expect(data.overview.totalPayable, 300000);
        expect(data.overview.totalReceivable, 300000);
        expect(data.overview.pendingProofCount, 1);
        expect(data.receivableDebts, isEmpty);
        expect(data.pendingProofs.single.groupName, 'Nhóm một');
        expect(data.groupedDebts, hasLength(2));
        expect(
          data.groupedDebts.map((group) => group.groupId),
          containsAll(['group-1', 'group-2']),
        );
        expect(
          data.pendingProofs.single.proofImageUrl,
          'https://cdn/proof.jpg',
        );
        expect(data.pendingProofs.single.referenceCode, 'PAYABCDEFGH');
        expect(data.bills, hasLength(2));
        expect(data.bills.first.payerDisplayName, 'Nguyễn An');
        expect(data.bills.first.paidMemberCount, 2);
        expect(data.bills.first.memberCount, 4);
      },
    );

    test(
      'maps the server QR and integer VND amount without inventing values',
      () async {
        when(
          () => remote.generatePaymentQr(
            groupId: 'group-1',
            creditorId: 'creditor-1',
            debtIds: const ['debt-1'],
          ),
        ).thenAnswer((_) async => _payment(status: 'pending_proof'));

        final qr = await repository.generatePaymentQr(
          groupId: 'group-1',
          creditorId: 'creditor-1',
          debtIds: const ['debt-1'],
        );

        expect(qr.id, 'payment-1');
        expect(qr.amount, 300000);
        expect(qr.referenceCode, 'PAYABCDEFGH');
        expect(qr.qrPayload, 'vietqr-payload');
        expect(qr.qrImageUrl, 'https://cdn/qr.png');
        expect(qr.accountNumber, '123456789');
      },
    );
  });
}

Map<String, dynamic> _group(String id, String name, String callerMembershipId) {
  return {
    'group': {'id': id, 'name': name},
    'caller_membership_id': callerMembershipId,
  };
}

Map<String, dynamic> _debt({
  required String id,
  required String debtorId,
  required String creditorId,
  required String amount,
  String status = 'awaiting',
  String? paymentId,
}) {
  return {
    'id': id,
    'bill_id': 'bill-$id',
    'merchant_name': 'Hóa đơn $id',
    'debtor_member_id': debtorId,
    'debtor_display_name': 'Người trả $debtorId',
    'creditor_member_id': creditorId,
    'creditor_display_name': 'Người nhận $creditorId',
    'amount': amount,
    'status': status,
    'reminder_count': 0,
    'payment_id': paymentId,
    'created_at': '2026-08-25T10:00:00Z',
  };
}

Map<String, dynamic> _bill(String id, String name, int total) {
  return {
    'id': id,
    'merchant_name': name,
    'total': total,
    'status': 'finalized',
    'payer_display_name': 'Nguyễn An',
    'paid_member_count': 2,
    'member_count': 4,
    'created_at': '2026-08-25T10:00:00Z',
  };
}

Map<String, dynamic> _payment({String status = 'pending_confirmation'}) {
  return {
    'id': 'payment-1',
    'group_id': 'group-1',
    'debtor_member_id': 'debtor-1',
    'creditor_member_id': 'me-1',
    'amount': '300000',
    'reference_code': 'PAYABCDEFGH',
    'status': status,
    'qr_payload': 'vietqr-payload',
    'qr_image_url': 'https://cdn/qr.png',
    'recipient': {
      'bank_name': 'Vietcombank',
      'account_number': '123456789',
      'account_holder': 'NGUYEN VAN A',
    },
    'image_url': 'https://cdn/proof.jpg',
    'note': 'Đã chuyển tiền',
    'covered_debt_ids': ['debt-proof'],
    'created_at': '2026-08-25T10:00:00Z',
    'submitted_at': '2026-08-25T10:05:00Z',
  };
}
