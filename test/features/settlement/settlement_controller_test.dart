import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/settlement/data/mock/mock_settlement_repository.dart';
import 'package:paysplit/features/settlement/domain/entities/settlement_entities.dart';
import 'package:paysplit/features/settlement/presentation/providers/settlement_controller.dart';

void main() {
  group('SettlementController', () {
    late MockSettlementRepository repository;
    late SettlementController controller;

    setUp(() async {
      repository = MockSettlementRepository();
      controller = SettlementController(repository);
      await controller.loadData();
    });

    tearDown(() => controller.dispose());

    test('loads the settlement overview and active debts', () {
      final state = controller.state;

      expect(state.isLoading, false);
      expect(state.currentTab, SettlementTab.payable);
      expect(state.overview?.totalPayable, 400000);
      expect(state.payableDebts, hasLength(3));
      expect(state.receivableDebts, hasLength(2));
      expect(state.groupedDebts, hasLength(2));
      expect(state.pendingProofs.single.debtorName, 'Trần Lâm');
      expect(state.settledHistory, hasLength(3));
      expect(state.bills, hasLength(3));
    });

    test('changes the selected tab', () {
      controller.setTab(SettlementTab.history);

      expect(controller.state.currentTab, SettlementTab.history);
    });

    test('keeps every pending proof reachable in submission order', () async {
      final multipleController = SettlementController(
        _MultipleProofRepository(),
      );
      addTearDown(multipleController.dispose);

      await multipleController.loadData();

      expect(multipleController.state.pendingProofs, hasLength(2));
      expect(
        multipleController.state.pendingProofs.map((proof) => proof.paymentId),
        containsAll(<String>['pay-tl-1', 'pay-second']),
      );
    });

    test('adds and removes an individual debt selection', () {
      expect(controller.state.selectedDebtIds, contains('debt-pay-1'));

      controller.toggleDebtSelection('debt-pay-1');
      expect(controller.state.selectedDebtIds, isNot(contains('debt-pay-1')));

      controller.toggleDebtSelection('debt-pay-1');
      expect(controller.state.selectedDebtIds, contains('debt-pay-1'));
    });

    test('selects debts only within the requested group and creditor', () {
      controller.setCreditorDebtsSelection('group-dev', 'cred-minh', false);

      expect(controller.state.selectedDebtIds, isNot(contains('debt-pay-1')));
      expect(controller.state.selectedDebtIds, isNot(contains('debt-pay-2')));
      expect(controller.state.selectedDebtIds, contains('debt-pay-3'));
    });

    test(
      'confirms a pending payment only after the repository completes',
      () async {
        await controller.confirmPendingPayment(
          groupId: 'group-dev',
          paymentId: 'pay-tl-1',
        );

        expect(controller.state.pendingProofs, isEmpty);
        expect(controller.state.settledHistory, hasLength(4));
        expect(controller.state.settledHistory.first.proof.isSettled, true);
      },
    );

    test('rejects a pending payment and reopens its receivable debt', () async {
      await controller.rejectPendingPayment(
        groupId: 'group-dev',
        paymentId: 'pay-tl-1',
        reason: 'Chưa nhận được tiền trên Vietcombank',
      );

      expect(controller.state.pendingProofs, isEmpty);
      expect(controller.state.receivableDebts, hasLength(3));
      expect(controller.state.receivableDebts.last.status, DebtStatus.awaiting);
    });

    test('submitting a batch proof changes only the covered debts', () async {
      final payment = await controller.generatePaymentQr(
        groupId: 'group-dev',
        creditorId: 'cred-minh',
        debtIds: const ['debt-pay-1', 'debt-pay-2'],
      );

      await controller.submitProof(
        groupId: payment.groupId,
        paymentId: payment.id,
        image: ProofUploadEntity(
          name: 'proof.png',
          bytes: Uint8List.fromList(const [1, 2, 3]),
        ),
        note: 'Đã chuyển khoản',
      );

      final debts = {
        for (final debt in controller.state.payableDebts) debt.id: debt,
      };
      expect(debts['debt-pay-1']?.status, DebtStatus.pendingConfirmation);
      expect(debts['debt-pay-2']?.status, DebtStatus.pendingConfirmation);
      expect(debts['debt-pay-3']?.status, DebtStatus.awaiting);
      await expectLater(
        controller.generatePaymentQr(
          groupId: 'group-dev',
          creditorId: 'cred-minh',
          debtIds: const ['debt-pay-1'],
        ),
        throwsStateError,
      );
    });

    test('rejects a batch that crosses a group boundary', () async {
      await expectLater(
        controller.generatePaymentQr(
          groupId: 'group-dev',
          creditorId: 'cred-minh',
          debtIds: const ['debt-pay-1', 'debt-pay-3'],
        ),
        throwsStateError,
      );
      expect(controller.state.errorMessage, isNotNull);
    });

    test('làm mới ngầm giữ nguyên nội dung thay vì sập thành spinner', () async {
      // SettlementPage thay cả trang bằng spinner khi isLoading. Lượt làm mới do
      // realtime kích hoạt mà bật cờ đó thì mỗi lần ai trong nhóm xác nhận thanh
      // toán là màn hình người khác chớp trắng và cuộn về đầu.
      await controller.loadData();
      final before = controller.state.payableDebts;
      expect(before, isNotEmpty);

      final future = controller.loadData(background: true);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.isRefreshing, isTrue);
      expect(controller.state.payableDebts, before);

      await future;
      expect(controller.state.isRefreshing, isFalse);
      expect(controller.state.isLoading, isFalse);
    });

    test('lần nạp đầu vẫn hiện spinner dù được gọi ở chế độ ngầm', () async {
      final fresh = SettlementController(MockSettlementRepository());
      addTearDown(fresh.dispose);
      // Constructor đã bắn một loadData(); chờ nó xong rồi thử lại từ state rỗng.
      final pending = fresh.loadData(background: true);
      expect(fresh.state.isLoading, isTrue);
      await pending;
    });

    test('đếm ngược dài dùng nhịp thưa thay vì mỗi giây', () async {
      // Cooldown nhắc nợ là 24 tiếng và giao diện chỉ hiện tới đơn vị giờ. Nhịp
      // mỗi giây là 86.400 lần phát state để chữ đổi đúng 24 lần.
      final slow = SettlementController(
        MockSettlementRepository(),
        countdownInterval: const Duration(milliseconds: 5),
      );
      addTearDown(slow.dispose);
      await slow.loadData();
      await slow.remindDebt(groupId: 'group-dev', debtId: 'debt-rec-1');

      final start = slow.state.remindedCooldowns['debt-rec-1'];
      expect(start, 24 * 3600);

      // Nhịp cho khoảng còn lại lớn là 1 phút, nên sau 30ms không nhịp nào chạy.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(slow.state.remindedCooldowns['debt-rec-1'], start);
    });

    test(
      'reminder countdown expires without mutating a map during iteration',
      () async {
        final fastController = SettlementController(
          MockSettlementRepository(),
          reminderCooldownSeconds: 2,
          countdownInterval: const Duration(milliseconds: 5),
        );
        addTearDown(fastController.dispose);
        await fastController.loadData();

        await fastController.remindDebt(
          groupId: 'group-dev',
          debtId: 'debt-rec-1',
        );
        expect(fastController.state.remindedCooldowns['debt-rec-1'], 2);

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(fastController.state.remindedCooldowns, isEmpty);
      },
    );

    test(
      'keeps the proof pending and exposes an error when confirmation fails',
      () async {
        final failingController = SettlementController(
          _FailingConfirmRepository(),
        );
        addTearDown(failingController.dispose);
        await failingController.loadData();

        await expectLater(
          failingController.confirmPendingPayment(
            groupId: 'group-dev',
            paymentId: 'pay-tl-1',
          ),
          throwsStateError,
        );

        expect(failingController.state.pendingProofs, isNotEmpty);
        expect(failingController.state.errorMessage, isNotNull);
        expect(failingController.state.isMutating, false);
      },
    );
  });
}

class _FailingConfirmRepository extends MockSettlementRepository {
  @override
  Future<void> confirmPayment({
    required String groupId,
    required String paymentId,
  }) {
    return Future<void>.error(StateError('offline'));
  }
}

class _MultipleProofRepository extends MockSettlementRepository {
  @override
  Future<SettlementDataEntity> loadSettlement({String? onlyGroupId}) async {
    final data = await super.loadSettlement(onlyGroupId: onlyGroupId);
    final first = data.pendingProofs.single;
    final second = ProofDetailEntity(
      id: 'proof-second',
      groupId: first.groupId,
      groupName: first.groupName,
      paymentId: 'pay-second',
      debtorName: 'Nguyễn An',
      debtorAvatar: 'NA',
      creditorName: first.creditorName,
      amount: 175000,
      submittedAt: first.submittedAt.subtract(const Duration(minutes: 5)),
      targetBank: first.targetBank,
      targetAccount: first.targetAccount,
      referenceCode: 'PAYSECOND',
      proofImageUrl: first.proofImageUrl,
    );
    return SettlementDataEntity(
      overview: SettlementOverviewEntity(
        totalPayable: data.overview.totalPayable,
        totalReceivable: data.overview.totalReceivable,
        payableCount: data.overview.payableCount,
        receivableCount: data.overview.receivableCount,
        activeGroupsCount: data.overview.activeGroupsCount,
        pendingProofCount: 2,
      ),
      payableDebts: data.payableDebts,
      receivableDebts: data.receivableDebts,
      groupedDebts: data.groupedDebts,
      pendingProofs: [first, second],
      settledHistory: data.settledHistory,
      bills: data.bills,
    );
  }
}
