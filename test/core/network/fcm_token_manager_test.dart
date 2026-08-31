import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/network/fcm_token_manager.dart';

void main() {
  test(
    'retry đồng bộ token sau lỗi tạm thời rồi dừng khi thành công',
    () async {
      var uploadAttempts = 0;
      final manager = FCMTokenManager.forTesting(
        readAccessToken: () async => 'access-token',
        uploadToken: (token) async {
          uploadAttempts++;
          return uploadAttempts == 1 ? 503 : 204;
        },
        deleteToken: () async {},
        retryDelays: const [Duration.zero],
      );

      expect(await manager.syncTokenWithBackend('fcm-token'), isFalse);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(uploadAttempts, 2);
      expect(manager.hasPendingRetry, isFalse);
    },
  );

  test('logout hủy retry đang chờ và xóa token Firebase', () async {
    var deleteCalls = 0;
    final manager = FCMTokenManager.forTesting(
      readAccessToken: () async => 'access-token',
      uploadToken: (_) async => 503,
      deleteToken: () async {
        deleteCalls++;
      },
      retryDelays: const [Duration(days: 1)],
    );

    expect(await manager.syncTokenWithBackend('fcm-token'), isFalse);
    expect(manager.hasPendingRetry, isTrue);

    await manager.onLogout();

    expect(manager.hasPendingRetry, isFalse);
    expect(deleteCalls, 1);
  });
}
