import '../../domain/entities/settlement_entities.dart';
import '../../domain/repositories/settlement_repository.dart';
import 'mock_settlement_data.dart';

class MockSettlementRepository implements SettlementRepository {
  MockSettlementRepository()
    : _payable = List.of(MockSettlementData.payableDebts),
      _receivable = List.of(MockSettlementData.receivableDebts),
      _pendingProof = MockSettlementData.pendingProof,
      _history = List.of(MockSettlementData.settledHistory);

  List<DebtItemEntity> _payable;
  final List<DebtItemEntity> _receivable;
  ProofDetailEntity? _pendingProof;
  final List<SettledHistoryEntity> _history;
  final Map<String, List<String>> _coveredDebts = {};
  var _paymentSequence = 0;

  @override
  Future<SettlementDataEntity> loadSettlement() async {
    final grouped = <String, List<DebtItemEntity>>{};
    for (final debt in _payable.where(
      (item) => item.status == DebtStatus.awaiting,
    )) {
      grouped
          .putIfAbsent('${debt.groupId}:${debt.creditorId}', () => [])
          .add(debt);
    }

    final pendingAmount = _pendingProof?.amount ?? 0;
    return SettlementDataEntity(
      overview: SettlementOverviewEntity(
        totalPayable: _payable
            .where((debt) => debt.status != DebtStatus.settled)
            .fold(0, (sum, debt) => sum + debt.amount),
        totalReceivable:
            _receivable.fold(0, (sum, debt) => sum + debt.amount) +
            pendingAmount,
        payableCount: _payable
            .where((debt) => debt.status == DebtStatus.awaiting)
            .length,
        receivableCount:
            _receivable
                .where((debt) => debt.status == DebtStatus.awaiting)
                .length +
            (_pendingProof == null ? 0 : 1),
        activeGroupsCount: 2,
        pendingProofCount: _pendingProof == null ? 0 : 1,
      ),
      payableDebts: List.unmodifiable(_payable),
      receivableDebts: List.unmodifiable(_receivable),
      groupedDebts: grouped.values.map((debts) {
        final first = debts.first;
        return SingleCreditorBatchEntity(
          groupId: first.groupId,
          groupName: first.groupName,
          creditorId: first.creditorId,
          creditorName: first.creditorName,
          creditorAvatar: first.creditorAvatar,
          debts: List.unmodifiable(debts),
        );
      }).toList(),
      pendingProofs: [?_pendingProof],
      settledHistory: List.unmodifiable(_history),
      bills: [
        SettlementBillEntity(
          id: 'bill-1',
          groupId: 'group-dev',
          groupName: 'Phòng Dev Cty',
          title: 'Lẩu gà lá é Tao Ngộ',
          amount: 1240000,
          status: 'draft',
          createdAt: DateTime(2026, 8, 25),
          payerDisplayName: 'Nam Phạm',
          paidMemberCount: 0,
          memberCount: 0,
        ),
        SettlementBillEntity(
          id: 'bill-2',
          groupId: 'group-dev',
          groupName: 'Phòng Dev Cty',
          title: 'Cà phê planning Sprint 12',
          amount: 185000,
          status: 'reviewed',
          createdAt: DateTime(2026, 8, 24),
          payerDisplayName: 'Linh Dan',
          paidMemberCount: 0,
          memberCount: 0,
        ),
        SettlementBillEntity(
          id: 'bill-3',
          groupId: 'group-dalat',
          groupName: 'Du lịch Đà Lạt 2026',
          title: 'Vé xe Limousine Đà Lạt',
          amount: 2400000,
          status: 'finalized',
          createdAt: DateTime(2026, 8, 23),
          payerDisplayName: 'Minh Trần',
          paidMemberCount: 3,
          memberCount: 5,
        ),
      ],
    );
  }

  @override
  Future<PaymentQrEntity> generatePaymentQr({
    required String groupId,
    required String creditorId,
    required List<String> debtIds,
  }) async {
    final selected = _payable
        .where((debt) => debtIds.contains(debt.id))
        .toList();
    if (selected.isEmpty ||
        selected.any(
          (debt) =>
              debt.groupId != groupId ||
              debt.creditorId != creditorId ||
              debt.status != DebtStatus.awaiting,
        )) {
      throw StateError('Các khoản nợ phải cùng nhóm và cùng chủ nợ');
    }

    _paymentSequence += 1;
    final paymentId = 'mock-payment-$_paymentSequence';
    _coveredDebts[paymentId] = List.of(debtIds);
    final first = selected.first;
    final isMinh = first.creditorId == 'cred-minh';

    return PaymentQrEntity(
      id: paymentId,
      groupId: groupId,
      amount: selected.fold(0, (sum, debt) => sum + debt.amount),
      referenceCode: 'PAYMOCK000$_paymentSequence',
      qrPayload: 'mock-vietqr-payload-$paymentId',
      qrImageUrl: 'https://example.com/$paymentId.png',
      bankName: isMinh ? 'Vietcombank (VCB)' : 'MB Bank',
      accountNumber: isMinh ? '1029384756' : '9988776655',
      accountHolder: isMinh ? 'TRAN VAN MINH' : 'NGUYEN DUC HUY',
      coveredDebtIds: List.of(debtIds),
    );
  }

  @override
  Future<void> submitProof({
    required String groupId,
    required String paymentId,
    required ProofUploadEntity image,
    String? note,
  }) async {
    final covered = _coveredDebts[paymentId];
    if (covered == null) throw StateError('Payment không tồn tại');
    _payable = _payable.map((debt) {
      if (debt.groupId == groupId && covered.contains(debt.id)) {
        return debt.copyWith(
          status: DebtStatus.pendingConfirmation,
          paymentId: paymentId,
        );
      }
      return debt;
    }).toList();
  }

  @override
  Future<void> confirmPayment({
    required String groupId,
    required String paymentId,
  }) async {
    final proof = _pendingProof;
    if (proof == null || proof.paymentId != paymentId) return;
    _pendingProof = null;
    _history.insert(
      0,
      SettledHistoryEntity(
        id: 'history-$paymentId',
        title: '${proof.debtorName} đã trả bạn',
        subtitle: 'Phòng Dev Cty · Cơm trưa lẩu gà',
        amount: proof.amount,
        isIncome: true,
        settledAt: DateTime.now(),
        proof: ProofDetailEntity(
          id: proof.id,
          groupId: proof.groupId,
          groupName: proof.groupName,
          paymentId: proof.paymentId,
          debtorName: proof.debtorName,
          debtorAvatar: proof.debtorAvatar,
          creditorName: proof.creditorName,
          amount: proof.amount,
          submittedAt: proof.submittedAt,
          targetBank: proof.targetBank,
          targetAccount: proof.targetAccount,
          referenceCode: proof.referenceCode,
          note: proof.note,
          status: PaymentStatus.confirmed,
          isSettled: true,
          proofImageUrl: proof.proofImageUrl,
        ),
      ),
    );
  }

  @override
  Future<void> rejectPayment({
    required String groupId,
    required String paymentId,
    required String reason,
  }) async {
    final proof = _pendingProof;
    if (proof == null || proof.paymentId != paymentId) return;
    _pendingProof = null;
    _receivable.add(
      DebtItemEntity(
        id: 'reopened-$paymentId',
        groupId: groupId,
        groupName: 'Phòng Dev Cty',
        billId: 'bill-lau-ga',
        billTitle: 'Cơm trưa lẩu gà',
        debtorId: 'debtor-tl',
        debtorName: proof.debtorName,
        debtorAvatar: proof.debtorAvatar,
        creditorId: 'user-nam',
        creditorName: proof.creditorName,
        creditorAvatar: 'HN',
        amount: proof.amount,
        status: DebtStatus.awaiting,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> remindDebt({
    required String groupId,
    required String debtId,
  }) async {
    final index = _receivable.indexWhere(
      (debt) => debt.groupId == groupId && debt.id == debtId,
    );
    if (index < 0) return;
    final debt = _receivable[index];
    _receivable[index] = debt.copyWith(
      reminderCount: debt.reminderCount + 1,
      lastRemindedAt: DateTime.now(),
    );
  }
}
