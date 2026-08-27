import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Số hiệu phiên đăng nhập hiện tại. Tăng lên mỗi lần đăng nhập thành công.
///
/// Mọi provider mang dữ liệu của người dùng (nhóm, hóa đơn, công nợ, thông báo)
/// đều `ref.watch` giá trị này, nên đổi tài khoản là chúng bị dựng lại từ đầu.
/// Nếu không có nó, các provider không `autoDispose` sẽ giữ nguyên dữ liệu của
/// tài khoản cũ cho tới khi khởi động lại app.
///
/// Cách này chỉ chạm vào provider **đang sống**: khác với việc gọi
/// `ref.invalidate(...)` cho cả danh sách — vốn dựng luôn các provider chưa ai
/// dùng và bắn một loạt request thừa ngay lúc chuyển tài khoản.
final sessionRevisionProvider = StateProvider<int>((ref) => 0);

/// Đánh dấu bắt đầu một phiên mới: gọi ngay sau khi đăng nhập thành công.
void beginNewSession(Ref ref) {
  ref.read(sessionRevisionProvider.notifier).state++;
}
