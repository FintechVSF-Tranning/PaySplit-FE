import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/settlement_entities.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../datasources/settlement_remote_data_source.dart';

class SettlementRepositoryImpl implements SettlementRepository {
  SettlementRepositoryImpl(
    this._remoteDataSource, {
    Uuid? uuid,
    this.maxConcurrentRequests = _defaultMaxConcurrentRequests,
  }) : _uuid = uuid ?? const Uuid();

  /// Trần số request song song. Không có trần thì một user nhiều nhóm sẽ bắn
  /// hàng trăm request cùng lúc và ăn rate limit của BE.
  static const int _defaultMaxConcurrentRequests = 6;

  /// Namespace cố định để sinh Idempotency-Key theo UUID v5. Cùng một thao tác
  /// logic (retry sau timeout, user bấm lại) phải ra đúng một key thì BE mới
  /// replay được kết quả cũ thay vì thực thi lần hai.
  static const String _idempotencyNamespace =
      '6ba7b811-9dad-11d1-80b4-00c04fd430c8';

  final SettlementRemoteDataSource _remoteDataSource;
  final Uuid _uuid;
  final int maxConcurrentRequests;

  /// Dữ liệu nhóm và payment của lượt nạp gần nhất, để lượt làm mới có phạm vi
  /// hẹp không phải gọi lại API cho những nhóm chẳng liên quan. Chỉ được đọc
  /// khi caller nói rõ nhóm nào vừa đổi; một lượt nạp đầy đủ luôn gọi lại tất
  /// cả và ghi đè cache.
  final Map<String, _GroupData> _groupCache = {};
  final Map<String, Map<String, dynamic>> _paymentCache = {};

  String _idempotencyKey(String operation) =>
      _uuid.v5(_idempotencyNamespace, 'paysplit:$operation');

  /// Chạy [tasks] với tối đa [maxConcurrentRequests] request đồng thời, giữ
  /// nguyên thứ tự kết quả.
  Future<List<T>> _throttled<T>(List<Future<T> Function()> tasks) async {
    final results = List<T?>.filled(tasks.length, null);
    var next = 0;

    Future<void> worker() async {
      while (true) {
        final index = next++;
        if (index >= tasks.length) return;
        results[index] = await tasks[index]();
      }
    }

    final workers = <Future<void>>[];
    final count = tasks.length < maxConcurrentRequests
        ? tasks.length
        : maxConcurrentRequests;
    for (var i = 0; i < count; i++) {
      workers.add(worker());
    }
    await Future.wait(workers);
    return results.cast<T>();
  }

  @override
  Future<SettlementDataEntity> loadSettlement({String? onlyGroupId}) =>
      _guard(() => _loadSettlement(onlyGroupId: onlyGroupId));

  Future<SettlementDataEntity> _loadSettlement({String? onlyGroupId}) async {
    // `listGroups` luôn được gọi lại: nó rẻ và là thứ duy nhất phát hiện nhóm
    // vừa được thêm hoặc vừa rời khỏi.
    final groupMaps = await _remoteDataSource.listGroups();
    final scoped = onlyGroupId != null && _groupCache.isNotEmpty;

    final groups = await _throttled(
      groupMaps.map((item) {
        final id = _string(_map(item['group'])['id']);
        final cached = _groupCache[id];
        // Nhóm chưa có trong cache luôn phải nạp, kể cả khi đang nạp có phạm vi.
        if (scoped && cached != null && id != onlyGroupId) {
          return () async => cached;
        }
        return () => _loadGroup(item);
      }).toList(),
    );

    _groupCache
      ..clear()
      ..addEntries(groups.map((group) => MapEntry(group.id, group)));

    // payable/receivable giữ mọi khoản còn "sống" (awaiting + pending_confirmation)
    // để tổng tiền và số lượng trên hero card luôn nói về cùng một tập. Các tab
    // tự lọc tiếp theo trạng thái chúng muốn hiển thị.
    final payable = <DebtItemEntity>[];
    final receivable = <DebtItemEntity>[];
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
        if (isReceivable && isActive) receivable.add(debt);

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

    final paymentRecords = await _throttled(
      paymentContexts.entries.map((entry) {
        final context = entry.value;
        final cached = _paymentCache[entry.key];
        if (scoped && cached != null && context.group.id != onlyGroupId) {
          return () async => _LoadedPayment(context: context, payment: cached);
        }
        return () async {
          final payment = await _remoteDataSource.getPayment(
            context.group.id,
            context.debt.paymentId!,
          );
          return _LoadedPayment(context: context, payment: payment);
        };
      }).toList(),
    );

    _paymentCache
      ..clear()
      ..addEntries(
        paymentRecords.map(
          (record) => MapEntry(
            '${record.context.group.id}:${record.context.debt.paymentId}',
            record.payment,
          ),
        ),
      );

    final pendingProofs = <ProofDetailEntity>[];
    final submittedProofs = <ProofDetailEntity>[];
    final history = <SettledHistoryEntity>[];
    for (final record in paymentRecords) {
      final proof = _proofFromPayment(record);
      final status = proof.status;
      final callerId = record.context.group.callerMembershipId;
      final isCreditor = record.context.debt.creditorId == callerId;

      if (status == PaymentStatus.pendingConfirmation &&
          record.context.debt.debtorId == callerId) {
        submittedProofs.add(proof);
      }
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
    final totalReceivable = receivable.fold<int>(
      0,
      (sum, debt) => sum + debt.amount,
    );

    return SettlementDataEntity(
      overview: SettlementOverviewEntity(
        totalPayable: totalPayable,
        totalReceivable: totalReceivable,
        payableCount: payable.length,
        receivableCount: receivable.length,
        activeGroupsCount: groups.length,
        pendingProofCount: pendingProofs.length,
      ),
      payableDebts: payable,
      receivableDebts: receivable,
      groupedDebts: grouped,
      pendingProofs: pendingProofs,
      submittedProofs: submittedProofs,
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
    // Key bám theo nội dung thao tác: bấm lại đúng nhóm nợ đó sẽ replay kết quả
    // cũ thay vì tạo payment thứ hai.
    final sortedDebtIds = [...debtIds]..sort();
    final payment = await _remoteDataSource.generatePaymentQr(
      groupId: groupId,
      creditorId: creditorId,
      debtIds: debtIds,
      idempotencyKey: _idempotencyKey(
        'qr:$groupId:$creditorId:${sortedDebtIds.join(",")}',
      ),
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
        // Mỗi payment chỉ nhận đúng một biên lai; bị từ chối thì BE tạo payment
        // mới nên key theo paymentId là đủ và an toàn khi retry.
        idempotencyKey: _idempotencyKey('proof:$groupId:$paymentId'),
      ),
    );
  }

  @override
  Future<void> confirmPayment({
    required String groupId,
    required String paymentId,
  }) => _guard(
    () => _remoteDataSource.confirmPayment(
      groupId,
      paymentId,
      idempotencyKey: _idempotencyKey('confirm:$groupId:$paymentId'),
    ),
  );

  @override
  Future<void> rejectPayment({
    required String groupId,
    required String paymentId,
    required String reason,
  }) => _guard(
    () => _remoteDataSource.rejectPayment(
      groupId,
      paymentId,
      reason,
      // Lý do nằm trong key: sửa lý do rồi gửi lại là thao tác mới, không phải
      // retry - nếu không BE sẽ báo lệch canonical request hash.
      idempotencyKey: _idempotencyKey('reject:$groupId:$paymentId:$reason'),
    ),
  );

  @override
  Future<void> remindDebt({
    required String groupId,
    required String debtId,
  }) => _guard(
    () => _remoteDataSource.remindDebt(
      groupId,
      debtId,
      // Nhắc nợ là thao tác lặp lại có chủ đích (BE cho tối đa 3 lần và tự
      // rate limit), nên mỗi lần nhắc là một key mới - khác với các thao tác
      // chỉ được thực hiện một lần ở trên.
      idempotencyKey: _uuid.v4(),
    ),
  );

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
      debts: _mapSkippingMalformed(
        results[0],
        (debt) => _debtFromMap(debt, groupId: id, groupName: name),
      ),
      bills: _mapSkippingMalformed(
        results[1],
        (bill) => _billFromMap(bill, groupId: id, groupName: name),
      ),
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
      lastRemindedAt: _optionalDate(map['last_reminded_at']),
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
      // payer_display_name / paid_member_count / member_count đến từ BE PR #66.
      // Nếu BE chưa deploy thì hiển thị thiếu tiến độ, không phải trắng cả trang.
      payerDisplayName: _optionalString(map['payer_display_name']) ?? '—',
      paidMemberCount: _optionalInteger(map['paid_member_count']) ?? 0,
      memberCount: _optionalInteger(map['member_count']) ?? 0,
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

  /// Trạng thái lạ (BE thêm giá trị mới, ví dụ 'stalled_confirmation' hay
  /// 'rejected' đã có sẵn trong enum DB) được coi là voided thay vì ném lỗi:
  /// mất một dòng còn hơn mất cả bốn tab.
  DebtStatus _debtStatus(String value) {
    return switch (value) {
      'awaiting' => DebtStatus.awaiting,
      'pending_confirmation' => DebtStatus.pendingConfirmation,
      'settled' => DebtStatus.settled,
      _ => DebtStatus.voided,
    };
  }

  /// Tương tự [_debtStatus]: giá trị lạ rơi về superseded, tức là không hiển thị
  /// như một khoản đang chờ xử lý.
  PaymentStatus _paymentStatus(String value) {
    return switch (value) {
      'pending_proof' => PaymentStatus.pendingProof,
      'pending_confirmation' => PaymentStatus.pendingConfirmation,
      'confirmed' => PaymentStatus.confirmed,
      'rejected' => PaymentStatus.rejected,
      _ => PaymentStatus.superseded,
    };
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  /// Một bản ghi hỏng chỉ nên mất chính nó. Trước đây mọi FormatException đều
  /// nổi lên [_guard] và biến thành invalidResponseFailure cho toàn bộ màn hình.
  List<T> _mapSkippingMalformed<T>(
    List<Map<String, dynamic>> source,
    T Function(Map<String, dynamic>) parse,
  ) {
    final parsed = <T>[];
    for (final item in source) {
      try {
        parsed.add(parse(item));
      } on FormatException {
        continue;
      }
    }
    return parsed;
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

  int? _optionalInteger(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  int _integer(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw const FormatException('Expected an integer');
  }

  DateTime? _optionalDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
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
