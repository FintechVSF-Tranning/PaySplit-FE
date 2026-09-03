import 'dart:convert';

/// Một frame đã tách khỏi luồng `text/event-stream`.
///
/// Nằm ở `core` chứ không ở tầng data của một feature: đây là hợp đồng vận
/// chuyển dùng chung cho stream người dùng và cả hai stream legacy, nên không
/// feature nào được sở hữu nó.
class SseFrame {
  const SseFrame({required this.event, required this.data});

  final String event;
  final Map<String, dynamic> data;
}

/// Tách các dòng `text/event-stream` thành frame.
///
/// Tách khỏi phần mở kết nối để test được mà không cần dựng Dio — đây là chỗ dễ
/// sai nhất của cả client: một frame bị ghép nhầm sẽ làm client hiểu sai version
/// và tự đẩy mình vào vòng catch-up.
Stream<SseFrame> parseSseLines(Stream<String> lines) async* {
  var eventName = 'message';
  final data = StringBuffer();

  await for (final line in lines) {
    if (line.isEmpty) {
      // Dòng trống kết thúc một frame.
      if (data.isNotEmpty) {
        try {
          final decoded = jsonDecode(data.toString());
          if (decoded is Map<String, dynamic>) {
            yield SseFrame(event: eventName, data: decoded);
          }
        } catch (_) {
          // Frame hỏng hoặc không phải JSON: bỏ qua thay vì giết cả stream.
        }
      }
      eventName = 'message';
      data.clear();
      continue;
    }
    if (line.startsWith(':')) continue; // comment giữ kết nối
    final separator = line.indexOf(':');
    if (separator < 0) continue;
    final field = line.substring(0, separator);
    final value = line.substring(separator + 1).trimLeft();
    switch (field) {
      case 'event':
        eventName = value;
      case 'data':
        data.write(value);
      // 'id' bỏ qua: version đã nằm trong payload nên không phải đọc hai nguồn.
    }
  }
}
