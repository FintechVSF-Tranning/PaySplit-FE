import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/network/session_events.dart';
import 'package:paysplit/core/network/session_terminator.dart';
import 'package:paysplit/core/network/token_storage.dart';

/// SessionTerminator là nơi duy nhất kết thúc phiên phía client. Nó thay cho
/// `SessionRefresher` cũ: không còn gì để xoay vòng, chỉ còn việc xóa credential
/// và báo lên UI đúng một lần.
///
/// Điều đáng kiểm nhất là tính idempotent khi gọi đồng thời. Một request REST
/// trả 401 cùng lúc stream SSE báo `session_ended` là chuyện thường, và hai lần
/// báo sẽ đẩy người dùng qua màn hình đăng nhập hai lần.
///
/// covers: AC-19 (không còn interceptor làm mới, một credential duy nhất),
/// AC-3 (force logout từ tầng realtime), AC-13 (kết thúc phiên là idempotent).

class _FakeTokenStorage implements TokenStorage {
  _FakeTokenStorage({this.session});

  String? session;
  int clearCalls = 0;

  /// Cho phép chèn độ trễ vào lần đọc, để dựng đúng cửa sổ tranh chấp giữa hai
  /// lời gọi đồng thời.
  Completer<void>? gate;

  @override
  Future<String?> get sessionId async {
    if (gate != null) await gate!.future;
    return session;
  }

  @override
  Future<String> getOrCreateDeviceId() async => 'device-1';

  @override
  Future<void> saveSession(String sessionId) async {
    session = sessionId;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    session = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeTokenStorage tokens;
  late SessionEvents events;
  late SessionTerminator terminator;
  late List<void> expired;
  late StreamSubscription<void> sub;

  setUp(() {
    tokens = _FakeTokenStorage(session: 'credential-dang-song');
    events = SessionEvents();
    terminator = SessionTerminator(tokens, events);
    expired = [];
    sub = events.onExpired.listen(expired.add);
  });

  tearDown(() async {
    await sub.cancel();
    events.dispose();
  });

  test('kết thúc phiên đang sống thì xóa credential và báo lên UI', () async {
    await terminator.endSession();
    await pumpEventQueue();

    expect(tokens.session, isNull);
    expect(tokens.clearCalls, 1);
    expect(expired, hasLength(1));
  });

  test('không có phiên thì vẫn xóa nhưng không báo', () async {
    tokens.session = null;

    await terminator.endSession();
    await pumpEventQueue();

    expect(tokens.clearCalls, 1);
    expect(
      expired,
      isEmpty,
      reason:
          'báo mất phiên khi vốn chưa đăng nhập sẽ đá người dùng ra khỏi màn hình đăng nhập',
    );
  });

  test('credential rỗng được coi như không có phiên', () async {
    tokens.session = '';

    await terminator.endSession();
    await pumpEventQueue();

    expect(expired, isEmpty);
  });

  test('nhiều lời gọi đồng thời chỉ báo mất phiên một lần', () async {
    // Chặn lần đọc đầu để cả ba lời gọi cùng nằm trong một cửa sổ.
    tokens.gate = Completer<void>();

    final calls = Future.wait([
      terminator.endSession(),
      terminator.endSession(),
      terminator.endSession(),
    ]);
    tokens.gate!.complete();
    await calls;
    await pumpEventQueue();

    expect(
      tokens.clearCalls,
      1,
      reason: 'ba lời gọi song song chỉ nên dọn một lần',
    );
    expect(
      expired,
      hasLength(1),
      reason:
          'REST 401 và SSE session_ended thường xảy ra cùng lúc; hai lần báo đẩy UI điều hướng hai lần',
    );
  });

  test('gọi lại sau khi đã kết thúc thì không báo lần hai', () async {
    await terminator.endSession();
    await pumpEventQueue();
    expect(expired, hasLength(1));

    await terminator.endSession();
    await pumpEventQueue();

    expect(
      expired,
      hasLength(1),
      reason: 'phiên đã chết rồi thì không còn gì để báo mất',
    );
    expect(
      tokens.clearCalls,
      2,
      reason: 'clear vẫn idempotent, chỉ việc báo mới bị chặn',
    );
  });

  test('đăng nhập lại rồi kết thúc lần nữa thì báo lại bình thường', () async {
    await terminator.endSession();
    await pumpEventQueue();

    await tokens.saveSession('credential-moi');
    await terminator.endSession();
    await pumpEventQueue();

    expect(
      expired,
      hasLength(2),
      reason:
          'cờ chống trùng phải được thả sau mỗi lượt, nếu không lần đăng xuất sau im lặng',
    );
  });

  test('lời gọi đang chạy hoàn tất trước khi lượt mới bắt đầu', () async {
    tokens.gate = Completer<void>();
    final first = terminator.endSession();
    final second = terminator.endSession();

    expect(
      identical(first, second),
      isTrue,
      reason: 'lượt thứ hai phải bám vào lượt đang chạy',
    );

    tokens.gate!.complete();
    await first;
    await second;
  });
}
