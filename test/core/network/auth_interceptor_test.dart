import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/network/interceptors/auth_interceptor.dart';
import 'package:paysplit/core/network/session_events.dart';
import 'package:paysplit/core/network/session_terminator.dart';
import 'package:paysplit/core/network/token_storage.dart';

/// TokenStorage trong bộ nhớ, không chạm tới FlutterSecureStorage.
class _FakeTokenStorage implements TokenStorage {
  _FakeTokenStorage({this.session});

  String? session;
  bool cleared = false;

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
    cleared = true;
    session = null;
  }
}

/// Adapter giả: trả kết quả theo path, đồng thời đếm số lần mỗi path được gọi.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responder);

  final ResponseBody Function(RequestOptions options) responder;
  final Map<String, int> calls = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls[options.path] = (calls[options.path] ?? 0) + 1;
    return responder(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic> body, int status) =>
    ResponseBody.fromString(
      '{"error":"${body['error'] ?? ''}"}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  group('AuthInterceptor', () {
    test('gắn Authorization: Bearer <session_id> vào mọi request', () async {
      final storage = _FakeTokenStorage(session: 'sess-abc');
      String? seenAuth;
      final adapter = _FakeAdapter((options) {
        seenAuth = options.headers['Authorization'] as String?;
        return _json({}, 200);
      });

      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(AuthInterceptor(storage));

      await dio.get<dynamic>('/groups');

      expect(seenAuth, 'Bearer sess-abc');
    });

    test('không có session thì không gắn header', () async {
      final storage = _FakeTokenStorage();
      String? seenAuth;
      final adapter = _FakeAdapter((options) {
        seenAuth = options.headers['Authorization'] as String?;
        return _json({}, 200);
      });

      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(AuthInterceptor(storage));

      await dio.get<dynamic>('/groups');

      expect(seenAuth, isNull);
    });

    test('401 thật thì kết thúc phiên — không còn refresh để cứu', () async {
      // Session ID không xoay vòng: một 401 trên endpoint được bảo vệ nghĩa là
      // phiên đã chết thật (thu hồi, hết hạn, đăng nhập nơi khác), không phải
      // chuyện tạm thời có thể làm mới rồi thử lại.
      final storage = _FakeTokenStorage(session: 'sess-dead');
      final events = SessionEvents();
      addTearDown(events.dispose);
      final terminator = SessionTerminator(storage, events);
      final expired = <void>[];
      events.onExpired.listen(expired.add);

      final adapter = _FakeAdapter(
        (options) => _json({'error': 'unauthorized'}, 401),
      );
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          AuthInterceptor(storage, sessionTerminator: terminator),
        );

      await expectLater(
        dio.get<dynamic>('/groups'),
        throwsA(isA<DioException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(storage.cleared, isTrue);
      expect(
        expired,
        hasLength(1),
        reason: 'app phải được đưa về màn đăng nhập',
      );
    });

    test('nhiều request cùng chết chỉ báo mất phiên một lần', () async {
      final storage = _FakeTokenStorage(session: 'sess-dead');
      final events = SessionEvents();
      addTearDown(events.dispose);
      final terminator = SessionTerminator(storage, events);
      final expired = <void>[];
      events.onExpired.listen(expired.add);

      final adapter = _FakeAdapter(
        (options) => _json({'error': 'unauthorized'}, 401),
      );
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          AuthInterceptor(storage, sessionTerminator: terminator),
        );

      await Future.wait([
        dio
            .get<dynamic>('/groups')
            .catchError(
              (_) => Response<dynamic>(requestOptions: RequestOptions()),
            ),
        dio
            .get<dynamic>('/bills')
            .catchError(
              (_) => Response<dynamic>(requestOptions: RequestOptions()),
            ),
        dio
            .get<dynamic>('/notifications')
            .catchError(
              (_) => Response<dynamic>(requestOptions: RequestOptions()),
            ),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(expired, hasLength(1));
    });

    test('đăng nhập sai mật khẩu không bị coi là mất phiên', () async {
      // 401 ở /auth/sign-in nghĩa là sai mật khẩu, không phải phiên hỏng: không
      // được xóa session đang dùng, cũng không được đá ai ra.
      final storage = _FakeTokenStorage(session: 'sess-valid');
      final events = SessionEvents();
      addTearDown(events.dispose);
      final terminator = SessionTerminator(storage, events);
      final expired = <void>[];
      events.onExpired.listen(expired.add);

      final adapter = _FakeAdapter(
        (options) => _json({'error': 'invalid'}, 401),
      );
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          AuthInterceptor(storage, sessionTerminator: terminator),
        );

      await expectLater(
        dio.post<dynamic>('/auth/sign-in', data: {'email': 'a@b.c'}),
        throwsA(isA<DioException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(storage.cleared, isFalse);
      expect(expired, isEmpty);
    });

    test('sign-out không bao giờ được coi là mất phiên', () async {
      // Sign-out cố ý không xác thực và luôn 204 phía backend, nhưng test này
      // ghim phòng khi client gọi nhầm sau khi credential đã chết cục bộ: một
      // 401 ở đây (ví dụ do proxy) không được kích hoạt endSession lần hai.
      final storage = _FakeTokenStorage();
      final events = SessionEvents();
      addTearDown(events.dispose);
      final terminator = SessionTerminator(storage, events);
      final expired = <void>[];
      events.onExpired.listen(expired.add);

      final adapter = _FakeAdapter(
        (options) => _json({'error': 'unauthorized'}, 401),
      );
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          AuthInterceptor(storage, sessionTerminator: terminator),
        );

      await expectLater(
        dio.post<dynamic>('/auth/sign-out'),
        throwsA(isA<DioException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(expired, isEmpty);
    });

    test('không có sessionTerminator thì vẫn không crash', () async {
      final storage = _FakeTokenStorage(session: 'sess-dead');
      final adapter = _FakeAdapter(
        (options) => _json({'error': 'unauthorized'}, 401),
      );
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(AuthInterceptor(storage));

      await expectLater(
        dio.get<dynamic>('/groups'),
        throwsA(isA<DioException>()),
      );
    });

    // Hồi quy: kho phiên hỏng KHÔNG phải mất phiên.
    //
    // Backend nay trả 503 SESSION_STORE_UNAVAILABLE khi Redis không truy cập
    // được, tách hẳn khỏi 401. Nếu app xóa credential ở đây thì một cú chớp vài
    // chục giây của Redis đăng xuất vĩnh viễn mọi người dùng, dù không phiên nào
    // bị thu hồi.
    test('503 kho phiên hỏng thì giữ nguyên credential', () async {
      final storage = _FakeTokenStorage(session: 'sess-con-song');
      final events = SessionEvents();
      addTearDown(events.dispose);
      final terminator = SessionTerminator(storage, events);
      final expired = <void>[];
      events.onExpired.listen(expired.add);

      final adapter = _FakeAdapter(
        (options) => _json({'error': 'session store unavailable'}, 503),
      );
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          AuthInterceptor(storage, sessionTerminator: terminator),
        );

      await expectLater(
        dio.get<dynamic>('/groups'),
        throwsA(isA<DioException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(storage.cleared, isFalse, reason: 'credential vẫn còn giá trị');
      expect(storage.session, 'sess-con-song');
      expect(
        expired,
        isEmpty,
        reason: 'không được đá người dùng về màn đăng nhập',
      );
    });

    // Hồi quy: một 401 chậm của phiên cũ không được giết phiên mới.
    //
    // Người dùng đăng xuất rồi đăng nhập lại trong lúc một request của phiên cũ
    // còn đang bay. Khi nó trả 401, credential đang lưu đã là của phiên mới.
    test('401 của phiên cũ không giết phiên vừa đăng nhập lại', () async {
      final storage = _FakeTokenStorage(session: 'sess-cu');
      final events = SessionEvents();
      addTearDown(events.dispose);
      final terminator = SessionTerminator(storage, events);
      final expired = <void>[];
      events.onExpired.listen(expired.add);

      final adapter = _FakeAdapter((options) {
        // Đăng nhập lại xảy ra trong lúc request còn đang bay.
        storage.session = 'sess-moi';
        return _json({'error': 'unauthorized'}, 401);
      });
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          AuthInterceptor(storage, sessionTerminator: terminator),
        );

      await expectLater(
        dio.get<dynamic>('/groups'),
        throwsA(isA<DioException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        storage.session,
        'sess-moi',
        reason: 'phiên vừa đăng nhập không được xóa bởi 401 của phiên trước',
      );
      expect(storage.cleared, isFalse);
      expect(expired, isEmpty, reason: 'phiên mới chưa bao giờ bị thu hồi');
    });

    test('401 của đúng phiên đang lưu vẫn kết thúc phiên như cũ', () async {
      final storage = _FakeTokenStorage(session: 'sess-dead');
      final events = SessionEvents();
      addTearDown(events.dispose);
      final terminator = SessionTerminator(storage, events);
      final expired = <void>[];
      events.onExpired.listen(expired.add);

      final adapter = _FakeAdapter(
        (options) => _json({'error': 'unauthorized'}, 401),
      );
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          AuthInterceptor(storage, sessionTerminator: terminator),
        );

      await expectLater(
        dio.get<dynamic>('/groups'),
        throwsA(isA<DioException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(storage.cleared, isTrue);
      expect(expired, hasLength(1));
    });
  });
}
