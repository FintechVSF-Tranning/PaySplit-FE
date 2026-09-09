import 'package:dio/dio.dart';

import '../../constants/api_endpoints.dart';
import '../session_terminator.dart';
import '../token_storage.dart';

/// Gắn credential vào mọi request; khi gặp 401 thật sự thì kết thúc phiên.
///
/// Không còn cặp access/refresh token: session ID tự gia hạn phía server mỗi
/// request (TTL trượt trên Redis), nên không có gì để làm mới ở đây và không
/// còn vòng "401 → refresh → retry" — một request 401 nghĩa là phiên đã chết
/// thật (thu hồi, hết hạn tuyệt đối, hoặc bị đăng nhập nơi khác), không cứu
/// được bằng cách gọi lại.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage, {this.sessionTerminator});

  final TokenStorage _tokenStorage;

  /// Kết thúc phiên khi 401 là thật. Tham số tùy chọn để test tiêm bản giả.
  final SessionTerminator? sessionTerminator;

  /// 401 trên chính các endpoint xác thực (sai mật khẩu, OTP hỏng, credential
  /// không tồn tại lúc sign-out...) không phải là mất phiên: người dùng chưa
  /// đăng nhập, hoặc đang tự đăng xuất — đừng đá ai ra khỏi đâu cả.
  static const Set<String> _unauthenticatedPaths = {
    ApiEndpoints.login,
    ApiEndpoints.register,
    ApiEndpoints.forgotPassword,
    ApiEndpoints.resetPassword,
    ApiEndpoints.verifyEmail,
    ApiEndpoints.resendVerification,
    ApiEndpoints.signOut,
  };

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final sessionId = await _tokenStorage.sessionId;
    if (sessionId != null && sessionId.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $sessionId';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Chỉ đúng 401 mới là mất phiên. 503 SESSION_STORE_UNAVAILABLE nghĩa là kho
    // phiên tạm thời không truy cập được: credential VẪN CÒN GIÁ TRỊ, giữ nguyên
    // và để người dùng thử lại. Xóa nó ở đây sẽ biến một cú chớp vài chục giây
    // của Redis thành một lần đăng xuất vĩnh viễn của toàn bộ người dùng.
    final isRealSessionLoss =
        err.response?.statusCode == 401 &&
        !_unauthenticatedPaths.contains(err.requestOptions.path);
    if (isRealSessionLoss) {
      // Kết thúc đúng phiên đã chết, không phải phiên đang lưu. Một request chậm
      // của phiên cũ có thể trả 401 sau khi người dùng đã đăng nhập lại.
      await sessionTerminator?.endSession(
        expectedSessionId: _bearerOf(err.requestOptions),
      );
    }
    handler.next(err);
  }

  /// Credential mà chính request này đã gửi đi, lấy lại từ header của nó.
  static String? _bearerOf(RequestOptions options) {
    final header = options.headers['Authorization'];
    if (header is! String || !header.startsWith('Bearer ')) {
      return null;
    }
    final value = header.substring('Bearer '.length).trim();
    return value.isEmpty ? null : value;
  }
}
