import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../network/token_storage.dart';
import 'sse_byte_source.dart';
import 'sse_frame.dart';

/// Vận chuyển SSE dùng chung cho stream người dùng và cả hai stream legacy.
///
/// Cả ba đi qua đúng một đường: trên web đó là `fetch` đọc thân phản hồi theo
/// từng chunk, vì adapter XHR của Dio đệm toàn bộ body và không giao gì cho tới
/// khi kết nối đóng — nghĩa là một stream sống lâu không bao giờ giao frame nào.
/// Nếu legacy đi đường khác thì đường lui 404/501 không hoạt động được trên web.
///
/// Không có gì để làm mới khi nhận 401 nữa: session ID không xoay vòng, nên
/// một 401 nghĩa là phiên đã chết thật (thu hồi, hết hạn, đăng nhập nơi khác).
/// Lỗi được ném thẳng ra ngoài; tầng gọi (`UserRealtimeOwner`) quyết định kết
/// thúc phiên, không thử mở lại.
class SseTransport {
  const SseTransport(this._dio, this._tokens);

  final Dio _dio;
  final TokenStorage _tokens;

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

  static Future<Map<String, String>> headers({String? sessionId}) async {
    return {
      'Accept': 'text/event-stream',
      'X-App-Version': await appVersion(),
      if (sessionId != null && sessionId.isNotEmpty)
        'Authorization': 'Bearer $sessionId',
    };
  }

  Stream<SseFrame> open(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async* {
    final built = await headers(sessionId: await _tokens.sessionId);
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
