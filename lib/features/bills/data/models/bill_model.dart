import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/bill_entity.dart';

part 'bill_model.freezed.dart';
part 'bill_model.g.dart';

/// DTO của một phần tử trong `data.bills` của `GET /api/v1/bills`.
///
/// BE nhúng `*Bill` vào `BillListItem` nên các field của hóa đơn nằm ở top
/// level cùng `payer_display_name` / `paid_member_count` / `member_count`.
@freezed
class BillModel with _$BillModel {
  const BillModel._();

  const factory BillModel({
    required String id,
    @JsonKey(name: 'group_id') @Default('') String groupId,
    @JsonKey(name: 'merchant_name') String? merchantName,
    @Default(0) int total,
    @Default('draft') String status,
    @JsonKey(name: 'bill_date') DateTime? billDate,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'payer_display_name') @Default('') String payerDisplayName,
    @JsonKey(name: 'paid_member_count') @Default(0) int paidMemberCount,
    @JsonKey(name: 'member_count') @Default(0) int memberCount,
    @JsonKey(name: 'my_share') int? myShare,
    @JsonKey(name: 'my_share_status') @Default('none') String myShareStatus,
    @JsonKey(name: 'ocr_status') @Default('') String ocrStatus,
    @Default(1) int version,
  }) = _BillModel;

  factory BillModel.fromJson(Map<String, dynamic> json) =>
      _$BillModelFromJson(json);

  BillEntity toEntity() => BillEntity(
    id: id,
    groupId: groupId,
    title: (merchantName == null || merchantName!.trim().isEmpty)
        ? 'Hóa đơn chưa đặt tên'
        : merchantName!.trim(),
    totalAmount: total,
    status: BillStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => BillStatus.draft,
    ),
    createdAt: createdAt ?? billDate ?? DateTime.now(),
    billDate: billDate,
    payerName: payerDisplayName,
    paidMemberCount: paidMemberCount,
    memberCount: memberCount,
    version: version,
    myShare: myShare,
    myShareStatus: MyShareStatus.values.firstWhere(
      (s) => s.name == myShareStatus,
      orElse: () => MyShareStatus.none,
    ),
    ocrStatus: OcrJobStatus.values.firstWhere(
      (s) => s.name == ocrStatus,
      orElse: () => OcrJobStatus.none,
    ),
  );
}
