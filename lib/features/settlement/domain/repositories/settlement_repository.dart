import '../entities/settlement_entities.dart';

abstract class SettlementRepository {
  Future<SettlementDataEntity> loadSettlement();

  Future<PaymentQrEntity> generatePaymentQr({
    required String groupId,
    required String creditorId,
    required List<String> debtIds,
  });

  Future<void> confirmPayment({
    required String groupId,
    required String paymentId,
  });

  Future<void> rejectPayment({
    required String groupId,
    required String paymentId,
    required String reason,
  });

  Future<void> remindDebt({required String groupId, required String debtId});

  Future<void> submitProof({
    required String groupId,
    required String paymentId,
    required ProofUploadEntity image,
    String? note,
  });
}
