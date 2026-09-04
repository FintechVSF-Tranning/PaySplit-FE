import 'package:dio/dio.dart';

Stream<List<int>> openSseByteStream({
  required Dio dio,
  required String path,
  Map<String, dynamic>? queryParameters,
  required Map<String, String> headers,
  CancelToken? cancelToken,
}) async* {
  final response = await dio.get<ResponseBody>(
    path,
    queryParameters: queryParameters,
    cancelToken: cancelToken,
    options: Options(
      responseType: ResponseType.stream,
      headers: headers,
      receiveTimeout: Duration.zero,
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  final status = response.statusCode ?? 0;
  if (status != 200) {
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
    );
  }
  final body = response.data;
  if (body == null) {
    throw DioException(
      requestOptions: response.requestOptions,
      type: DioExceptionType.badResponse,
    );
  }
  yield* body.stream.map((chunk) => chunk.toList());
}
