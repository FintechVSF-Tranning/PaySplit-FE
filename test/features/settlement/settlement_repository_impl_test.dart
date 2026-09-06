import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paysplit/core/error/failures.dart';
import 'package:paysplit/features/settlement/data/datasources/settlement_remote_data_source.dart';
import 'package:paysplit/features/settlement/data/repositories/settlement_repository_impl.dart';
import 'package:paysplit/features/settlement/domain/entities/settlement_entities.dart';

class _MockRemoteDataSource extends Mock
    implements SettlementRemoteDataSource {}

void main() {
  setUpAll(() => registerFallbackValue(Uint8List(0)));
  group('SettlementRepositoryImpl', () {
    late _MockRemoteDataSource remote;
    late SettlementRepositoryImpl repository;

    setUp(() {
      remote = _MockRemoteDataSource();
      repository = SettlementRepositoryImpl(remote);
    });

    test(
      'keeps debtor receipts separate from proofs awaiting creditor review',
      () async {
        when(
          () => remote.listGroups(),
        ).thenAnswer((_) async => [_group('group-1', 'Nhóm một', 'debtor-1')]);
        when(() => remote.listDebts('group-1')).thenAnswer(
          (_) async => [
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
        when(() => remote.listBills('group-1')).thenAnswer((_) async => []);
        when(
          () => remote.getPayment('group-1', 'payment-1'),
        ).thenAnswer((_) async => _payment());
        final data = await repository.loadSettlement();
        expect(data.pendingProofs, isEmpty);
        expect(data.overview.pendingProofCount, 0);
        expect(data.submittedProofs.single.paymentId, 'payment-1');
        expect(
          data.submittedProofs.single.proofImageUrl,
          'https://cdn/proof.jpg',
        );
        expect(data.groupedDebts, isEmpty);
        expect(data.payableDebts.single.paymentId, 'payment-1');
      },
    );

    test('làm mới có phạm vi chỉ gọi lại API của đúng nhóm vừa đổi', () async {
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
      when(() => remote.listBills('group-1')).thenAnswer((_) async => []);
      when(() => remote.listBills('group-2')).thenAnswer((_) async => []);

      await repository.loadSettlement();
      final data = await repository.loadSettlement(onlyGroupId: 'group-1');

      // group-1 được nạp hai lượt, group-2 chỉ lượt đầu.
      verify(() => remote.listDebts('group-1')).called(2);
      verify(() => remote.listBills('group-1')).called(2);
      verify(() => remote.listDebts('group-2')).called(1);
      verify(() => remote.listBills('group-2')).called(1);
      // listGroups luôn gọi lại: nó là thứ duy nhất phát hiện nhóm mới/bị rời.
      verify(() => remote.listGroups()).called(2);

      // Dữ liệu nhóm không nạp lại vẫn phải có mặt đầy đủ trong kết quả.
      expect(
        data.payableDebts.map((debt) => debt.id),
        containsAll(['debt-1', 'debt-2']),
      );
      expect(data.overview.activeGroupsCount, 2);
    });

    test('lượt nạp đầy đủ luôn gọi lại mọi nhóm', () async {
      when(
        () => remote.listGroups(),
      ).thenAnswer((_) async => [_group('group-1', 'Nhóm một', 'me-1')]);
      when(() => remote.listDebts('group-1')).thenAnswer((_) async => []);
      when(() => remote.listBills('group-1')).thenAnswer((_) async => []);

      await repository.loadSettlement();
      await repository.loadSettlement();

      verify(() => remote.listDebts('group-1')).called(2);
    });

    test('loads real group data and keeps batches scoped to one group', () async {
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

      // Tổng tiền và số lượng phải nói về cùng một tập khoản nợ, nếu không hero
      // card sẽ hiện 300.000d ben canh "(0)".
      expect(data.overview.payableCount, data.payableDebts.length);
      expect(data.overview.receivableCount, data.receivableDebts.length);
      expect(
        data.receivableDebts.fold<int>(0, (sum, d) => sum + d.amount),
        data.overview.totalReceivable,
      );
      expect(
        data.payableDebts.fold<int>(0, (sum, d) => sum + d.amount),
        data.overview.totalPayable,
      );
      // Khoản nợ pending_confirmation vẫn là khoản cần thu đang sống; tab tự
      // lọc tiếp để tách phần chờ duyệt biên lai.
      expect(data.receivableDebts.single.id, 'debt-proof');
      expect(data.pendingProofs.single.groupName, 'Nhóm một');
      expect(data.groupedDebts, hasLength(2));
      expect(
        data.groupedDebts.map((group) => group.groupId),
        containsAll(['group-1', 'group-2']),
      );
      expect(data.pendingProofs.single.proofImageUrl, 'https://cdn/proof.jpg');
      expect(data.pendingProofs.single.referenceCode, 'PAYABCDEFGH');
      expect(data.bills, hasLength(2));
      expect(data.bills.first.payerDisplayName, 'Nguyễn An');
      expect(data.bills.first.paidMemberCount, 2);
      expect(data.bills.first.memberCount, 4);
    });

    test(
      'maps the server QR and integer VND amount without inventing values',
      () async {
        when(
          () => remote.generatePaymentQr(
            groupId: 'group-1',
            creditorId: 'creditor-1',
            debtIds: const ['debt-1'],
            idempotencyKey: any(named: 'idempotencyKey'),
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
    test(
      'một bản ghi hỏng chỉ mất chính nó, không đánh sập cả lần tải',
      () async {
        when(
          () => remote.listGroups(),
        ).thenAnswer((_) async => [_group('group-1', 'Nhóm một', 'me-1')]);
        when(() => remote.listDebts('group-1')).thenAnswer(
          (_) async => [
            _debt(
              id: 'debt-ok',
              debtorId: 'me-1',
              creditorId: 'creditor-1',
              amount: '100000',
            ),
            // thiếu amount -> FormatException khi parse
            {'id': 'debt-hong', 'status': 'awaiting'},
          ],
        );
        when(() => remote.listBills('group-1')).thenAnswer(
          (_) async => [
            _bill('bill-1', 'Bữa trưa', 400000),
            {'id': 'bill-hong'},
          ],
        );

        final data = await repository.loadSettlement();

        expect(data.payableDebts.single.id, 'debt-ok');
        expect(data.bills.single.id, 'bill-1');
      },
    );

    test(
      'trạng thái debt lạ không ném lỗi và không bị tính là đang sống',
      () async {
        when(
          () => remote.listGroups(),
        ).thenAnswer((_) async => [_group('group-1', 'Nhóm một', 'me-1')]);
        when(() => remote.listDebts('group-1')).thenAnswer(
          (_) async => [
            _debt(
              id: 'debt-stalled',
              debtorId: 'me-1',
              creditorId: 'creditor-1',
              amount: '100000',
              status: 'stalled_confirmation',
            ),
          ],
        );
        when(() => remote.listBills('group-1')).thenAnswer((_) async => []);

        final data = await repository.loadSettlement();

        expect(data.payableDebts, isEmpty);
        expect(data.overview.totalPayable, 0);
      },
    );

    test(
      'bill thiếu field tiến độ của BE #66 vẫn hiển thị, chỉ mất tiến độ',
      () async {
        when(
          () => remote.listGroups(),
        ).thenAnswer((_) async => [_group('group-1', 'Nhóm một', 'me-1')]);
        when(() => remote.listDebts('group-1')).thenAnswer((_) async => []);
        when(() => remote.listBills('group-1')).thenAnswer(
          (_) async => [
            {
              'id': 'bill-1',
              'merchant_name': 'Bữa trưa',
              'total': 400000,
              'status': 'finalized',
              'created_at': '2026-08-25T10:00:00Z',
            },
          ],
        );

        final data = await repository.loadSettlement();

        expect(data.bills.single.id, 'bill-1');
        expect(data.bills.single.memberCount, 0);
        expect(data.bills.single.paidRatio, 0);
      },
    );

    test('giới hạn số request song song khi fan-out nhiều nhóm', () async {
      const groupCount = 20;
      repository = SettlementRepositoryImpl(remote, maxConcurrentRequests: 4);

      var inFlight = 0;
      var peak = 0;
      Future<List<Map<String, dynamic>>> slow() async {
        inFlight++;
        if (inFlight > peak) peak = inFlight;
        await Future<void>.delayed(const Duration(milliseconds: 1));
        inFlight--;
        return [];
      }

      when(() => remote.listGroups()).thenAnswer(
        (_) async => List.generate(
          groupCount,
          (i) => _group('group-$i', 'Nhóm $i', 'me-$i'),
        ),
      );
      when(() => remote.listDebts(any())).thenAnswer((_) => slow());
      when(() => remote.listBills(any())).thenAnswer((_) => slow());

      await repository.loadSettlement();

      // 4 nhóm song song, mỗi nhóm 2 request (debts + bills) = trần 8.
      expect(peak, lessThanOrEqualTo(8));
      expect(peak, lessThan(groupCount));
    });

    test('replays a committed proof after its response is lost', () async {
      String? completedKey;
      var submissions = 0;
      when(
        () => remote.submitProof(
          groupId: any(named: 'groupId'),
          paymentId: any(named: 'paymentId'),
          imageName: any(named: 'imageName'),
          imageBytes: any(named: 'imageBytes'),
          note: any(named: 'note'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((invocation) async {
        final key = invocation.namedArguments[#idempotencyKey]! as String;
        final request = RequestOptions(path: '/proof');
        if (completedKey == null) {
          completedKey = key;
          submissions++;
          throw DioException(
            requestOptions: request,
            type: DioExceptionType.receiveTimeout,
          );
        }
        // The server replays completed keys before checking payment status.
        if (key != completedKey) {
          throw DioException(
            requestOptions: request,
            type: DioExceptionType.badResponse,
            response: Response<dynamic>(
              requestOptions: request,
              statusCode: 409,
              data: {
                'error': {'code': 'PAYMENT_NOT_PENDING_PROOF'},
              },
            ),
          );
        }
      });
      final image = ProofUploadEntity(
        name: 'receipt.jpg',
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      await expectLater(
        repository.submitProof(
          groupId: 'group-1',
          paymentId: 'payment-1',
          image: image,
        ),
        throwsA(isA<Failure>()),
      );
      // Reopening the screen/recreating the repository must also preserve retry.
      await SettlementRepositoryImpl(
        remote,
      ).submitProof(groupId: 'group-1', paymentId: 'payment-1', image: image);
      expect(submissions, 1);
    });

    test(
      'proof keys follow payment, image bytes and normalized note',
      () async {
        final keys = <String>[];
        when(
          () => remote.submitProof(
            groupId: any(named: 'groupId'),
            paymentId: any(named: 'paymentId'),
            imageName: any(named: 'imageName'),
            imageBytes: any(named: 'imageBytes'),
            note: any(named: 'note'),
            idempotencyKey: any(named: 'idempotencyKey'),
          ),
        ).thenAnswer((invocation) async {
          keys.add(invocation.namedArguments[#idempotencyKey]! as String);
        });
        Future<void> submit({
          String group = 'group-1',
          String payment = 'payment-1',
          String name = 'receipt.jpg',
          List<int> bytes = const [1, 2, 3],
          String? note = 'Paid',
        }) => repository.submitProof(
          groupId: group,
          paymentId: payment,
          note: note,
          image: ProofUploadEntity(
            name: name,
            bytes: Uint8List.fromList(bytes),
          ),
        );

        await submit();
        await submit(name: 'renamed.jpg', note: '  Paid  ');
        await submit(bytes: [3, 2, 1]);
        await submit(note: 'Updated');
        await submit(payment: 'payment-2');
        await submit(group: 'group-2');
        await submit(note: null);
        await submit(note: '');
        await submit(note: '   ');
        expect(keys[1], keys[0]);
        expect({keys[0], ...keys.sublist(2, 7)}, hasLength(6));
        expect(keys[7], keys[6]);
        expect(keys[8], keys[6]);
      },
    );

    test('creates a fresh QR after rejection for the same debts', () async {
      final cached = <String, Map<String, dynamic>>{};
      var rejected = false;
      when(
        () => remote.generatePaymentQr(
          groupId: 'group-1',
          creditorId: 'creditor-1',
          debtIds: const ['debt-1'],
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((invocation) async {
        final key = invocation.namedArguments[#idempotencyKey]! as String;
        return cached.putIfAbsent(
          key,
          () => {
            ..._payment(status: 'pending_proof'),
            'id': rejected ? 'payment-2' : 'payment-1',
          },
        );
      });
      Future<PaymentQrEntity> generate() => repository.generatePaymentQr(
        groupId: 'group-1',
        creditorId: 'creditor-1',
        debtIds: const ['debt-1'],
      );
      expect((await generate()).id, 'payment-1');
      rejected = true;
      expect((await generate()).id, 'payment-2');
    });

    test('Idempotency-Key ổn định khi lặp lại cùng một thao tác', () async {
      when(
        () => remote.confirmPayment(
          any(),
          any(),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async {});

      await repository.confirmPayment(
        groupId: 'group-1',
        paymentId: 'payment-1',
      );
      await repository.confirmPayment(
        groupId: 'group-1',
        paymentId: 'payment-1',
      );
      await repository.confirmPayment(
        groupId: 'group-1',
        paymentId: 'payment-2',
      );

      final keys = verify(
        () => remote.confirmPayment(
          any(),
          any(),
          idempotencyKey: captureAny(named: 'idempotencyKey'),
        ),
      ).captured.cast<String>();

      expect(keys[0], keys[1], reason: 'retry cùng payment phải dùng lại key');
      expect(keys[2], isNot(keys[0]), reason: 'payment khác phải khác key');
    });
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
