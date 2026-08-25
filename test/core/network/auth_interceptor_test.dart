import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/network/interceptors/auth_interceptor.dart';
import 'package:paysplit/core/network/token_storage.dart';

/// TokenStorage trong bộ nhớ, không chạm tới FlutterSecureStorage.
class _FakeTokenStorage implements TokenStorage {
  _FakeTokenStorage({this.access, this.refresh});

  String? access;
  String? refresh;
  bool cleared = false;

  @override
  Future<String?> get accessToken async => access;

  @override
  Future<String?> get refreshToken async => refresh;

  @override
  Future<String> getOrCreateDeviceId() async => 'device-1';

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
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

ResponseBody _json(Map<String, dynamic> body, int status) => ResponseBody.fromString(
  _encode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

String _encode(Map<String, dynamic> body) {
  final entries = body.entries.map((e) {
    final value = e.value;
    if (value is Map<String, dynamic>) return '"${e.key}":${_encode(value)}';
    return '"${e.key}":"$value"';
  });
  return '{${entries.join(',')}}';
}

void main() {
  group('AuthInterceptor', () {
    test('làm mới token khi gặp 401 rồi thử lại request gốc', () async {
      final storage = _FakeTokenStorage(access: 'expired', refresh: 'refresh-1');
      var protectedCalls = 0;

      final adapter = _FakeAdapter((options) {
        if (options.path == '/auth/refresh') {
          return _json({
            'success': 'true',
            'data': {'access_token': 'fresh', 'refresh_token': 'refresh-2'},
          }, 200);
        }
        protectedCalls++;
        // Lần đầu access token đã hết hạn, lần thử lại mang token mới.
        if (options.headers['Authorization'] == 'Bearer fresh') {
          return _json({'ok': 'yes'}, 200);
        }
        return _json({'error': 'unauthorized'}, 401);
      });

      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          AuthInterceptor(
            storage,
            'http://test',
            dioFactory: (o) => Dio(o)..httpClientAdapter = adapter,
          ),
        );

      final response = await dio.get<dynamic>('/groups');

      expect(response.statusCode, 200);
      expect(protectedCalls, 2, reason: 'gọi lần đầu bị 401, lần hai là retry');
      expect(adapter.calls['/auth/refresh'], 1);
      expect(await storage.accessToken, 'fresh');
      expect(storage.cleared, isFalse);
    });

    test('nhiều request 401 song song chỉ làm mới token đúng một lần', () async {
      // Refresh token của backend dùng một lần: gọi refresh song song sẽ bị coi
      // là tái sử dụng và thu hồi cả phiên (SESSION_REVOKED).
      final storage = _FakeTokenStorage(access: 'expired', refresh: 'refresh-1');

      final adapter = _FakeAdapter((options) {
        if (options.path == '/auth/refresh') {
          return _json({
            'data': {'access_token': 'fresh', 'refresh_token': 'refresh-2'},
          }, 200);
        }
        if (options.headers['Authorization'] == 'Bearer fresh') {
          return _json({'ok': 'yes'}, 200);
        }
        return _json({'error': 'unauthorized'}, 401);
      });

      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          AuthInterceptor(
            storage,
            'http://test',
            dioFactory: (o) => Dio(o)..httpClientAdapter = adapter,
          ),
        );

      await Future.wait([
        dio.get<dynamic>('/groups'),
        dio.get<dynamic>('/bills'),
        dio.get<dynamic>('/users/me'),
      ]);

      expect(adapter.calls['/auth/refresh'], 1);
    });

    test('làm mới thất bại thì xóa token và trả lỗi ra ngoài', () async {
      final storage = _FakeTokenStorage(access: 'expired', refresh: 'refresh-1');

      final adapter = _FakeAdapter((options) {
        if (options.path == '/auth/refresh') {
          return _json({'error': 'session revoked'}, 401);
        }
        return _json({'error': 'unauthorized'}, 401);
      });

      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          AuthInterceptor(
            storage,
            'http://test',
            dioFactory: (o) => Dio(o)..httpClientAdapter = adapter,
          ),
        );

      await expectLater(dio.get<dynamic>('/groups'), throwsA(isA<DioException>()));
      expect(storage.cleared, isTrue);
    });

    test('không làm mới cho chính endpoint đăng nhập', () async {
      final storage = _FakeTokenStorage(refresh: 'refresh-1');
      final adapter = _FakeAdapter((options) => _json({'error': 'bad credentials'}, 401));

      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          AuthInterceptor(
            storage,
            'http://test',
            dioFactory: (o) => Dio(o)..httpClientAdapter = adapter,
          ),
        );

      await expectLater(dio.post<dynamic>('/auth/sign-in', data: {}), throwsA(isA<DioException>()));
      expect(adapter.calls['/auth/refresh'], isNull, reason: 'không được gọi refresh');
    });
  });
}
