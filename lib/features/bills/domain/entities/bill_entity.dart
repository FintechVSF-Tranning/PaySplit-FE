import 'package:freezed_annotation/freezed_annotation.dart';

part 'bill_entity.freezed.dart';

/// Vòng đời hóa đơn theo backend (`internal/modules/bill/domain/bill.go`).
enum BillStatus { draft, reviewed, finalized, voided }

/// Trạng thái phần tiền của người đang xem trong một hóa đơn (`my_share_status`).
enum MyShareStatus {
  /// Hóa đơn chưa chốt, hoặc người xem không gánh phần nào.
  none,

  /// Người xem chính là người đã ứng tiền.
  creditor,

  /// Còn nợ người ứng tiền.
  pending,

  /// Đã trả xong (hoặc khoản nợ được xóa khi rời nhóm).
  settled,
}

/// Trạng thái tiến trình OCR gần nhất của hóa đơn (`ocr_status`).
enum OcrJobStatus { none, queued, processing, succeeded, failed }

extension OcrJobStatusX on OcrJobStatus {
  /// Ảnh vẫn đang được AI bóc tách — hóa đơn chưa có món để gán.
  bool get isRunning =>
      this == OcrJobStatus.queued || this == OcrJobStatus.processing;
}

/// Một dòng hóa đơn trong danh sách `GET /api/v1/bills?group_id=...`.
@freezed
class BillEntity with _$BillEntity {
  const factory BillEntity({
    required String id,
    required String groupId,
    required String title,
    required int totalAmount,
    required BillStatus status,
    required DateTime createdAt,
    DateTime? billDate,

    /// Tên người đã trả trước (creditor) — BE trả `payer_display_name`.
    @Default('') String payerName,
    @Default(0) int paidMemberCount,
    @Default(0) int memberCount,

    /// Optimistic locking version — bắt buộc khi huỷ hóa đơn đã chốt.
    @Default(1) int version,

    /// Phần tiền của người đang xem, `null` khi hóa đơn chưa chốt.
    int? myShare,
    @Default(MyShareStatus.none) MyShareStatus myShareStatus,
    @Default(OcrJobStatus.none) OcrJobStatus ocrStatus,
  }) = _BillEntity;
}
