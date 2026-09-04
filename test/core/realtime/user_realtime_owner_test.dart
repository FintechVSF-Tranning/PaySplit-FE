import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/network/session_events.dart';
import 'package:paysplit/core/network/session_refresher.dart';
import 'package:paysplit/core/network/token_storage.dart';
import 'package:paysplit/core/realtime/realtime_interest.dart';
import 'package:paysplit/core/realtime/realtime_interest_registry.dart';
import 'package:paysplit/core/realtime/realtime_ports.dart';
import 'package:paysplit/core/realtime/realtime_transport_mode.dart';
import 'package:paysplit/core/realtime/sse_frame.dart';
import 'package:paysplit/core/realtime/user_realtime_owner.dart';

/// TokenStorage trong bộ nhớ, không chạm tới FlutterSecureStorage.
class _FakeTokenStorage implements TokenStorage {
  String? access = 'access-1';
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

/// Nguồn stream cho owner trong test. `opened` đếm số lần kết nối, đủ để kiểm
/// tra thời điểm thử lại mà không phải bắt Timer.
abstract class _StreamSource {
  int get opened;

  Stream<SseFrame> open({CancelToken? cancelToken});
}

/// Mỗi lần owner kết nối lại sẽ lấy kịch bản tiếp theo.
class _FakeStreamSource implements _StreamSource {
  _FakeStreamSource(this._scripts);

  final List<StreamController<SseFrame>> _scripts;

  @override
  int opened = 0;

  @override
  Stream<SseFrame> open({CancelToken? cancelToken}) {
    final index = opened++;
    if (index >= _scripts.length) {
      return const Stream<SseFrame>.empty();
    }
    return _scripts[index].stream;
  }
}

DioException _httpError(
  int status, {
  Map<String, List<String>> headers = const {},
}) {
  return DioException(
    requestOptions: RequestOptions(path: '/users/me/events'),
    response: Response<dynamic>(
      requestOptions: RequestOptions(path: '/users/me/events'),
      statusCode: status,
      headers: Headers.fromMap(headers),
    ),
    type: DioExceptionType.badResponse,
  );
}

({
  ProviderContainer container,
  UserRealtimeOwner owner,
  RealtimeInterestRegistry registry,
  _FakeTokenStorage tokens,
  SessionEvents events,
})
_harness({
  required List<StreamController<SseFrame>> scripts,
  _StreamSource? source,
}) {
  final tokens = _FakeTokenStorage();
  final events = SessionEvents();
  final built = source ?? _FakeStreamSource(scripts);
  final container = ProviderContainer(
    overrides: [
      realtimeSignedInProvider.overrideWithValue(true),
      realtimeSessionEventsProvider.overrideWithValue(events),
      realtimeSessionRefresherProvider.overrideWithValue(
        SessionRefresher(tokens, events, baseUrlOverride: 'http://test'),
      ),
      userEventStreamOpenerProvider.overrideWithValue(built.open),
    ],
  );
  addTearDown(container.dispose);
  container.read(userRealtimeOwnerProvider);
  return (
    container: container,
    owner: container.read(userRealtimeOwnerProvider.notifier),
    registry: container.read(realtimeInterestRegistryProvider),
    tokens: tokens,
    events: events,
  );
}

const _readyFrame = SseFrame(
  event: 'ready',
  data: {'stream_id': 's1', 'timestamp': '2026-09-03T00:00:00Z'},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => RealtimeTransportMode.instance.setLegacyFallback(false));

  test('ready refetches every mounted interest and reports live', () async {
    // covers: AC-17, AC-18
    final script = StreamController<SseFrame>.broadcast();
    final h = _harness(scripts: [script]);
    var homeHits = 0;
    h.registry.register(
      RealtimeInterest(
        key: RealtimeInterestKey.homeGroups(),
        refresh: () async => homeHits++,
      ),
    );

    h.owner.handleLifecycle(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    script.add(_readyFrame);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(homeHits, 1);
    expect(
      h.container.read(userRealtimeOwnerProvider).transport,
      RealtimeTransport.live,
    );
  });

  test(
    'an event naming one group patches that row instead of the page',
    () async {
      // covers: AC-18
      final script = StreamController<SseFrame>.broadcast();
      final h = _harness(scripts: [script]);
      var fullRefreshes = 0;
      final patched = <String>[];
      h.registry.register(
        RealtimeInterest(
          key: RealtimeInterestKey.groupsIndex(),
          refresh: () async => fullRefreshes++,
          patchGroup: (groupId) async => patched.add(groupId),
        ),
      );

      h.owner.handleLifecycle(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      script.add(
        const SseFrame(
          event: 'invalidate',
          data: {
            'scope': 'bill',
            'group_id': 'g7',
            'resource_id': 'b1',
            'type': 'bill.deleted',
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(patched, ['g7']);
      expect(
        fullRefreshes,
        0,
        reason: 'tải lại cả trang sẽ không chạm tới dòng người dùng đang nhìn',
      );
    },
  );

  test('ready still refreshes the whole surface, never a single row', () async {
    // covers: AC-18
    final script = StreamController<SseFrame>.broadcast();
    final h = _harness(scripts: [script]);
    var fullRefreshes = 0;
    final patched = <String>[];
    h.registry.register(
      RealtimeInterest(
        key: RealtimeInterestKey.groupsIndex(),
        refresh: () async => fullRefreshes++,
        patchGroup: (groupId) async => patched.add(groupId),
      ),
    );

    h.owner.handleLifecycle(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    script.add(_readyFrame);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // Sau khi nối lại, khoảng trống sự kiện có thể rộng bằng bất kỳ thứ gì: chỉ
    // đọc lại toàn bộ mới hàn được, vá lẻ thì không.
    expect(fullRefreshes, 1);
    expect(patched, isEmpty);
  });

  test('two groups changing do not collapse into one patch', () async {
    // covers: AC-18
    final script = StreamController<SseFrame>.broadcast();
    final h = _harness(scripts: [script]);
    final patched = <String>[];
    h.registry.register(
      RealtimeInterest(
        key: RealtimeInterestKey.groupsIndex(),
        refresh: () async {},
        patchGroup: (groupId) async => patched.add(groupId),
      ),
    );

    h.owner.handleLifecycle(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    for (final groupId in ['g1', 'g2']) {
      script.add(
        SseFrame(
          event: 'invalidate',
          data: {'scope': 'bill', 'group_id': groupId, 'type': 'bill.deleted'},
        ),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));

    expect(patched..sort(), ['g1', 'g2']);
  });

  test('a surface without patchGroup is refreshed once per event', () async {
    // covers: AC-18
    // Gắn group_id cho một surface không vá lẻ được sẽ tạo ra hai đích riêng và
    // kéo theo hai lượt làm mới y hệt nhau.
    final script = StreamController<SseFrame>.broadcast();
    final h = _harness(scripts: [script]);
    var refreshes = 0;
    h.registry.register(
      RealtimeInterest(
        key: RealtimeInterestKey.homeGroups(),
        refresh: () async => refreshes++,
      ),
    );

    h.owner.handleLifecycle(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    for (final groupId in ['g1', 'g2']) {
      script.add(
        SseFrame(
          event: 'invalidate',
          data: {'scope': 'bill', 'group_id': groupId, 'type': 'bill.deleted'},
        ),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));

    expect(refreshes, 1);
  });

  test('a failed refetch stays dirty and is retried', () async {
    // covers: AC-18
    final script = StreamController<SseFrame>.broadcast();
    final h = _harness(scripts: [script]);
    var attempts = 0;
    h.registry.register(
      RealtimeInterest(
        key: RealtimeInterestKey.homeGroups(),
        refresh: () async {
          attempts++;
          if (attempts == 1) throw Exception('transient REST failure');
        },
      ),
    );

    h.owner.handleLifecycle(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    script.add(_readyFrame);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Lần đầu hỏng: chưa được coi là live, và invalidation vẫn còn.
    expect(attempts, 1);
    expect(
      h.container.read(userRealtimeOwnerProvider).transport,
      RealtimeTransport.resyncing,
    );

    // Backoff nấc đầu là 1 giây (jitter 0.7–1.3).
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    expect(attempts, 2, reason: 'invalidation bị mất thay vì được thử lại');
  });

  test('an invalidation arriving during a refresh is not swallowed', () async {
    // covers: AC-18
    final script = StreamController<SseFrame>.broadcast();
    final h = _harness(scripts: [script]);
    var hits = 0;
    final firstRefreshStarted = Completer<void>();
    final releaseFirstRefresh = Completer<void>();
    h.registry.register(
      RealtimeInterest(
        key: RealtimeInterestKey.homeGroups(),
        refresh: () async {
          hits++;
          if (hits == 1) {
            firstRefreshStarted.complete();
            await releaseFirstRefresh.future;
          }
        },
      ),
    );

    h.owner.handleLifecycle(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    script.add(_readyFrame);
    await firstRefreshStarted.future;

    // Sự kiện tới khi lần làm mới đầu vẫn đang chạy: dữ liệu nó mang về đã cũ.
    script.add(
      const SseFrame(
        event: 'invalidate',
        data: {
          'scope': 'home',
          'group_id': 'g1',
          'type': 'home.balance_changed',
        },
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 400));
    releaseFirstRefresh.complete();
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(hits, greaterThanOrEqualTo(2));
  });

  test('overflow falls back to refetching everything mounted', () async {
    // covers: AC-18
    final script = StreamController<SseFrame>.broadcast();
    final h = _harness(scripts: [script]);
    // Nhiều màn hình đang mở, mỗi màn một interest riêng: đúng hình dạng làm
    // tràn bộ đếm invalidation.
    for (var i = 0; i < 300; i++) {
      h.registry.register(
        RealtimeInterest(
          key: RealtimeInterestKey.groupActivities('g$i'),
          refresh: () async {},
        ),
      );
    }
    var debtHits = 0;
    h.registry.register(
      RealtimeInterest(
        key: RealtimeInterestKey.groupDebts('g-unrelated'),
        refresh: () async => debtHits++,
      ),
    );

    h.owner.handleLifecycle(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    for (var i = 0; i < 300; i++) {
      script.add(
        SseFrame(
          event: 'invalidate',
          data: {
            'scope': 'group',
            'group_id': 'g$i',
            'type': 'group.activity_changed',
          },
        ),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 700));

    expect(
      debtHits,
      greaterThanOrEqualTo(1),
      reason: 'tràn phải chuyển sang refetch toàn bộ interest đang mounted',
    );
  });

  test('a 401 that survives the transport retry ends the session', () async {
    // covers: AC-23
    final h = _harness(scripts: [], source: _Erroring(_httpError(401)));

    var expired = 0;
    final sub = h.events.onExpired.listen((_) => expired++);
    addTearDown(sub.cancel);

    h.owner.handleLifecycle(AppLifecycleState.resumed);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(h.tokens.cleared, isTrue, reason: 'token phải bị xóa');
    expect(expired, 1, reason: 'UI phải được báo mất phiên');
    expect(
      h.container.read(userRealtimeOwnerProvider).transport,
      RealtimeTransport.signedOut,
    );
  });

  test('a 404 before ready switches the whole app to legacy transport', () async {
    // covers: AC-23
    final h = _harness(scripts: [], source: _Erroring(_httpError(404)));

    h.owner.handleLifecycle(AppLifecycleState.resumed);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(h.container.read(userRealtimeOwnerProvider).legacyFallback, isTrue);
    expect(
      RealtimeTransportMode.instance.useLegacy,
      isTrue,
      reason:
          'người chờ OCR phải thấy chế độ hiệu lực, không phải biến môi trường',
    );
  });

  test('Retry-After is a floor, never jittered below', () async {
    // covers: AC-23
    final source = _Erroring(
      _httpError(
        429,
        headers: {
          'retry-after': ['2'],
        },
      ),
    );
    final h = _harness(scripts: [], source: source);

    h.owner.handleLifecycle(AppLifecycleState.resumed);
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    expect(
      source.opened,
      1,
      reason: 'thử lại trước cửa sổ server yêu cầu sẽ ăn thêm một 429',
    );
  });
}

/// Nguồn stream luôn lỗi ngay khi mở.
class _Erroring implements _StreamSource {
  _Erroring(this.error);

  final Object error;

  @override
  int opened = 0;

  @override
  Stream<SseFrame> open({CancelToken? cancelToken}) {
    opened++;
    return Stream<SseFrame>.error(error);
  }
}
