import '../entities/settlement_entities.dart';

abstract class SettlementRepository {
  /// Nạp dữ liệu đối soát của mọi nhóm.
  ///
  /// [onlyGroupId] cho phép nạp lại đúng một nhóm và tái dùng dữ liệu đã nạp
  /// của các nhóm còn lại. Dùng cho lượt làm mới do realtime kích hoạt: sự kiện
  /// luôn kèm `group_id`, nên nạp lại cả N nhóm là thừa N-1 lần.
  Future<SettlementDataEntity> loadSettlement({String? onlyGroupId});

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
