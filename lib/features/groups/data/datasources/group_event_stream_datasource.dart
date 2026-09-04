import 'dart:async';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/session_refresher.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/realtime/sse_frame.dart';
import '../../../../core/realtime/sse_transport.dart';

export '../../../../core/realtime/sse_frame.dart' show SseFrame, parseSseLines;

/// Client SSE cho `GET /groups/{id}/events` (đường legacy).
///
/// Đi qua [SseTransport] chung với stream người dùng: cùng một byte source có
/// điều kiện theo nền tảng và cùng một bộ header. Trên web, adapter XHR của Dio
/// đệm toàn bộ body nên đường legacy sẽ không giao được frame nào — mà đây đúng
/// là đường lui khi stream người dùng trả 404/501.
@lazySingleton
class GroupEventStreamDataSource {
  GroupEventStreamDataSource(
    Dio dio,
    TokenStorage tokens,
    SessionRefresher refresher,
  ) : _transport = SseTransport(dio, tokens, refresher);

  final SseTransport _transport;

  /// Mở stream sự kiện của một nhóm, bắt đầu từ [since].
  ///
  /// Stream kết thúc bình thường khi server đóng kết nối (chạm tuổi thọ tối đa,
  /// nhóm bị giải tán, hoặc caller không còn là thành viên) và ném lỗi khi mạng
  /// đứt. Việc kết nối lại thuộc về tầng gọi, vì chỉ nó biết version hiện tại.
  Stream<SseFrame> stream(
    String groupId, {
    required int since,
    CancelToken? cancelToken,
  }) {
    return _transport.open(
      ApiEndpoints.groupEvents(groupId),
      queryParameters: {'since': since},
      cancelToken: cancelToken,
    );
  }
}
