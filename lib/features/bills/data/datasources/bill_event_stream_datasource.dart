import 'dart:async';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/session_refresher.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/realtime/sse_frame.dart';
import '../../../../core/realtime/sse_transport.dart';

/// Một frame SSE của bill. Giữ tên riêng vì tầng bill đã dùng nó ở nhiều nơi;
/// nội dung là [SseFrame] của core.
typedef BillSseFrame = SseFrame;

/// Client SSE cho `GET /bills/{id}/events` (đường legacy).
///
/// Dùng chung [SseTransport] với stream người dùng, xem ghi chú ở
/// `GroupEventStreamDataSource` về lý do không dùng `ResponseType.stream`.
@lazySingleton
class BillEventStreamDataSource {
  BillEventStreamDataSource(
    Dio dio,
    TokenStorage tokens,
    SessionRefresher refresher,
  ) : _transport = SseTransport(dio, tokens, refresher);

  final SseTransport _transport;

  /// Theo dõi sự kiện realtime của một hóa đơn (trạng thái job OCR, snapshot).
  Stream<BillSseFrame> stream(
    String billId, {
    required String groupId,
    CancelToken? cancelToken,
  }) {
    return _transport.open(
      ApiEndpoints.billEvents(billId),
      queryParameters: {'group_id': groupId},
      cancelToken: cancelToken,
    );
  }
}

/// Giữ tên cũ cho các test/parse đã dùng: parser nay nằm ở core.
Stream<BillSseFrame> parseBillSseLines(Stream<String> lines) =>
    parseSseLines(lines);
