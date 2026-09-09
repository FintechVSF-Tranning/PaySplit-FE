import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../constants/storage_keys.dart';

@lazySingleton
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;
  static const _uuid = Uuid();

  /// Credential duy nhất: một session ID đục do `POST /auth/sign-in` cấp, gửi
  /// kèm mọi request qua header `Authorization: Bearer <sessionId>`. Server tự
  /// gia hạn phiên mỗi request (TTL trượt trên Redis), nên không có refresh
  /// token nào để lưu song song.
  Future<String?> get sessionId => _storage.read(key: StorageKeys.sessionId);

  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.read(key: StorageKeys.deviceId);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final newId = _uuid.v4();
    await _storage.write(key: StorageKeys.deviceId, value: newId);
    return newId;
  }

  Future<void> saveSession(String sessionId) {
    return _storage.write(key: StorageKeys.sessionId, value: sessionId);
  }

  Future<void> clear() {
    return _storage.delete(key: StorageKeys.sessionId);
  }
}
