import 'dart:async';

import 'package:injectable/injectable.dart';

/// Kênh báo "phiên đăng nhập đã mất" từ tầng network lên tầng presentation.
///
/// [AuthInterceptor] xóa token khi refresh thất bại hoặc gặp 401 không cứu
/// được, nhưng nó không biết gì về Riverpod. Nếu không có kênh này, người dùng
/// vẫn kẹt lại trong màn hình đã đăng nhập với mọi API trả 401 cho tới khi tự
/// thoát ra.
@lazySingleton
class SessionEvents {
  final StreamController<void> _expired = StreamController<void>.broadcast();

  /// Phát ra mỗi lần phiên bị mất. Broadcast nên nhiều nơi cùng nghe được.
  Stream<void> get onExpired => _expired.stream;

  void notifyExpired() {
    if (_expired.isClosed) return;
    _expired.add(null);
  }

  @disposeMethod
  void dispose() => _expired.close();
}
