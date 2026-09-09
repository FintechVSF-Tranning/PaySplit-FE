import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/constants/storage_keys.dart';
import 'package:paysplit/core/network/token_storage.dart';

/// TokenStorage giữ credential duy nhất của ứng dụng. Sau spec 0011 nó chỉ còn
/// một khóa `session_id`; nếu một refresh token nào đó lén quay lại đây thì hai
/// credential song song sẽ lệch nhau và người dùng bị đăng xuất ngẫu nhiên.
///
/// covers: AC-19 (ứng dụng giữ đúng một credential), AC-1 (credential đục gửi
/// kèm mọi request), AC-18 (device_id bền hơn phiên, khóa của device_tokens).

/// FlutterSecureStorage trong bộ nhớ. Keychain thật không chạy trong unit test,
/// và điều đang kiểm là TokenStorage đọc ghi đúng khóa nào, không phải Keychain.
class _InMemorySecureStorage implements FlutterSecureStorage {
  final Map<String, String> values = {};
  final List<String> writtenKeys = [];
  final List<String> deletedKeys = [];

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    writtenKeys.add(key);
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    deletedKeys.add(key);
    values.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _InMemorySecureStorage storage;
  late TokenStorage tokens;

  setUp(() {
    storage = _InMemorySecureStorage();
    tokens = TokenStorage(storage);
  });

  group('TokenStorage credential', () {
    test('chưa đăng nhập thì không có session', () async {
      expect(await tokens.sessionId, isNull);
    });

    test('lưu rồi đọc lại đúng credential vừa nhận từ sign-in', () async {
      const credential = 'YSe0MW1ErH0cxUwVtwi_NiurXpWImzpMEEBEJP3bCNk';

      await tokens.saveSession(credential);

      expect(await tokens.sessionId, credential);
      expect(storage.values[StorageKeys.sessionId], credential);
    });

    test(
      'đăng nhập lại ghi đè credential cũ, không giữ song song hai cái',
      () async {
        await tokens.saveSession('credential-cu');
        await tokens.saveSession('credential-moi');

        expect(await tokens.sessionId, 'credential-moi');
        // Chỉ đúng một khóa credential tồn tại. Một khóa refresh token sót lại ở
        // đây là hồi quy đúng nghĩa của spec 0011.
        expect(storage.values.keys.where((k) => k != StorageKeys.deviceId), [
          StorageKeys.sessionId,
        ]);
      },
    );

    test('clear xóa credential và chỉ credential', () async {
      await tokens.saveSession('credential');
      final deviceId = await tokens.getOrCreateDeviceId();

      await tokens.clear();

      expect(await tokens.sessionId, isNull);
      expect(storage.deletedKeys, [StorageKeys.sessionId]);
      // device_id phải sống sót: nó mô tả thiết bị, là khóa của device_tokens
      // phía server, và phải bền hơn phiên.
      expect(await tokens.getOrCreateDeviceId(), deviceId);
    });

    test('clear khi chưa từng đăng nhập vẫn an toàn', () async {
      await tokens.clear();
      expect(await tokens.sessionId, isNull);
    });

    test('không lưu bất kỳ khóa refresh token nào', () async {
      await tokens.saveSession('credential');

      final suspicious = storage.writtenKeys.where(
        (k) =>
            k.toLowerCase().contains('refresh') ||
            k.toLowerCase().contains('access'),
      );
      expect(
        suspicious,
        isEmpty,
        reason:
            'spec 0011 bỏ hẳn cặp access/refresh; một khóa như vậy quay lại là hồi quy',
      );
    });
  });

  group('TokenStorage device id', () {
    test('lần đầu sinh ra một UUID v4 và lưu lại', () async {
      final id = await tokens.getOrCreateDeviceId();

      expect(id, isNotEmpty);
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(id),
        isTrue,
        reason:
            'server validate device_id bằng canonicalUUID và trả 400 nếu sai định dạng',
      );
      expect(storage.values[StorageKeys.deviceId], id);
    });

    test('gọi lại trả đúng device id cũ, không sinh cái mới', () async {
      final first = await tokens.getOrCreateDeviceId();
      final second = await tokens.getOrCreateDeviceId();

      expect(second, first);
    });

    test('device id rỗng trong kho được coi như chưa có và sinh lại', () async {
      storage.values[StorageKeys.deviceId] = '';

      final id = await tokens.getOrCreateDeviceId();

      expect(id, isNotEmpty);
      expect(storage.values[StorageKeys.deviceId], id);
    });

    test('device id bền qua nhiều lần đăng nhập và đăng xuất', () async {
      final original = await tokens.getOrCreateDeviceId();

      await tokens.saveSession('phien-1');
      await tokens.clear();
      await tokens.saveSession('phien-2');
      await tokens.clear();

      expect(await tokens.getOrCreateDeviceId(), original);
    });
  });
}
