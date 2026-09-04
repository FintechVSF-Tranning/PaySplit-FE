import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/network/session_events.dart';
import 'package:paysplit/core/network/session_refresher.dart';
import 'package:paysplit/core/network/token_storage.dart';
import 'package:paysplit/core/realtime/sse_transport.dart';

class _FakeTokenStorage implements TokenStorage {
  String? access = 'expired';
  String? refresh = 'refresh-1';
  bool cleared = false;

  @override
  Future<String?> get accessToken async => access;

  @override
  Future<String?> get refreshToken async => refresh;

  @override
  Future<String> getOrCreateDeviceId() async => 'device-1';

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    cleared = true;
    access = null;
    refresh = null;
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
  test('every stream carries Accept and X-App-Version', () async {
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
    expect(request.queryParameters['since'], 0);
  });

  test(
    'a stream 401 refreshes once and reopens with the rotated token',
    () async {
      // covers: AC-23
      var streamAttempts = 0;
      var refreshCalls = 0;
      final adapter = _RecordingAdapter((options) {
        if (options.path == '/auth/refresh') {
          refreshCalls++;
          return _status(
            200,
            body:
                '{"data":{"access_token":"fresh","refresh_token":"refresh-2"}}',
          );
        }
        streamAttempts++;
        if (options.headers['Authorization'] == 'Bearer fresh') {
          return _sseBody(_oneReadyFrame);
        }
        return _status(401);
      });
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter;
      final tokens = _FakeTokenStorage();
      final refresher = SessionRefresher(
        tokens,
        SessionEvents(),
        dioFactory: (o) => Dio(o)..httpClientAdapter = adapter,
        baseUrlOverride: 'http://test',
      );

      final frames = await SseTransport(
        dio,
        tokens,
        refresher,
      ).open('/users/me/events').toList();

      expect(frames.single.event, 'ready');
      expect(refreshCalls, 1);
      expect(
        streamAttempts,
        2,
        reason: 'mở lại đúng một lần, không lặp vô hạn',
      );
      expect(tokens.cleared, isFalse);
    },
  );

  test('a stream 401 whose refresh fails clears the session', () async {
    // covers: AC-23
    final events = SessionEvents();
    var expired = 0;
    final sub = events.onExpired.listen((_) => expired++);
    addTearDown(sub.cancel);

    final adapter = _RecordingAdapter((options) {
      if (options.path == '/auth/refresh') return _status(401);
      return _status(401);
    });
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = adapter;
    final tokens = _FakeTokenStorage();
    final refresher = SessionRefresher(
      tokens,
      events,
      dioFactory: (o) => Dio(o)..httpClientAdapter = adapter,
      baseUrlOverride: 'http://test',
    );

    await expectLater(
      SseTransport(dio, tokens, refresher).open('/users/me/events').toList(),
      throwsA(isA<DioException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(tokens.cleared, isTrue);
    expect(expired, 1);
  });

  test('concurrent refreshes share one rotation', () async {
    // covers: AC-23
    // Refresh token dùng một lần: hai lần xoay song song bị backend coi là tái
    // sử dụng và thu hồi cả họ token.
    var refreshCalls = 0;
    final adapter = _RecordingAdapter((options) {
      if (options.path == '/auth/refresh') {
        refreshCalls++;
        return _status(
          200,
          body: '{"data":{"access_token":"fresh","refresh_token":"refresh-2"}}',
        );
      }
      return _status(401);
    });
    final refresher = SessionRefresher(
      _FakeTokenStorage(),
      SessionEvents(),
      dioFactory: (o) => Dio(o)..httpClientAdapter = adapter,
      baseUrlOverride: 'http://test',
    );

    final results = await Future.wait([
      refresher.refresh(),
      refresher.refresh(),
    ]);

    expect(results, [true, true]);
    expect(refreshCalls, 1);
  });
}
