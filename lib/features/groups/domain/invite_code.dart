/// Độ dài mã mời do backend sinh (`domain.InviteCodeLength`).
const int kInviteCodeLength = 8;

/// Tách mã mời khỏi một link đầy đủ, hoặc trả lại nguyên mã khi người dùng gõ tay.
///
/// **Không đổi hoa/thường.** Mã mời là Base62 phân biệt hoa thường
/// (`A-Za-z0-9`, ví dụ `xuRWai09`) và backend tra bằng so sánh chuỗi chính xác
/// (`WHERE code = $1`), nên mọi thao tác chuẩn hóa chữ đều làm mã hợp lệ trở
/// thành 404 INVITE_NOT_FOUND.
String extractInviteCode(String raw) {
  var value = raw.trim();
  // Cắt fragment và query trước, nếu không '#'/'?' sẽ dính vào mã.
  for (final separator in ['#', '?']) {
    final index = value.indexOf(separator);
    if (index >= 0) value = value.substring(0, index);
  }
  while (value.endsWith('/')) {
    value = value.substring(0, value.length - 1);
  }
  final slash = value.lastIndexOf('/');
  return slash >= 0 ? value.substring(slash + 1) : value;
}
