import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/settlement_entities.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../datasources/settlement_remote_data_source.dart';

class SettlementRepositoryImpl implements SettlementRepository {
  SettlementRepositoryImpl(this._remoteDataSource);

  final SettlementRemoteDataSource _remoteDataSource;

  @override
  Future<SettlementDataEntity> loadSettlement() => _guard(_loadSettlement);

  Future<SettlementDataEntity> _loadSettlement() async {
    final groupMaps = await _remoteDataSource.listGroups();
    final groups = await Future.wait(groupMaps.map(_loadGroup));

    final payable = <DebtItemEntity>[];
    final receivable = <DebtItemEntity>[];
    final activeReceivable = <DebtItemEntity>[];
    final bills = <SettlementBillEntity>[];
    final paymentContexts = <String, _PaymentContext>{};

    for (final group in groups) {
      bills.addAll(group.bills);
      for (final debt in group.debts) {
        final isPayable = debt.debtorId == group.callerMembershipId;
        final isReceivable = debt.creditorId == group.callerMembershipId;
        final isActive =
            debt.status == DebtStatus.awaiting ||
            debt.status == DebtStatus.pendingConfirmation;

        if (isPayable && isActive) payable.add(debt);
        if (isReceivable && isActive) activeReceivable.add(debt);
        if (isReceivable && debt.status == DebtStatus.awaiting) {
          receivable.add(debt);
        }

        final paymentId = debt.paymentId;
        if (paymentId != null &&
            (debt.status == DebtStatus.pendingConfirmation ||
                debt.status == DebtStatus.settled)) {
          paymentContexts.putIfAbsent(
            '${group.id}:$paymentId',
            () => _PaymentContext(group: group, debt: debt),
          );
        }
      }
    }

    final paymentRecords = await Future.wait(
      paymentContexts.entries.map((entry) async {
        final context = entry.value;
        final payment = await _remoteDataSource.getPayment(
          context.group.id,
          context.debt.paymentId!,
        );
        return _LoadedPayment(context: context, payment: payment);
      }),
    );

    final pendingProofs = <ProofDetailEntity>[];
    final history = <SettledHistoryEntity>[];
    for (final record in paymentRecords) {
      final proof = _proofFromPayment(record);
      final status = proof.status;
      final callerId = record.context.group.callerMembershipId;
      final isCreditor = record.context.debt.creditorId == callerId;

      if (status == PaymentStatus.pendingConfirmation && isCreditor) {
        pendingProofs.add(proof);
      } else if (status == PaymentStatus.confirmed) {
        final debt = record.context.debt;
        history.add(
          SettledHistoryEntity(
            id: proof.paymentId,
            title: isCreditor
                ? '${proof.debtorName} đã trả bạn'
                : 'Bạn đã trả ${proof.creditorName}',
            subtitle: '${debt.groupName} · ${debt.billTitle}',
            amount: proof.amount,
            isIncome: isCreditor,
            settledAt: _date(
              record.payment['confirmed_at'] ??
                  record.payment['submitted_at'] ??
                  record.payment['created_at'],
            ),
            proof: proof,
          ),
        );
      }
    }

    payable.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    receivable.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    pendingProofs.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    history.sort((a, b) => b.settledAt.compareTo(a.settledAt));
    bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final grouped = _groupPayable(payable);
    final totalPayable = payable.fold<int>(0, (sum, debt) => sum + debt.amount);
    final totalReceivable = activeReceivable.fold<int>(
      0,
      (sum, debt) => sum + debt.amount,
    );

    return SettlementDataEntity(
      overview: SettlementOverviewEntity(
        totalPayable: totalPayable,
        totalReceivable: totalReceivable,
        payableCount: payable
            .where((debt) => debt.status == DebtStatus.awaiting)
            .length,
        receivableCount: receivable
            .where((debt) => debt.status == DebtStatus.awaiting)
            .length,
        activeGroupsCount: groups.length,
        pendingProofCount: pendingProofs.length,
      ),
      payableDebts: payable,
      receivableDebts: receivable,
      groupedDebts: grouped,
      pendingProofs: pendingProofs,
      settledHistory: history,
      bills: bills,
    );
  }

  @override
  Future<PaymentQrEntity> generatePaymentQr({
    required String groupId,
    required String creditorId,
    required List<String> debtIds,
  }) => _guard(
    () => _generatePaymentQr(
      groupId: groupId,
      creditorId: creditorId,
      debtIds: debtIds,
    ),
  );

  Future<PaymentQrEntity> _generatePaymentQr({
    required String groupId,
    required String creditorId,
    required List<String> debtIds,
  }) async {
    if (debtIds.isEmpty) {
      throw ArgumentError.value(debtIds, 'debtIds', 'Must not be empty');
    }
    final payment = await _remoteDataSource.generatePaymentQr(
      groupId: groupId,
      creditorId: creditorId,
      debtIds: debtIds,
    );
    final recipient = _map(payment['recipient']);
    return PaymentQrEntity(
      id: _string(payment['id']),
      groupId: _string(payment['group_id']),
      amount: _money(payment['amount']),
      referenceCode: _string(payment['reference_code']),
      qrPayload: _string(payment['qr_payload']),
      qrImageUrl: _string(payment['qr_image_url']),
      bankName: _string(recipient['bank_name']),
      accountNumber: _string(recipient['account_number']),
      accountHolder: _string(recipient['account_holder']),
      coveredDebtIds: _stringList(payment['covered_debt_ids']),
    );
  }

  @override
  Future<void> submitProof({
    required String groupId,
    required String paymentId,
    required ProofUploadEntity image,
    String? note,
  }) {
    return _guard(
      () => _remoteDataSource.submitProof(
        groupId: groupId,
        paymentId: paymentId,
        imageName: image.name,
        imageBytes: image.bytes,
        note: note,
      ),
    );
  }

  @override
  Future<void> confirmPayment({
    required String groupId,
    required String paymentId,
  }) => _guard(() => _remoteDataSource.confirmPayment(groupId, paymentId));

  @override
  Future<void> rejectPayment({
    required String groupId,
    required String paymentId,
    required String reason,
  }) =>
      _guard(() => _remoteDataSource.rejectPayment(groupId, paymentId, reason));

  @override
  Future<void> remindDebt({required String groupId, required String debtId}) =>
      _guard(() => _remoteDataSource.remindDebt(groupId, debtId));

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw mapDioError(error);
    } on FormatException {
      throw invalidResponseFailure;
    }
  }

  Future<_GroupData> _loadGroup(Map<String, dynamic> item) async {
    final groupMap = _map(item['group']);
    final id = _string(groupMap['id']);
    final name = _string(groupMap['name']);
    final callerMembershipId = _string(item['caller_membership_id']);
    final results = await Future.wait<List<Map<String, dynamic>>>([
      _remoteDataSource.listDebts(id),
      _remoteDataSource.listBills(id),
    ]);

    return _GroupData(
      id: id,
      name: name,
      callerMembershipId: callerMembershipId,
      debts: results[0]
          .map((debt) => _debtFromMap(debt, groupId: id, groupName: name))
          .toList(),
      bills: results[1]
          .map((bill) => _billFromMap(bill, groupId: id, groupName: name))
          .toList(),
    );
  }

  DebtItemEntity _debtFromMap(
    Map<String, dynamic> map, {
    required String groupId,
    required String groupName,
  }) {
    final debtorName = _string(map['debtor_display_name']);
    final creditorName = _string(map['creditor_display_name']);
    return DebtItemEntity(
      id: _string(map['id']),
      groupId: groupId,
      groupName: groupName,
      billId: _string(map['bill_id']),
      billTitle: _optionalString(map['merchant_name']) ?? 'Hóa đơn',
      debtorId: _string(map['debtor_member_id']),
      debtorName: debtorName,
      debtorAvatar: _initials(debtorName),
      creditorId: _string(map['creditor_member_id']),
      creditorName: creditorName,
      creditorAvatar: _initials(creditorName),
      amount: _money(map['amount']),
      status: _debtStatus(_string(map['status'])),
      createdAt: _date(map['created_at']),
      reminderCount: _integer(map['reminder_count']),
      paymentId: _optionalString(map['payment_id']),
    );
  }

  SettlementBillEntity _billFromMap(
    Map<String, dynamic> map, {
    required String groupId,
    required String groupName,
  }) {
    return SettlementBillEntity(
      id: _string(map['id']),
      groupId: groupId,
      groupName: groupName,
      title: _optionalString(map['merchant_name']) ?? 'Hóa đơn chưa đặt tên',
      amount: _integer(map['total']),
      status: _string(map['status']),
      createdAt: _date(map['created_at']),
      payerDisplayName: _string(map['payer_display_name']),
      paidMemberCount: _integer(map['paid_member_count']),
      memberCount: _integer(map['member_count']),
    );
  }

  ProofDetailEntity _proofFromPayment(_LoadedPayment record) {
    final payment = record.payment;
    final debt = record.context.debt;
    final recipient = payment['recipient'] == null
        ? <String, dynamic>{}
        : _map(payment['recipient']);
    final account = _optionalString(recipient['account_number']) ?? 'Không có';
    final holder = _optionalString(recipient['account_holder']);

    return ProofDetailEntity(
      id: _string(payment['id']),
      groupId: record.context.group.id,
      groupName: record.context.group.name,
      paymentId: _string(payment['id']),
      debtorName: debt.debtorName,
      debtorAvatar: debt.debtorAvatar,
      creditorName: debt.creditorName,
      amount: _money(payment['amount']),
      submittedAt: _date(payment['submitted_at'] ?? payment['created_at']),
      targetBank: _optionalString(recipient['bank_name']) ?? 'Không có',
      targetAccount: holder == null ? account : '$account ($holder)',
      referenceCode: _string(payment['reference_code']),
      note: _optionalString(payment['note']),
      status: _paymentStatus(_string(payment['status'])),
      isSettled: _string(payment['status']) == 'confirmed',
      proofImageUrl: _optionalString(payment['image_url']),
      rejectionReason: _optionalString(payment['rejection_reason']),
    );
  }

  List<SingleCreditorBatchEntity> _groupPayable(List<DebtItemEntity> payable) {
    final groups = <String, List<DebtItemEntity>>{};
    for (final debt in payable.where(
      (item) => item.status == DebtStatus.awaiting,
    )) {
      groups
          .putIfAbsent('${debt.groupId}:${debt.creditorId}', () => [])
          .add(debt);
    }

    return groups.values.map((debts) {
      final first = debts.first;
      return SingleCreditorBatchEntity(
        groupId: first.groupId,
        groupName: first.groupName,
        creditorId: first.creditorId,
        creditorName: first.creditorName,
        creditorAvatar: first.creditorAvatar,
        debts: debts,
      );
    }).toList();
  }

  DebtStatus _debtStatus(String value) {
    return switch (value) {
      'awaiting' => DebtStatus.awaiting,
      'pending_confirmation' => DebtStatus.pendingConfirmation,
      'settled' => DebtStatus.settled,
      'voided' => DebtStatus.voided,
      _ => throw FormatException('Unknown debt status: $value'),
    };
  }

  PaymentStatus _paymentStatus(String value) {
    return switch (value) {
      'pending_proof' => PaymentStatus.pendingProof,
      'pending_confirmation' => PaymentStatus.pendingConfirmation,
      'confirmed' => PaymentStatus.confirmed,
      'rejected' => PaymentStatus.rejected,
      'superseded' => PaymentStatus.superseded,
      _ => throw FormatException('Unknown payment status: $value'),
    };
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is! Map) throw const FormatException('Expected a JSON object');
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  String _string(dynamic value) {
    if (value is String && value.isNotEmpty) return value;
    throw const FormatException('Expected a non empty string');
  }

  String? _optionalString(dynamic value) {
    return value is String && value.isNotEmpty ? value : null;
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) throw const FormatException('Expected a JSON array');
    return value.map(_string).toList();
  }

  int _money(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw const FormatException('Expected an integer VND amount');
  }

  int _integer(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw const FormatException('Expected an integer');
  }

  DateTime _date(dynamic value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw const FormatException('Expected an ISO date');
  }
}

class _GroupData {
  const _GroupData({
    required this.id,
    required this.name,
    required this.callerMembershipId,
    required this.debts,
    required this.bills,
  });

  final String id;
  final String name;
  final String callerMembershipId;
  final List<DebtItemEntity> debts;
  final List<SettlementBillEntity> bills;
}

class _PaymentContext {
  const _PaymentContext({required this.group, required this.debt});

  final _GroupData group;
  final DebtItemEntity debt;
}

class _LoadedPayment {
  const _LoadedPayment({required this.context, required this.payment});

  final _PaymentContext context;
  final Map<String, dynamic> payment;
}
