import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../di/injection.dart';
import '../constants/api_endpoints.dart';
import 'token_storage.dart';

typedef AccessTokenReader = Future<String?> Function();
typedef FCMTokenUploader = Future<int?> Function(String token);
typedef FirebaseTokenDeleter = Future<void> Function();

/// Quản lý vòng đời của Firebase Cloud Messaging (FCM) Registration Token:
/// - Xin quyền thông báo hệ điều hành (POST_NOTIFICATIONS / APNs).
/// - Lấy FCM token và gửi lên Backend (`PUT /api/v1/users/me/fcm-token`).
/// - Lắng nghe sự kiện token refresh và tự động cập nhật lên Backend.
/// - Dọn dẹp / hủy token khi đăng xuất.
class FCMTokenManager {
  FCMTokenManager._({
    AccessTokenReader? readAccessToken,
    FCMTokenUploader? uploadToken,
    FirebaseTokenDeleter? deleteToken,
    this._retryDelays = _defaultRetryDelays,
  }) : _readAccessToken = readAccessToken ?? _defaultReadAccessToken,
       _uploadToken = uploadToken ?? _defaultUploadToken,
       _deleteToken = deleteToken ?? _defaultDeleteToken;

  static final FCMTokenManager instance = FCMTokenManager._();

  @visibleForTesting
  factory FCMTokenManager.forTesting({
    required AccessTokenReader readAccessToken,
    required FCMTokenUploader uploadToken,
    required FirebaseTokenDeleter deleteToken,
    List<Duration> retryDelays = _defaultRetryDelays,
  }) => FCMTokenManager._(
    readAccessToken: readAccessToken,
    uploadToken: uploadToken,
    deleteToken: deleteToken,
    retryDelays: retryDelays,
  );

  static const List<Duration> _defaultRetryDelays = [
    Duration(seconds: 10),
    Duration(minutes: 1),
    Duration(minutes: 5),
  ];

  final AccessTokenReader _readAccessToken;
  final FCMTokenUploader _uploadToken;
  final FirebaseTokenDeleter _deleteToken;
  final List<Duration> _retryDelays;

  StreamSubscription<String>? _tokenRefreshSubscription;
  Timer? _retryTimer;
  String? _lastSyncedToken;
  String? _pendingToken;
  int _retryAttempt = 0;
  int _sessionEpoch = 0;
  bool _isInitializing = false;

  @visibleForTesting
  bool get hasPendingRetry => _pendingToken != null || _retryTimer != null;

  static Future<String?> _defaultReadAccessToken() async {
    return getIt<TokenStorage>().accessToken;
  }

  static Future<int?> _defaultUploadToken(String token) async {
    final response = await getIt<Dio>().put<dynamic>(
      ApiEndpoints.fcmToken,
      data: {'fcm_token': token},
    );
    return response.statusCode;
  }

  static Future<void> _defaultDeleteToken() {
    return FirebaseMessaging.instance.deleteToken();
  }

  /// Lấy FCM Token hiện tại của thiết bị.
  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('FCMTokenManager.getToken error: $e');
      return null;
    }
  }

  /// Khởi tạo FCM: Xin quyền, lấy token và đồng bộ lên server nếu đã đăng nhập.
  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      // 1. Xin quyền thông báo (iOS & Android 13+)
      final settings = await FirebaseMessaging.instance.requestPermission();

      debugPrint(
        'FCM Notification permission status: ${settings.authorizationStatus}',
      );

      // 2. Lấy FCM Token ban đầu
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        await syncTokenWithBackend(token);
      }

      // 3. Lắng nghe sự kiện Token được làm mới bởi Google Play Services / Firebase
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
          .listen(
            (newToken) async {
              debugPrint('FCM Token refreshed');
              await syncTokenWithBackend(newToken);
            },
            onError: (Object error) {
              debugPrint('FCM onTokenRefresh error: $error');
            },
          );
    } catch (e) {
      debugPrint('FCMTokenManager.initialize error: $e');
    } finally {
      _isInitializing = false;
    }
  }

  /// Gửi FCM Token lên Backend để lưu vào Session hiện tại.
  Future<bool> syncTokenWithBackend([String? token]) async {
    String? fcmToken = token;
    try {
      final accessToken = await _readAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        // Chưa đăng nhập, không cần gửi lên server
        return false;
      }

      fcmToken ??= await getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        return false;
      }

      if (_lastSyncedToken == fcmToken) {
        // Đã đồng bộ token này rồi, tránh gọi lặp lại
        return true;
      }

      final statusCode = await _uploadToken(fcmToken);

      if (statusCode == 200 || statusCode == 204) {
        _lastSyncedToken = fcmToken;
        _clearRetry();
        debugPrint('FCM Token synced successfully with Backend');
        return true;
      }
      _scheduleRetry(fcmToken);
      return false;
    } catch (_) {
      if (fcmToken != null && fcmToken.isNotEmpty) {
        _scheduleRetry(fcmToken);
      }
      debugPrint('FCMTokenManager.syncTokenWithBackend failed');
      return false;
    }
  }

  void _scheduleRetry(String token) {
    _pendingToken = token;
    if (_retryTimer?.isActive ?? false) return;
    if (_retryAttempt >= _retryDelays.length) return;

    final delay = _retryDelays[_retryAttempt];
    _retryAttempt++;
    final epoch = _sessionEpoch;
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      if (epoch != _sessionEpoch) return;
      final pendingToken = _pendingToken;
      if (pendingToken != null) {
        unawaited(syncTokenWithBackend(pendingToken));
      }
    });
  }

  void _clearRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _pendingToken = null;
    _retryAttempt = 0;
  }

  /// Xử lý khi đăng xuất: Hủy đăng ký lắng nghe refresh và xóa cache token.
  Future<void> onLogout() async {
    try {
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
      _lastSyncedToken = null;
      _sessionEpoch++;
      _clearRetry();

      // Xóa token trên Firebase server để thiết bị này không nhận push của user cũ
      await _deleteToken();
    } catch (e) {
      debugPrint('FCMTokenManager.onLogout error: $e');
    }
  }

  /// Hủy subscription khi app đóng
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _clearRetry();
  }
}
