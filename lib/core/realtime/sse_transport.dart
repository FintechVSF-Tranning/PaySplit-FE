import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../network/session_refresher.dart';
import '../network/token_storage.dart';
import 'sse_byte_source.dart';
import 'sse_frame.dart';

/// Vận chuyển SSE dùng chung cho stream người dùng và cả hai stream legacy.
///
/// Cả ba đi qua đúng một đường: trên web đó là `fetch` đọc thân phản hồi theo
/// từng chunk, vì adapter XHR của Dio đệm toàn bộ body và không giao gì cho tới
/// khi kết nối đóng — nghĩa là một stream sống lâu không bao giờ giao frame nào.
/// Nếu legacy đi đường khác thì đường lui 404/501 không hoạt động được trên web.
class SseTransport {
  const SseTransport(this._dio, this._tokens, [this._refresher]);

  final Dio _dio;
  final TokenStorage _tokens;

  /// Xoay vòng token khi stream nhận 401. Bắt buộc phải là instance dùng chung
  /// với `AuthInterceptor`, xem [SessionRefresher].
  final SessionRefresher? _refresher;

  /// Phiên bản app gắn vào mọi stream. Telemetry rollout phân loại lưu lượng
  /// theo header này, nên thiếu nó ở đường legacy sẽ làm cả nhóm fallback bị
  /// đếm là `unknown`.
  static Future<String> appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return 'unknown';
    }
  }

  static Future<Map<String, String>> headers({String? accessToken}) async {
    return {
      'Accept': 'text/event-stream',
      'X-App-Version': await appVersion(),
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
  }

  /// Mở stream, làm mới token đúng một lần nếu server trả 401.
  ///
  /// Byte source coi mọi status dưới 500 là "thành công" và ném DioException
  /// của riêng nó, nên 401 của stream không bao giờ chạm tới `AuthInterceptor`.
  /// Không xử lý ở đây thì đúng lúc access token hết hạn, kết nối realtime duy
  /// nhất của app chết và không bao giờ quay lại.
  Stream<SseFrame> open(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async* {
    var refreshed = false;
    while (true) {
      var delivered = false;
      try {
        // `await for` chứ không phải `yield*`: lỗi của một stream được `yield*`
        // đi thẳng ra controller bên ngoài và không bao giờ vào được try/catch
        // này — nghĩa là nhánh 401 dưới đây sẽ không bao giờ chạy.
        await for (final frame in _openOnce(
          path,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
        )) {
          delivered = true;
          yield frame;
        }
        return;
      } on DioException catch (error) {
        final refresher = _refresher;
        if (refreshed ||
            delivered ||
            error.response?.statusCode != 401 ||
            refresher == null ||
            (cancelToken?.isCancelled ?? false)) {
          rethrow;
        }
        // Đúng một lần: nếu token mới cũng bị từ chối, phiên hỏng thật và lần
        // ném thứ hai đi thẳng lên tầng gọi.
        if (!await refresher.refresh()) {
          await refresher.endSession();
          rethrow;
        }
        refreshed = true;
      }
    }
  }

  Stream<SseFrame> _openOnce(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async* {
    final built = await headers(accessToken: await _tokens.accessToken);
    yield* parseSseLines(
      utf8.decoder
          .bind(
            openSseByteStream(
              dio: _dio,
              path: path,
              queryParameters: queryParameters,
              headers: built,
              cancelToken: cancelToken,
            ),
          )
          .transform(const LineSplitter()),
    );
  }
}
