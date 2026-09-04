import 'dart:typed_data';

enum DebtStatus { awaiting, pendingConfirmation, settled, voided }

enum PaymentStatus {
  pendingProof,
  pendingConfirmation,
  confirmed,
  rejected,
  superseded,
}

class DebtItemEntity {
  const DebtItemEntity({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.billId,
    required this.billTitle,
    required this.debtorId,
    required this.debtorName,
    required this.debtorAvatar,
    required this.creditorId,
    required this.creditorName,
    required this.creditorAvatar,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.reminderCount = 0,
    this.lastRemindedAt,
    this.paymentId,
  });

  final String id;
  final String groupId;
  final String groupName;
  final String billId;
  final String billTitle;
  final String debtorId;
  final String debtorName;
  final String debtorAvatar;
  final String creditorId;
  final String creditorName;
  final String creditorAvatar;
  final int amount;
  final DebtStatus status;
  final DateTime createdAt;
  final int reminderCount;
  final DateTime? lastRemindedAt;
  final String? paymentId;

  DebtItemEntity copyWith({
    DebtStatus? status,
    int? reminderCount,
    DateTime? lastRemindedAt,
    String? paymentId,
  }) {
    return DebtItemEntity(
      id: id,
      groupId: groupId,
      groupName: groupName,
      billId: billId,
      billTitle: billTitle,
      debtorId: debtorId,
      debtorName: debtorName,
      debtorAvatar: debtorAvatar,
      creditorId: creditorId,
      creditorName: creditorName,
      creditorAvatar: creditorAvatar,
      amount: amount,
      status: status ?? this.status,
      createdAt: createdAt,
      reminderCount: reminderCount ?? this.reminderCount,
      lastRemindedAt: lastRemindedAt ?? this.lastRemindedAt,
      paymentId: paymentId ?? this.paymentId,
    );
  }
}

class SingleCreditorBatchEntity {
  const SingleCreditorBatchEntity({
    required this.groupId,
    required this.groupName,
    required this.creditorId,
    required this.creditorName,
    required this.creditorAvatar,
    required this.debts,
  });

  final String groupId;
  final String groupName;
  final String creditorId;
  final String creditorName;
  final String creditorAvatar;
  final List<DebtItemEntity> debts;

  int get totalAmount => debts.fold(0, (sum, item) => sum + item.amount);
}

class PaymentQrEntity {
  const PaymentQrEntity({
    required this.id,
    required this.groupId,
    required this.amount,
    required this.referenceCode,
    required this.qrPayload,
    required this.qrImageUrl,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    required this.coveredDebtIds,
  });

  final String id;
  final String groupId;
  final int amount;
  final String referenceCode;
  final String qrPayload;
  final String qrImageUrl;
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final List<String> coveredDebtIds;
}

class ProofUploadEntity {
  const ProofUploadEntity({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class ProofDetailEntity {
  const ProofDetailEntity({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.paymentId,
    required this.debtorName,
    required this.debtorAvatar,
    required this.creditorName,
    required this.amount,
    required this.submittedAt,
    required this.targetBank,
    required this.targetAccount,
    required this.referenceCode,
    this.note,
    this.status = PaymentStatus.pendingConfirmation,
    this.isSettled = false,
    this.proofImageUrl,
    this.rejectionReason,
  });

  final String id;
  final String groupId;
  final String groupName;
  final String paymentId;
  final String debtorName;
  final String debtorAvatar;
  final String creditorName;
  final int amount;
  final DateTime submittedAt;
  final String targetBank;
  final String targetAccount;
  final String referenceCode;
  final String? note;
  final PaymentStatus status;
  final bool isSettled;
  final String? proofImageUrl;
  final String? rejectionReason;
}

class SettlementOverviewEntity {
  const SettlementOverviewEntity({
    required this.totalPayable,
    required this.totalReceivable,
    required this.payableCount,
    required this.receivableCount,
    required this.activeGroupsCount,
    required this.pendingProofCount,
  });

  final int totalPayable;
  final int totalReceivable;
  final int payableCount;
  final int receivableCount;
  final int activeGroupsCount;
  final int pendingProofCount;

  int get netBalance => totalReceivable - totalPayable;
  bool get isPositive => netBalance >= 0;
}

class SettledHistoryEntity {
  const SettledHistoryEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    required this.settledAt,
    required this.proof,
  });

  final String id;
  final String title;
  final String subtitle;
  final int amount;
  final bool isIncome;
  final DateTime settledAt;
  final ProofDetailEntity proof;
}

class SettlementBillEntity {
  const SettlementBillEntity({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.title,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.payerDisplayName,
    required this.paidMemberCount,
    required this.memberCount,
  });

  final String id;
  final String groupId;
  final String groupName;
  final String title;
  final int amount;
  final String status;
  final DateTime createdAt;
  final String payerDisplayName;
  final int paidMemberCount;
  final int memberCount;

  double get paidRatio => memberCount == 0 ? 0 : paidMemberCount / memberCount;
}

class SettlementDataEntity {
  const SettlementDataEntity({
    required this.overview,
    required this.payableDebts,
    required this.receivableDebts,
    required this.groupedDebts,
    required this.pendingProofs,
    required this.settledHistory,
    required this.bills,
  });

  final SettlementOverviewEntity overview;
  final List<DebtItemEntity> payableDebts;
  final List<DebtItemEntity> receivableDebts;
  final List<SingleCreditorBatchEntity> groupedDebts;
  final List<ProofDetailEntity> pendingProofs;
  final List<SettledHistoryEntity> settledHistory;
  final List<SettlementBillEntity> bills;
}
