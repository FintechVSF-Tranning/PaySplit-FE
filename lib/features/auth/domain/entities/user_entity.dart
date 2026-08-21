import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

@freezed
abstract class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String name,
    required String email,
    String? avatarUrl,
    String? phoneNumber,
    String? bankCode,
    String? bankAccountNumber,
    String? bankAccountHolder,
  }) = _UserEntity;
}
