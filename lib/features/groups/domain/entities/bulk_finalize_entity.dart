import 'package:equatable/equatable.dart';

enum BulkFinalizeStatus { queued, processing, completed }

enum BulkFinalizeItemStatus { pending, finalized, failed }

class BulkFinalizeItemEntity extends Equatable {
  const BulkFinalizeItemEntity({
    required this.billId,
    required this.billName,
    required this.status,
    this.errorCode,
    this.billVersion,
    this.capturedReviewed,
  });

  final String billId;
  final String billName;
  final BulkFinalizeItemStatus status;
  final String? errorCode;

  /// Bill version captured at batch creation time; used together with
  /// [capturedReviewed] to verify whether a `BILL_IMMUTABLE` result means
  /// the bill was actually finalized at the expected version.
  final int? billVersion;
  final bool? capturedReviewed;

  /// Whether this item's error allows opening the bill for editing.
  bool get canOpenBill =>
      status == BulkFinalizeItemStatus.failed &&
      errorCode != 'BILL_DELETED' &&
      errorCode != 'BILL_ALREADY_VOIDED';

  String get resultText {
    if (status == BulkFinalizeItemStatus.finalized) return 'Đã chốt';
    if (status == BulkFinalizeItemStatus.pending) return 'Đang chờ xử lý';
    return switch (errorCode) {
      'VERSION_CONFLICT' => 'Bill vừa thay đổi, hãy kiểm tra lại',
      'BILL_NOT_READY' => 'Bill chưa đủ dữ liệu để chốt',
      'BANK_ACCOUNT_REQUIRED' => 'Người nhận chưa cài tài khoản ngân hàng',
      'BILL_DELETED' => 'Bill đã bị xóa',
      'BILL_ALREADY_VOIDED' => 'Bill đã bị hủy',
      'BILL_IMMUTABLE' => 'Bill đã chốt hoặc đã hủy',
      'DISCOUNT_NOT_ALLOCATABLE' => 'Giảm giá chưa thể phân bổ',
      _ => 'Không thể chốt bill này',
    };
  }

  String get actionLabel => switch (errorCode) {
    'VERSION_CONFLICT' => 'Tải lại bill',
    'BILL_NOT_READY' => 'Mở và sửa bill',
    'BANK_ACCOUNT_REQUIRED' => 'Xem bill',
    'BILL_IMMUTABLE' => 'Tải lại bill',
    _ => 'Mở bill',
  };

  @override
  List<Object?> get props => [
    billId,
    billName,
    status,
    errorCode,
    billVersion,
    capturedReviewed,
  ];
}

class BulkFinalizeBatchEntity extends Equatable {
  const BulkFinalizeBatchEntity({
    required this.id,
    required this.status,
    required this.targetCount,
    required this.finalizedCount,
    required this.failedCount,
    this.items = const [],
    this.nextCursor,
  });

  final String id;
  final BulkFinalizeStatus status;
  final int targetCount;
  final int finalizedCount;
  final int failedCount;
  final List<BulkFinalizeItemEntity> items;
  final String? nextCursor;

  bool get isComplete => status == BulkFinalizeStatus.completed;
  int get processedCount => finalizedCount + failedCount;

  /// Sentinel to distinguish "not passed" from "explicitly set to null".
  static const _unsetCursor = Object();

  BulkFinalizeBatchEntity copyWith({
    List<BulkFinalizeItemEntity>? items,
    Object? nextCursor = _unsetCursor,
  }) => BulkFinalizeBatchEntity(
    id: id,
    status: status,
    targetCount: targetCount,
    finalizedCount: finalizedCount,
    failedCount: failedCount,
    items: items ?? this.items,
    nextCursor: identical(nextCursor, _unsetCursor)
        ? this.nextCursor
        : nextCursor as String?,
  );

  @override
  List<Object?> get props => [
    id,
    status,
    targetCount,
    finalizedCount,
    failedCount,
    items,
    nextCursor,
  ];
}
