import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';

/// Một frame đã tách khỏi luồng `text/event-stream`.
class SseFrame {
  const SseFrame({required this.event, required this.data});

  final String event;
  final Map<String, dynamic> data;
}

/// Client SSE cho `GET /groups/{id}/events`.
///
/// Dùng Dio thay vì một package SSE riêng vì request phải đi qua
/// `AuthInterceptor` sẵn có: nó gắn Bearer token và làm mới token khi 401, đúng
/// như mọi request khác. Package ngoài sẽ mở một HTTP client riêng nằm ngoài
/// chuỗi interceptor đó.
@lazySingleton
class GroupEventStreamDataSource {
  GroupEventStreamDataSource(this._dio);

  final Dio _dio;

  /// Mở stream sự kiện của một nhóm, bắt đầu từ [since].
  ///
  /// Stream kết thúc bình thường khi server đóng kết nối (chạm tuổi thọ tối đa,
  /// nhóm bị giải tán, hoặc caller không còn là thành viên) và ném lỗi khi mạng
  /// đứt. Việc kết nối lại thuộc về tầng gọi, vì chỉ nó biết version hiện tại.
  Stream<SseFrame> stream(String groupId, {required int since, CancelToken? cancelToken}) async* {
    final response = await _dio.get<ResponseBody>(
      ApiEndpoints.groupEvents(groupId),
      queryParameters: {'since': since},
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
        // Kết nối sống lâu: timeout theo nhịp nhận của Dio sẽ cắt ngang stream
        // giữa hai sự kiện. Heartbeat 15 giây của server mới là cơ chế phát
        // hiện kết nối chết.
        receiveTimeout: Duration.zero,
      ),
    );

    yield* parseSseLines(
      utf8.decoder
          .bind(response.data!.stream.map((chunk) => chunk.toList()))
          .transform(const LineSplitter()),
    );
  }
}

/// Tách các dòng `text/event-stream` thành frame.
///
/// Tách khỏi [GroupEventStreamDataSource] để test được mà không cần dựng Dio —
/// đây là chỗ dễ sai nhất của cả client: một frame bị ghép nhầm sẽ làm client
/// hiểu sai version và tự đẩy mình vào vòng catch-up.
Stream<SseFrame> parseSseLines(Stream<String> lines) async* {
  var eventName = 'message';
  final data = StringBuffer();

  await for (final line in lines) {
    if (line.isEmpty) {
      // Dòng trống kết thúc một frame.
      if (data.isNotEmpty) {
        final decoded = jsonDecode(data.toString());
        if (decoded is Map<String, dynamic>) {
          yield SseFrame(event: eventName, data: decoded);
        }
      }
      eventName = 'message';
      data.clear();
      continue;
    }
    if (line.startsWith(':')) continue; // comment giữ kết nối
    final separator = line.indexOf(':');
    if (separator < 0) continue;
    final field = line.substring(0, separator);
    final value = line.substring(separator + 1).trimLeft();
    switch (field) {
      case 'event':
        eventName = value;
      case 'data':
        data.write(value);
      // 'id' bỏ qua: version đã nằm trong payload nên không phải đọc hai nguồn.
    }
  }
}
