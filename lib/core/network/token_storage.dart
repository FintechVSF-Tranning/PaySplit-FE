import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../constants/storage_keys.dart';

/// Persists auth tokens outside the widget tree so both the DI-managed
/// [AuthInterceptor] and the auth feature's datasource can read/write them
/// without depending on each other.
@lazySingleton
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> get accessToken => _storage.read(key: StorageKeys.accessToken);

  Future<String?> get refreshToken => _storage.read(key: StorageKeys.refreshToken);

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
