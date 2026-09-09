/// Keys used with [FlutterSecureStorage] / [SharedPreferences].
abstract class StorageKeys {
  /// Session ID đục (opaque), credential duy nhất kể từ khi bỏ cặp
  /// access/refresh token. Server tự gia hạn phiên bằng TTL trượt trên Redis,
  /// nên không còn refresh token nào để lưu.
  static const String sessionId = 'session_id';
  static const String deviceId = 'device_id';
  static const String cachedUser = 'cached_user';
  static const String onboardingSeen = 'onboarding_seen';
}
