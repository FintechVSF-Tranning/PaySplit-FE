import 'package:flutter/services.dart';

import 'vietnamese_utils.dart';

/// Chuẩn hóa tên chủ tài khoản ngay khi gõ: in hoa, bỏ dấu, chỉ giữ ký tự mà
/// hệ thống ngân hàng chấp nhận (`A-Z`, `0-9`, khoảng trắng, `.`, `-`).
///
/// Phải là một [TextInputFormatter] chứ không phải một nhánh trong `onChanged`.
/// Sửa `controller.value` từ trong `onChanged` là ghi đè text ngay giữa lúc bàn
/// phím đang có vùng composing mở, và `copyWith` thì giữ nguyên khoảng composing
/// cũ — khoảng đó lúc này trỏ vào một chuỗi không còn tồn tại. Gboard nhận lại
/// `setEditingState` với vùng composing lạc, rồi commit tiếp buffer của chính
/// nó, nên mỗi phím gõ thêm lại nối cả tiền tố cũ vào: gõ "PHAM" ra
/// "PPHPHAPHAM". Formatter chạy trước khi giá trị tới controller nên không có
/// vòng phản hồi đó.
///
/// Không `trim()`: cắt khoảng trắng cuối ở đây thì không ai gõ nổi dấu cách
/// giữa hai từ. Việc trim để dành cho lúc lưu.
class BankHolderInputFormatter extends TextInputFormatter {
  const BankHolderInputFormatter();

  static final RegExp _disallowed = RegExp(r'[^A-Z0-9 .\-]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final source = newValue.text;
    final rawCursor = newValue.selection.end;
    final cursor = rawCursor < 0 ? source.length : rawCursor;

    final buffer = StringBuffer();
    var offset = 0;
    for (var i = 0; i < source.length; i++) {
      // Bỏ dấu trước rồi mới in hoa: 'đ' -> 'd' -> 'D'. Cả hai bước đều giữ
      // nguyên độ dài, chỉ bước lọc dưới đây mới rút ngắn chuỗi.
      final normalized = VietnameseUtils.removeDiacritics(
        source[i],
      ).toUpperCase();
      final kept = normalized.replaceAll(_disallowed, '');
      buffer.write(kept);
      if (i < cursor) offset += kept.length;
    }

    final text = buffer.toString();
    if (text == source) return newValue;

    // Dựng mới thay vì `newValue.copyWith`: hàm dựng mặc định `composing` là
    // rỗng, còn `copyWith` sẽ bê nguyên khoảng composing đang trỏ vào chuỗi cũ
    // sang chuỗi mới — đúng cái gây ra lỗi nhân đôi ký tự.
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset.clamp(0, text.length)),
    );
  }
}
