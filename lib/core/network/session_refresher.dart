import 'dart:async';

import 'package:dio/dio.dart';

import '../config/env_config.dart';
import '../constants/api_endpoints.dart';
import 'session_events.dart';
import 'token_storage.dart';

/// Nơi duy nhất xoay vòng refresh token, và là nơi duy nhất kết thúc phiên.
///
/// Phải là một instance dùng chung cho mọi người gọi. Refresh token là dùng một
/// lần: hai lần làm mới song song cùng xuất phát từ một token sẽ bị backend coi
/// là tái sử dụng và thu hồi cả họ token — nghĩa là người dùng bị đá ra ngoài
/// đúng lúc app đang tự cứu mình. Vì thế [refresh] gom mọi lời gọi trùng nhau
/// vào một future duy nhất.
///
/// Đăng ký qua `NetworkModule` chứ không bằng annotation: hàm dựng có seam cho
/// test mà injectable không phân giải được.
class SessionRefresher {
  SessionRefresher(
    this._tokens,
    this._sessionEvents, {
    Dio Function(BaseOptions)? dioFactory,
    this.baseUrlOverride,
  }) : _dioFactory = dioFactory ?? Dio.new;

  final TokenStorage _tokens;
  final SessionEvents? _sessionEvents;
  final Dio Function(BaseOptions) _dioFactory;

  /// Base URL cố định cho test; mặc định lấy từ [EnvConfig].
  final String? baseUrlOverride;

  Future<bool>? _inFlight;
  bool _endNotified = false;

  String get baseUrl => baseUrlOverride ?? EnvConfig.apiBaseUrl;

  /// Làm mới cặp token. Trả `false` khi phiên không cứu được nữa.
  Future<bool> refresh() {
    final existing = _inFlight;
    if (existing != null) return existing;
    final started = _refresh().whenComplete(() => _inFlight = null);
    _inFlight = started;
    return started;
  }

  Future<bool> _refresh() async {
    final refreshToken = await _tokens.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response =
          await _dioFactory(
            BaseOptions(baseUrl: baseUrl, contentType: 'application/json'),
          ).post<Map<String, dynamic>>(
            ApiEndpoints.refreshToken,
            data: {
              'refresh_token': refreshToken,
              'device_id': await _tokens.getOrCreateDeviceId(),
            },
          );

      final body = response.data;
      if (body == null) return false;
      // Backend bọc payload trong envelope `{success, data, message}`.
      final data = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body;
      final access = data['access_token'] as String?;
      final refresh = data['refresh_token'] as String?;
      if (access == null ||
          access.isEmpty ||
          refresh == null ||
          refresh.isEmpty) {
        return false;
      }

      await _tokens.saveTokens(accessToken: access, refreshToken: refresh);
      // Làm mới được nghĩa là phiên vẫn sống: lần mất phiên sau phải được báo lại.
      _endNotified = false;
      return true;
    } on DioException {
      return false;
    }
  }

  /// Kết thúc phiên: xóa token và báo lên UI đúng một lần.
  ///
  /// Nhiều đường cùng chết vì một phiên hỏng (vài request REST song song cộng
  /// thêm stream realtime), nên nếu không chặn, UI nhận cả loạt sự kiện cho
  /// cùng một sự việc.
  Future<void> endSession() async {
    final hadToken =
        (await _tokens.refreshToken)?.isNotEmpty == true ||
        (await _tokens.accessToken)?.isNotEmpty == true;
    await _tokens.clear();
    if (_endNotified) return;
    _endNotified = true;
    if (hadToken) {
      _sessionEvents?.notifyExpired();
    }
  }
}
