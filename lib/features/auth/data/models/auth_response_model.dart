import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_model.dart';

part 'auth_response_model.freezed.dart';
part 'auth_response_model.g.dart';

@freezed
class AuthResponseModel with _$AuthResponseModel {
  const factory AuthResponseModel({
    /// Credential duy nhất — chuỗi đục 43 ký tự, gửi kèm mọi request qua
    /// header `Authorization: Bearer <sessionId>`. Không phải JWT: không mang
    /// thông tin gì, chỉ server tra được.
    @JsonKey(name: 'session_id') required String sessionId,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
    required UserModel user,
  }) = _AuthResponseModel;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);
}
