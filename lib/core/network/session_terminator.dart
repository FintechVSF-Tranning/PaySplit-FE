import 'package:injectable/injectable.dart';

import 'session_events.dart';
import 'token_storage.dart';

/// Nơi duy nhất kết thúc phiên: xóa credential cục bộ và báo lên UI đúng một
/// lần, dù nhiều đường cùng phát hiện phiên chết cùng lúc (một request REST
/// song song với stream realtime, ví dụ).
///
/// Trước khi bỏ refresh token, lớp này (`SessionRefresher`) còn phải xoay vòng
/// token — giờ credential tự gia hạn bằng TTL trượt phía server nên không còn
/// gì để xoay, và việc kết thúc phiên là tất cả những gì còn lại.
@lazySingleton
class SessionTerminator {
  SessionTerminator(this._tokens, this._events);

  final TokenStorage _tokens;
  final SessionEvents _events;

  Future<void>? _ending;

  /// Xóa credential và báo `SessionEvents.onExpired` nếu trước đó còn phiên.
  /// Idempotent và an toàn khi gọi đồng thời từ nhiều nơi.
  ///
  /// [expectedSessionId] là credential mà lời gọi này tin là đã chết. Truyền vào
  /// thì việc kết thúc phiên chỉ xảy ra khi credential đang lưu ĐÚNG là nó.
  /// Không truyền thì xóa vô điều kiện, giữ nguyên hành vi cũ.
  ///
  /// Vì sao cần: một request chậm phát đi từ phiên A có thể trả 401 SAU khi
  /// người dùng đã đăng xuất và đăng nhập lại thành phiên B. Nếu không đối chiếu,
  /// cái 401 của A sẽ xóa credential B và đá người vừa đăng nhập ra ngoài — đúng
  /// kiểu "bị đăng xuất vì một cuộc đua" mà spec 0011 muốn loại bỏ.
  Future<void> endSession({String? expectedSessionId}) {
    return _ending ??= _endSession(
      expectedSessionId,
    ).whenComplete(() => _ending = null);
  }

  Future<void> _endSession(String? expectedSessionId) async {
    final current = await _tokens.sessionId;
    if (expectedSessionId != null && current != expectedSessionId) {
      // Credential đã đổi kể từ lúc request kia được phát đi: phiên hiện tại
      // không phải phiên đã chết, không được đụng vào.
      return;
    }
    final hadSession = current?.isNotEmpty == true;
    await _tokens.clear();
    if (hadSession) {
      _events.notifyExpired();
    }
  }
}
