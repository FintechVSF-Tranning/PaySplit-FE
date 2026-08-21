import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/bill_entity.dart';

part 'bill_model.freezed.dart';
part 'bill_model.g.dart';

@freezed
abstract class BillModel with _$BillModel {
  const BillModel._();

  const factory BillModel({
    required String id,
    required String title,
    @JsonKey(name: 'total_amount') required double totalAmount,
    required String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _BillModel;

  factory BillModel.fromJson(Map<String, dynamic> json) => _$BillModelFromJson(json);

  BillEntity toEntity() => BillEntity(
    id: id,
    title: title,
    totalAmount: totalAmount,
    status: BillStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => BillStatus.pending,
    ),
    createdAt: createdAt,
  );
}
