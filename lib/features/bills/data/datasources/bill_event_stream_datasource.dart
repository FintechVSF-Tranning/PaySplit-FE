import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';

/// Represents an SSE frame parsed from `text/event-stream`.
class BillSseFrame {
  const BillSseFrame({required this.event, required this.data});

  final String event;
  final Map<String, dynamic> data;
}

/// SSE client for `GET /bills/{id}/events`.
///
/// Uses Dio to automatically inherit AuthInterceptor (Bearer token injection
/// and token refresh).
@lazySingleton
class BillEventStreamDataSource {
  const BillEventStreamDataSource(this._dio);

  final Dio _dio;

  /// Subscribes to real-time events for a bill (e.g. OCR job status, snapshots).
  Stream<BillSseFrame> stream(
    String billId, {
    required String groupId,
    CancelToken? cancelToken,
  }) async* {
    final response = await _dio.get<ResponseBody>(
      ApiEndpoints.billEvents(billId),
      queryParameters: {'group_id': groupId},
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
        receiveTimeout: Duration.zero,
      ),
    );

    yield* parseBillSseLines(
      utf8.decoder
          .bind(response.data!.stream.map((chunk) => chunk.toList()))
          .transform(const LineSplitter()),
    );
  }
}

/// Parses raw lines from `text/event-stream` into [BillSseFrame] objects.
Stream<BillSseFrame> parseBillSseLines(Stream<String> lines) async* {
  var eventName = 'message';
  final data = StringBuffer();

  await for (final line in lines) {
    if (line.isEmpty) {
      if (data.isNotEmpty) {
        try {
          final decoded = jsonDecode(data.toString());
          if (decoded is Map<String, dynamic>) {
            yield BillSseFrame(event: eventName, data: decoded);
          }
        } catch (_) {
          // Ignore non-JSON or malformed frames
        }
      }
      eventName = 'message';
      data.clear();
      continue;
    }
    if (line.startsWith(':')) continue; // Heartbeat/comment frame
    final separator = line.indexOf(':');
    if (separator < 0) continue;
    final field = line.substring(0, separator);
    final value = line.substring(separator + 1).trimLeft();
    switch (field) {
      case 'event':
        eventName = value;
      case 'data':
        data.write(value);
    }
  }
}
