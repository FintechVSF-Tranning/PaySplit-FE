import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/network/token_storage.dart';
import 'package:paysplit/core/realtime/sse_transport.dart';

class _FakeTokenStorage implements TokenStorage {
  String? session = 'sess-abc';

  @override
  Future<String?> get sessionId async => session;

  @override
  Future<String> getOrCreateDeviceId() async => 'device-1';

  @override
  Future<void> saveSession(String sessionId) async {
    session = sessionId;
  }

  @override
  Future<void> clear() async {
    session = null;
  }
}

/// Adapter giả ghi lại mọi request và trả kết quả theo kịch bản.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.responder);

  final ResponseBody Function(RequestOptions options) responder;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return responder(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _sseBody(String payload) {
  return ResponseBody.fromString(
    payload,
    200,
    headers: {
      Headers.contentTypeHeader: ['text/event-stream'],
    },
  );
}

ResponseBody _status(int code, {String body = '{}'}) {
  return ResponseBody.fromString(
    body,
    code,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

const _oneReadyFrame =
    'event: ready\ndata: {"stream_id":"s1","timestamp":"2026-09-03T00:00:00Z"}\n\n';

void main() {
  test(
    'every stream carries Accept, X-App-Version and the Bearer credential',
    () async {
      // covers: AC-23
      final adapter = _RecordingAdapter((_) => _sseBody(_oneReadyFrame));
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter;

      await SseTransport(
        dio,
        _FakeTokenStorage(),
      ).open('/groups/g1/events', queryParameters: {'since': 0}).toList();

      final request = adapter.requests.single;
      expect(request.headers['Accept'], 'text/event-stream');
      expect(
        request.headers['X-App-Version'],
        isNotNull,
        reason: 'thiếu header này thì telemetry rollout đếm legacy là unknown',
      );
      expect(request.headers['Authorization'], 'Bearer sess-abc');
      expect(request.queryParameters['since'], 0);
    },
  );

  test('không có session thì không gắn header Authorization', () async {
    final adapter = _RecordingAdapter((_) => _sseBody(_oneReadyFrame));
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = adapter;
    final tokens = _FakeTokenStorage()..session = null;

    await SseTransport(dio, tokens).open('/users/me/events').toList();

    expect(adapter.requests.single.headers['Authorization'], isNull);
  });

  test('a stream 401 is surfaced as-is — session ID does not rotate, so there is '
      'nothing to refresh and no retry', () async {
    // covers: AC-23
    final adapter = _RecordingAdapter((options) => _status(401));
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = adapter;

    await expectLater(
      SseTransport(dio, _FakeTokenStorage()).open('/users/me/events').toList(),
      throwsA(isA<DioException>()),
    );
    expect(
      adapter.requests,
      hasLength(1),
      reason:
          'không có lần mở lại nào — quyết định kết thúc phiên thuộc về tầng gọi',
    );
  });

  test('parses frames delivered on the first attempt', () async {
    final adapter = _RecordingAdapter((_) => _sseBody(_oneReadyFrame));
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = adapter;

    final frames = await SseTransport(
      dio,
      _FakeTokenStorage(),
    ).open('/users/me/events').toList();

    expect(frames.single.event, 'ready');
  });
}
