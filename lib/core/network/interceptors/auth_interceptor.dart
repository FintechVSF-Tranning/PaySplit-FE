import 'dart:async';

import 'package:dio/dio.dart';

import '../../constants/api_endpoints.dart';
import '../session_events.dart';
import '../session_refresher.dart';
import '../token_storage.dart';

/// Gắn bearer token vào mọi request và tự xoay vòng token khi gặp 401.
///
/// Access token chỉ sống 15 phút (`JWT_ACCESS_TOKEN_TTL_MINUTES`), nên nếu
/// không làm mới thì toàn bộ ứng dụng sẽ trả 401 sau đúng 15 phút kể từ lúc
/// đăng nhập. Việc làm mới đặt ở đây thay vì trong từng repository để mọi
/// module (auth, groups, bills, settlement...) đều được bảo vệ như nhau.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._tokenStorage,
    String baseUrl, {
    Dio Function(BaseOptions)? dioFactory,
    this.sessionEvents,
    SessionRefresher? refresher,
  }) : _dioFactory = dioFactory ?? Dio.new,
       _refresher =
           refresher ??
           SessionRefresher(
             _tokenStorage,
             sessionEvents,
             dioFactory: dioFactory,
             baseUrlOverride: baseUrl,
           );

  final TokenStorage _tokenStorage;

  /// Xoay vòng token và kết thúc phiên. Dùng chung với stream SSE: hai đường
  /// tự làm mới độc lập sẽ cùng tiêu một refresh token và bị backend thu hồi
  /// cả họ token vì tưởng là tái sử dụng.
  final SessionRefresher _refresher;

  /// Báo lên tầng UI khi phiên mất hẳn, để app đưa người dùng về màn đăng nhập
  /// thay vì đứng yên với một loạt request 401.
  final SessionEvents? sessionEvents;

  /// Cách dựng Dio cho lời gọi làm mới và lần thử lại. Tách ra thành tham số
  /// để test có thể tiêm adapter giả; mặc định là `Dio.new`.
  final Dio Function(BaseOptions) _dioFactory;

  /// Đánh dấu request đã được thử lại sau khi làm mới token, để một request
  /// không rơi vào vòng lặp 401 → refresh → 401 vô hạn.
  static const String _retriedFlag = 'auth_interceptor_retried';

  /// Các endpoint không bao giờ được làm mới token: bản thân chúng là cách lấy
  /// token, gọi refresh ở đây sẽ tạo đệ quy.
  static const Set<String> _skipRefreshPaths = {
    ApiEndpoints.login,
    ApiEndpoints.register,
    ApiEndpoints.refreshToken,
    ApiEndpoints.forgotPassword,
    ApiEndpoints.resetPassword,
    ApiEndpoints.verifyEmail,
    ApiEndpoints.resendVerification,
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final shouldTryRefresh =
        err.response?.statusCode == 401 &&
        !_skipRefreshPaths.contains(request.path) &&
        request.extra[_retriedFlag] != true;

    if (!shouldTryRefresh) {
      // 401 trên chính các endpoint xác thực (sai mật khẩu, OTP hỏng...) không
      // phải là mất phiên: người dùng chưa đăng nhập, đừng đụng vào token và
      // đừng đá ai ra khỏi đâu cả.
      if (err.response?.statusCode == 401 && !_skipRefreshPaths.contains(request.path)) {
        // Còn lại là request đã thử lại bằng token mới mà vẫn 401 — phiên hỏng thật.
        await _endSession();
      }
      handler.next(err);
      return;
    }

    final refreshed = await _refresher.refresh();

    if (!refreshed) {
      await _endSession();
      handler.next(err);
      return;
    }

    try {
      handler.resolve(await _retry(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<void> _endSession() => _refresher.endSession();

  Future<Response<dynamic>> _retry(RequestOptions request) {
    final token = _tokenStorage.accessToken;
    return token.then((value) {
      final headers = Map<String, dynamic>.from(request.headers);
      if (value != null && value.isNotEmpty) {
        headers['Authorization'] = 'Bearer $value';
      }
      return _dioFactory(BaseOptions(baseUrl: request.baseUrl)).fetch<dynamic>(
        request.copyWith(headers: headers, extra: {...request.extra, _retriedFlag: true}),
      );
    });
  }
}
