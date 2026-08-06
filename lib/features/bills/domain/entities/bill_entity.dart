import 'package:freezed_annotation/freezed_annotation.dart';

part 'bill_entity.freezed.dart';

enum BillStatus { pending, settled }

@freezed
class BillEntity with _$BillEntity {
  const factory BillEntity({
    required String id,
    required String title,
    required double totalAmount,
    required BillStatus status,
    required DateTime createdAt,
  }) = _BillEntity;
}
