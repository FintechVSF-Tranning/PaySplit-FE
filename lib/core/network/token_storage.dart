import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../constants/storage_keys.dart';

@lazySingleton
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;
  static const _uuid = Uuid();

  Future<String?> get accessToken => _storage.read(key: StorageKeys.accessToken);

  Future<String?> get refreshToken => _storage.read(key: StorageKeys.refreshToken);

  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.read(key: StorageKeys.deviceId);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final newId = _uuid.v4();
    await _storage.write(key: StorageKeys.deviceId, value: newId);
    return newId;
  }

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await Future.wait([
      _storage.write(key: StorageKeys.accessToken, value: accessToken),
      _storage.write(key: StorageKeys.refreshToken, value: refreshToken),
    ]);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: StorageKeys.accessToken),
      _storage.delete(key: StorageKeys.refreshToken),
    ]);
  }
}
