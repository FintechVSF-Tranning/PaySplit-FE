import 'dart:async';

import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import '../network/token_storage.dart';
import 'sse_frame.dart';
import 'sse_transport.dart';

/// Client SSE cho `GET /users/me/events` — stream realtime duy nhất của phiên.
class UserEventStreamDataSource {
  UserEventStreamDataSource(Dio dio, TokenStorage tokens)
    : _transport = SseTransport(dio, tokens);

  final SseTransport _transport;

  static Future<String> appVersionHeader() => SseTransport.appVersion();

  Stream<SseFrame> stream({CancelToken? cancelToken}) {
    return _transport.open(ApiEndpoints.userEvents, cancelToken: cancelToken);
  }
}
