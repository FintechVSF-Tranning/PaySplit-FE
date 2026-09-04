import 'dart:async';

import 'sse_frame.dart';

class RealtimeFrameBus {
  static final RealtimeFrameBus instance = RealtimeFrameBus();

  final StreamController<SseFrame> _controller =
      StreamController<SseFrame>.broadcast();

  Stream<SseFrame> get frames => _controller.stream;

  void add(SseFrame frame) {
    if (!_controller.isClosed) {
      _controller.add(frame);
    }
  }

  void close() {
    _controller.close();
  }
}
