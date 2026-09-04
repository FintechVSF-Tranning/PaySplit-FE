import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/injection.dart';
import '../network/session_events.dart';
import '../network/session_refresher.dart';
import '../network/token_storage.dart';
import 'sse_frame.dart';
import 'user_event_stream_datasource.dart';

/// Các cổng mà tầng realtime cần từ bên ngoài.
///
/// Khai báo ở `core` và được tầng app ghi đè (xem `bootstrap.dart`). Nhờ vậy
/// `core/realtime` không phải import tầng presentation hay data của bất kỳ
/// feature nào: hợp đồng vận chuyển dùng chung cho cả app không thể do một
/// adapter của một feature sở hữu. Đây cũng là chỗ test tiêm bản giả.

/// Người dùng đã đăng nhập hay chưa. Mặc định `false` (không kết nối); tầng app
/// ghi đè bằng trạng thái thật của feature auth.
final realtimeSignedInProvider = Provider<bool>((ref) => false);

final realtimeSessionEventsProvider = Provider<SessionEvents>((ref) {
  return getIt<SessionEvents>();
});

final realtimeSessionRefresherProvider = Provider<SessionRefresher>((ref) {
  return getIt<SessionRefresher>();
});

/// Mở stream sự kiện của phiên. Tách thành cổng để test dựng được owner mà
/// không cần Dio, secure storage hay mạng.
typedef UserEventStreamOpener =
    Stream<SseFrame> Function({CancelToken? cancelToken});

final userEventStreamOpenerProvider = Provider<UserEventStreamOpener>((ref) {
  final source = UserEventStreamDataSource(
    getIt<Dio>(),
    getIt<TokenStorage>(),
    ref.read(realtimeSessionRefresherProvider),
  );
  return ({CancelToken? cancelToken}) =>
      source.stream(cancelToken: cancelToken);
});
