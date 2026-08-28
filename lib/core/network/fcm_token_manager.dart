import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../di/injection.dart';
import '../constants/api_endpoints.dart';
import 'token_storage.dart';

/// Quản lý vòng đời của Firebase Cloud Messaging (FCM) Registration Token:
/// - Xin quyền thông báo hệ điều hành (POST_NOTIFICATIONS / APNs).
/// - Lấy FCM token và gửi lên Backend (`PUT /api/v1/users/me/fcm-token`).
/// - Lắng nghe sự kiện token refresh và tự động cập nhật lên Backend.
/// - Dọn dẹp / hủy token khi đăng xuất.
class FCMTokenManager {
  FCMTokenManager._();

  static final FCMTokenManager instance = FCMTokenManager._();

  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _lastSyncedToken;
  bool _isInitializing = false;

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
        debugPrint('FCM Registration Token: $token');
        await syncTokenWithBackend(token);
      }

      // 3. Lắng nghe sự kiện Token được làm mới bởi Google Play Services / Firebase
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
          .listen(
            (newToken) async {
              debugPrint('FCM Token refreshed: $newToken');
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
    try {
      final tokenStorage = getIt<TokenStorage>();
      final accessToken = await tokenStorage.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        // Chưa đăng nhập, không cần gửi lên server
        return false;
      }

      final fcmToken = token ?? await getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        return false;
      }

      if (_lastSyncedToken == fcmToken) {
        // Đã đồng bộ token này rồi, tránh gọi lặp lại
        return true;
      }

      final dio = getIt<Dio>();
      final response = await dio.put<dynamic>(
        ApiEndpoints.fcmToken,
        data: {'fcm_token': fcmToken},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _lastSyncedToken = fcmToken;
        debugPrint('FCM Token synced successfully with Backend');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('FCMTokenManager.syncTokenWithBackend error: $e');
      return false;
    }
  }

  /// Xử lý khi đăng xuất: Hủy đăng ký lắng nghe refresh và xóa cache token.
  Future<void> onLogout() async {
    try {
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
      _lastSyncedToken = null;

      // Xóa token trên Firebase server để thiết bị này không nhận push của user cũ
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('FCMTokenManager.onLogout error: $e');
    }
  }

  /// Hủy subscription khi app đóng
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}
