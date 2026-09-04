import 'dart:async';
import 'dart:js_interop';

import 'package:dio/dio.dart';
import 'package:web/web.dart' as web;

import '../config/env_config.dart';

Stream<List<int>> openSseByteStream({
  required Dio dio,
  required String path,
  Map<String, dynamic>? queryParameters,
  required Map<String, String> headers,
  CancelToken? cancelToken,
}) async* {
  final uri = Uri.parse('${EnvConfig.apiBaseUrl}$path').replace(
    queryParameters: queryParameters?.map(
      (key, value) => MapEntry(key, value.toString()),
    ),
  );
  final jsHeaders = web.Headers();
  headers.forEach((name, value) {
    jsHeaders.set(name, value);
  });
  final abort = web.AbortController();
  if (cancelToken != null) {
    unawaited(cancelToken.whenCancel.whenComplete(() => abort.abort()));
  }
  final init = web.RequestInit(
    method: 'GET',
    headers: jsHeaders,
    signal: abort.signal,
  );
  final response = await web.window.fetch(uri.toString().toJS, init).toDart;
  if (response.status != 200) {
    throw DioException(
      requestOptions: RequestOptions(path: path, headers: headers),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: path),
        statusCode: response.status,
        headers: _dioHeaders(response.headers),
      ),
      type: DioExceptionType.badResponse,
    );
  }
  final body = response.body;
  if (body == null) {
    throw DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.badResponse,
    );
  }
  final reader = web.ReadableStreamDefaultReader(body);
  while (true) {
    final chunk = await reader.read().toDart;
    if (chunk.done) {
      break;
    }
    final value = chunk.value;
    if (value == null) {
      continue;
    }
    yield (value as JSUint8Array).toDart;
  }
}

/// Các header phản hồi mà client thực sự đọc được sau một lỗi.
///
/// `Retry-After` là bắt buộc: không có nó, một 429 sẽ được thử lại theo backoff
/// của chính client và bỏ qua cửa sổ mà server vừa yêu cầu.
const _preservedResponseHeaders = <String>[
  'retry-after',
  'content-type',
  'x-request-id',
];

Headers _dioHeaders(web.Headers source) {
  final map = <String, List<String>>{};
  for (final name in _preservedResponseHeaders) {
    final value = source.get(name);
    if (value != null && value.isNotEmpty) {
      map[name] = [value];
    }
  }
  return Headers.fromMap(map);
}
