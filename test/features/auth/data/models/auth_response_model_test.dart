import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/auth/data/models/auth_response_model.dart';

/// Đây là hợp đồng giữa Flutter và `POST /api/v1/auth/sign-in`. Spec 0011 đổi
/// hẳn shape của nó: `access_token` và `refresh_token` biến mất, thay bằng
/// `session_id` và `expires_at`. Test này khóa shape mới lại, để một lần đổi
/// backend không âm thầm làm app parse hụt.
///
/// covers: AC-17 (response đăng nhập trả session_id và expires_at, không còn
/// cặp token), AC-1 (credential đục 43 ký tự), AC-19 (một credential duy nhất).

Map<String, dynamic> signInPayload({
  String sessionId = 'YSe0MW1ErH0cxUwVtwi_NiurXpWImzpMEEBEJP3bCNk',
  String expiresAt = '2026-10-09T10:34:02.349393+07:00',
}) {
  return {
    'session_id': sessionId,
    'expires_at': expiresAt,
    'user': {
      'id': '01a0843a-1ed2-7e45-b0ef-5448b0703526',
      'email': 'nguoidung@example.com',
      'phone_number': '+84988924796',
      'display_name': 'Nguoi Dung',
      'role': 'user',
      'status': 'active',
      'email_verified_at': '2026-09-09T10:33:28.322710+07:00',
      'bank_code': null,
      'bank_account_number': null,
      'bank_account_holder': null,
      'avatar_url': null,
      'created_at': '2026-09-09T10:33:16.626402+07:00',
      'updated_at': '2026-09-09T10:33:28.322710+07:00',
    },
  };
}

void main() {
  group('AuthResponseModel.fromJson', () {
    test('parse đúng response đăng nhập thật của backend', () {
      final model = AuthResponseModel.fromJson(signInPayload());

      expect(model.sessionId, 'YSe0MW1ErH0cxUwVtwi_NiurXpWImzpMEEBEJP3bCNk');
      expect(
        model.expiresAt,
        DateTime.parse('2026-10-09T10:34:02.349393+07:00'),
      );
      expect(model.user.id, '01a0843a-1ed2-7e45-b0ef-5448b0703526');
      expect(model.user.email, 'nguoidung@example.com');
    });

    test('credential dài đúng 43 ký tự base64url như CSPRNG 32 byte sinh ra', () {
      final model = AuthResponseModel.fromJson(signInPayload());

      expect(model.sessionId, hasLength(43));
      expect(
        RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(model.sessionId),
        isTrue,
        reason:
            'base64url không đệm; ký tự lạ nghĩa là backend đã đổi cách sinh credential',
      );
    });

    test('bỏ qua field lạ để backend thêm field mới không làm sập app', () {
      final payload = signInPayload()
        ..['token_type'] = 'Bearer'
        ..['mot_field_moi_nao_do'] = 123;

      final model = AuthResponseModel.fromJson(payload);

      expect(model.sessionId, isNotEmpty);
    });

    test('thiếu session_id là lỗi, không phải chuỗi rỗng im lặng', () {
      final payload = signInPayload()..remove('session_id');

      // Một credential rỗng đi qua lặng lẽ sẽ biến thành `Bearer ` và mọi
      // request trả 401 mà không ai biết vì sao.
      expect(
        () => AuthResponseModel.fromJson(payload),
        throwsA(isA<TypeError>()),
      );
    });

    test('thiếu expires_at là lỗi', () {
      final payload = signInPayload()..remove('expires_at');

      expect(
        () => AuthResponseModel.fromJson(payload),
        throwsA(isA<TypeError>()),
      );
    });

    test('expires_at không phải ngày hợp lệ thì ném lỗi', () {
      final payload = signInPayload(expiresAt: 'khong-phai-ngay');

      expect(
        () => AuthResponseModel.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('expires_at giữ nguyên mốc thời gian tuyệt đối kèm offset', () {
      final model = AuthResponseModel.fromJson(signInPayload());

      // Trần tuyệt đối mặc định là 720 giờ. App hiển thị mốc này cho người dùng,
      // nên mất offset sẽ lệch bảy tiếng ở giờ Việt Nam.
      expect(
        model.expiresAt.toUtc(),
        DateTime.parse('2026-10-09T03:34:02.349393Z'),
      );
    });

    test('model không có chỗ nào để chứa access token hay refresh token', () {
      final json = AuthResponseModel.fromJson(signInPayload()).toJson();

      expect(
        json.keys,
        isNot(anyElement(anyOf(contains('refresh'), equals('access_token')))),
        reason:
            'spec 0011 bỏ hẳn cặp token; một field như vậy quay lại là hồi quy',
      );
      expect(json.keys, containsAll(<String>['session_id', 'expires_at']));
    });

    test('mã hóa ra JSON rồi đọc lại cho ra cùng một giá trị', () {
      final original = AuthResponseModel.fromJson(signInPayload());

      // Đi qua jsonEncode chứ không dùng thẳng toJson(): trong map mà toJson()
      // trả về, `user` vẫn là một UserModel chứ chưa phải Map. dart:convert tự
      // gọi toJson() của nó khi mã hóa, nên đường thật của ứng dụng chạy đúng.
      final encoded = jsonEncode(original.toJson());
      final roundTripped = AuthResponseModel.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );

      expect(roundTripped.sessionId, original.sessionId);
      expect(roundTripped.expiresAt, original.expiresAt);
      expect(roundTripped.user.id, original.user.id);
    });
  });
}
