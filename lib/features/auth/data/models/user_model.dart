import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    @JsonKey(name: 'display_name') String? displayName,
    String? name,
    required String email,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    @JsonKey(name: 'bank_code') String? bankCode,
    @JsonKey(name: 'bank_account_number') String? bankAccountNumber,
    @JsonKey(name: 'bank_account_holder') String? bankAccountHolder,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  UserEntity toEntity() => UserEntity(
        id: id,
        name: displayName ?? name ?? email.split('@').first,
        email: email,
        avatarUrl: avatarUrl,
        phoneNumber: phoneNumber,
        bankCode: bankCode,
        bankAccountNumber: bankAccountNumber,
        bankAccountHolder: bankAccountHolder,
      );
}
