import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/error/failures.dart';
import 'package:paysplit/core/network/dio_failure_mapper.dart';

DioException _badResponse(int statusCode, dynamic data) {
  final requestOptions = RequestOptions(path: '/test');
  return DioException(
    requestOptions: requestOptions,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: requestOptions,
      statusCode: statusCode,
      data: data,
    ),
  );
}

void main() {
  group(
    'mapDioError with the new envelope body ({"success":false,"error":{...,"details":...}})',
    () {
      test('maps a 401 to UnauthorizedFailure using error.code/message', () {
        final failure = mapDioError(
          _badResponse(401, {
            'success': false,
            'error': {
              'code': 'INVALID_CREDENTIALS',
              'message': 'invalid email or password',
            },
          }),
        );

        expect(failure, isA<UnauthorizedFailure>());
        expect(failure.code, 'INVALID_CREDENTIALS');
        expect(
          failure.message,
          'Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại.',
        );
      });

      test(
        'maps a 422 to ValidationFailure and reads per-field errors from "details"',
        () {
          final failure = mapDioError(
            _badResponse(422, {
              'success': false,
              'error': {
                'code': 'VALIDATION_FAILED',
                'message': 'request validation failed',
                'details': {'email': 'invalid'},
              },
            }),
          );

          expect(failure, isA<ValidationFailure>());
          final validation = failure as ValidationFailure;
          expect(validation.fields, {'email': 'invalid'});
        },
      );

      test(
        'falls back to compound field message when the code has no canned translation',
        () {
          final failure = mapDioError(
            _badResponse(400, {
              'success': false,
              'error': {
                'code': 'SOME_UNKNOWN_CODE',
                'message': 'bad request',
                'details': {'phone_number': 'required'},
              },
            }),
          );

          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('phone_number: required'));
        },
      );
    },
  );

  group(
    'mapDioError stays compatible with the old body ({"error":{...,"fields":...}})',
    () {
      test('still reads code/message', () {
        final failure = mapDioError(
          _badResponse(401, {
            'error': {
              'code': 'INVALID_CREDENTIALS',
              'message': 'invalid email or password',
            },
          }),
        );

        expect(failure, isA<UnauthorizedFailure>());
        expect(failure.code, 'INVALID_CREDENTIALS');
      });

      test('still reads per-field errors from the legacy "fields" key', () {
        final failure = mapDioError(
          _badResponse(422, {
            'error': {
              'code': 'VALIDATION_FAILED',
              'message': 'request validation failed',
              'fields': {'email': 'invalid'},
            },
          }),
        );

        expect(failure, isA<ValidationFailure>());
        final validation = failure as ValidationFailure;
        expect(validation.fields, {'email': 'invalid'});
      });
    },
  );

  test('429 nói rõ thời gian chờ lấy từ header Retry-After', () {
    final requestOptions = RequestOptions(path: '/bills');
    final failure = mapDioError(
      DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: requestOptions,
          statusCode: 429,
          headers: Headers.fromMap({
            'retry-after': ['42'],
          }),
          data: {
            'success': false,
            'error': {'code': 'RATE_LIMITED', 'message': 'rate limit exceeded'},
          },
        ),
      ),
    );

    expect(failure.message, contains('42 giây'));
    expect(failure.message, isNot(contains('thao tác sai')));
  });

  test('429 không có Retry-After vẫn có thông báo dễ hiểu', () {
    final failure = mapDioError(
      _badResponse(429, {
        'success': false,
        'error': {'code': 'RATE_LIMITED', 'message': 'rate limit exceeded'},
      }),
    );

    expect(failure.message, contains('quá nhiều yêu cầu'));
  });

  test('maps a connection timeout to NetworkFailure', () {
    final requestOptions = RequestOptions(path: '/test');
    final exception = DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.connectionTimeout,
    );

    expect(mapDioError(exception), isA<NetworkFailure>());
  });
}
