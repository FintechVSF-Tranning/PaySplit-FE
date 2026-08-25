import 'dart:async';

import 'package:dio/dio.dart';

import '../../constants/api_endpoints.dart';
import '../token_storage.dart';

/// Gắn bearer token vào mọi request và tự xoay vòng token khi gặp 401.
///
/// Access token chỉ sống 15 phút (`JWT_ACCESS_TOKEN_TTL_MINUTES`), nên nếu
/// không làm mới thì toàn bộ ứng dụng sẽ trả 401 sau đúng 15 phút kể từ lúc
/// đăng nhập. Việc làm mới đặt ở đây thay vì trong từng repository để mọi
/// module (auth, groups, bills, settlement...) đều được bảo vệ như nhau.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage, this._baseUrl, {Dio Function(BaseOptions)? dioFactory})
    : _dioFactory = dioFactory ?? Dio.new;

  final TokenStorage _tokenStorage;
  final String _baseUrl;

  /// Cách dựng Dio cho lời gọi làm mới và lần thử lại. Tách ra thành tham số
  /// để test có thể tiêm adapter giả; mặc định là `Dio.new`.
  final Dio Function(BaseOptions) _dioFactory;

  /// Chỉ cho phép một lần làm mới tại một thời điểm. Nhiều request 401 cùng
  /// lúc (màn hình gọi song song vài API) sẽ cùng chờ một future, tránh việc
  /// mỗi request tự xoay token và làm hỏng chuỗi rotation của backend — refresh
  /// token là dùng một lần, gọi song song sẽ bị coi là tái sử dụng và thu hồi
  /// cả phiên.
  Future<bool>? _refreshing;

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
      // 401 ở nơi không làm mới được nghĩa là phiên thực sự đã mất.
      if (err.response?.statusCode == 401) {
        await _tokenStorage.clear();
      }
      handler.next(err);
      return;
    }

    final refreshed = await (_refreshing ??= _refresh());
    _refreshing = null;

    if (!refreshed) {
      await _tokenStorage.clear();
      handler.next(err);
      return;
    }

    try {
      handler.resolve(await _retry(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Gọi `POST /auth/refresh` bằng một Dio riêng, không gắn interceptor này,
  /// nếu không lỗi 401 của chính lời gọi làm mới sẽ lại kích hoạt làm mới.
  Future<bool> _refresh() async {
    final refreshToken = await _tokenStorage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response =
          await _dioFactory(
            BaseOptions(baseUrl: _baseUrl, contentType: 'application/json'),
          ).post<Map<String, dynamic>>(
            ApiEndpoints.refreshToken,
            data: {
              'refresh_token': refreshToken,
              'device_id': await _tokenStorage.getOrCreateDeviceId(),
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
      if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
        return false;
      }

      await _tokenStorage.saveTokens(accessToken: access, refreshToken: refresh);
      return true;
    } on DioException {
      return false;
    }
  }

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
