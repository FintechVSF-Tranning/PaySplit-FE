import 'package:dio/dio.dart';

import '../error/failures.dart';

/// Maps a caught error to a [Failure]. Repository implementations wrap
/// their datasource calls in `try { ... } on DioException catch (e) { return
/// Left(mapDioError(e)); }` so this is the single place request-layer
/// errors are translated into domain-facing failures.
Failure mapDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      final message = _extractMessage(error.response?.data) ?? 'Server error';
      if (statusCode == 401 || statusCode == 403) {
        return UnauthorizedFailure(message);
      }
      if (statusCode == 422 || statusCode == 400) {
        return ValidationFailure(message);
      }
      return ServerFailure(message, statusCode: statusCode);
    case DioExceptionType.cancel:
      return const UnexpectedFailure('Request cancelled');
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
    default:
      return const UnexpectedFailure();
  }
}

String? _extractMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data['message'] as String? ?? data['error'] as String?;
  }
  return null;
}
