import 'package:dio/dio.dart';

Stream<List<int>> openSseByteStream({
  required Dio dio,
  required String path,
  Map<String, dynamic>? queryParameters,
  required Map<String, String> headers,
  CancelToken? cancelToken,
}) {
  throw UnsupportedError('SSE byte stream is not available on this platform');
}
