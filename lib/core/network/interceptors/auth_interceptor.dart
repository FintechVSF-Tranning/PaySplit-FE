import 'package:dio/dio.dart';

import '../token_storage.dart';

/// Attaches the bearer token to every request and clears stale tokens on a
/// 401 response. Token *refresh* is intentionally not handled here — retry
/// logic that re-issues the original request belongs in the auth
/// repository, not in a generic interceptor, to keep this class simple and
/// side-effect free.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

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
    if (err.response?.statusCode == 401) {
      await _tokenStorage.clear();
    }
    handler.next(err);
  }
}
