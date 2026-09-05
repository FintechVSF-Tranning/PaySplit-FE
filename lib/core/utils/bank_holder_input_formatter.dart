import 'package:flutter/services.dart';

import 'vietnamese_utils.dart';

/// Chuẩn hóa tên chủ tài khoản ngay khi gõ: in hoa, bỏ dấu, chỉ giữ ký tự mà
/// hệ thống ngân hàng chấp nhận (`A-Z`, `0-9`, khoảng trắng, `.`, `-`).
///
/// Phải là một [TextInputFormatter] chứ không phải một nhánh trong `onChanged`,
/// và phải đứng yên trong lúc IME còn đang soạn dở. Cả hai cách ghi đè text
/// giữa một phiên composition đều dẫn tới cùng một chỗ: bàn phím giữ buffer
/// riêng, không biết chuỗi vừa bị đổi, nên phím kế tiếp nó chèn lại cả buffer
/// đó vào — gõ "PHAM" ra "PPHPHAPHAM".
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
    // Đang giữa một phiên composition của IME (gõ tiếng Việt telex, gợi ý từ
    // của bàn phím, IME tiếng Trung/Nhật/Hàn...): sửa text lúc này là ghi đè
    // ngay dưới chân bàn phím. Bàn phím vẫn giữ buffer riêng của nó và không
    // biết chuỗi vừa bị đổi, nên phím kế tiếp nó chèn lại cả buffer đó vào —
    // gõ "ph" ra "Pph". Trên Flutter Web nó còn làm khoảng composing của engine
    // trỏ ra ngoài chuỗi mới và ném thẳng assertion
    // "Range end N is out of text of length M".
    //
    // Để yên cho tới lúc IME commit: lượt đó `composing` rỗng và cả chuỗi được
    // chuẩn hóa một lần.
    if (newValue.composing.isValid) return newValue;

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
