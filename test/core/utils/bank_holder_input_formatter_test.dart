import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/utils/bank_holder_input_formatter.dart';

void main() {
  const formatter = BankHolderInputFormatter();

  TextEditingValue format(TextEditingValue old, TextEditingValue next) =>
      formatter.formatEditUpdate(old, next);

  TextEditingValue typed(String text, {TextRange? composing}) =>
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
        composing: composing ?? TextRange.empty,
      );

  group('BankHolderInputFormatter', () {
    test('gõ từng phím với vùng composing mở không nhân đôi ký tự', () {
      // Đây chính là lỗi đã thấy trên máy thật: gõ "PHAM" ra "PPHPHAPHAM".
      // Bàn phím giữ vùng composing trên cả từ đang gõ; nếu formatter trả về
      // giá trị còn mang khoảng composing cũ thì bàn phím commit lại buffer của
      // nó và tiền tố cũ bị nối thêm sau mỗi phím.
      var current = TextEditingValue.empty;
      for (final keystroke in ['p', 'ph', 'pha', 'pham']) {
        final next = typed(
          keystroke,
          composing: TextRange(start: 0, end: keystroke.length),
        );
        current = format(current, next);
      }

      expect(current.text, 'PHAM');
      expect(current.composing, TextRange.empty);
      expect(current.selection.baseOffset, 4);
    });

    test('bỏ dấu tiếng Việt và in hoa', () {
      expect(format(TextEditingValue.empty, typed('Nguyễn Văn A')).text,
          'NGUYEN VAN A');
      expect(format(TextEditingValue.empty, typed('Phạm Đức')).text,
          'PHAM DUC');
    });

    test('giữ dấu cách giữa các từ, kể cả dấu cách vừa gõ ở cuối', () {
      // trim() trong formatter sẽ khiến không ai gõ nổi dấu cách giữa hai từ.
      final result = format(typed('NGUYEN'), typed('NGUYEN '));

      expect(result.text, 'NGUYEN ');
      expect(result.selection.baseOffset, 7);
    });

    test('loại ký tự ngân hàng không nhận, con trỏ bám đúng vị trí', () {
      // "NG@UYEN" với con trỏ ngay sau '@' (offset 4): '@' bị loại nên con trỏ
      // phải lùi về sau "NG" + "U" đã giữ lại, tức offset 3.
      final result = format(
        typed('NGUYEN'),
        const TextEditingValue(
          text: 'NG@UYEN',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );

      expect(result.text, 'NGUYEN');
      expect(result.selection.baseOffset, 3);
    });

    test('giữ nguyên các ký tự ngân hàng cho phép', () {
      expect(format(TextEditingValue.empty, typed('NGUYEN VAN A-B.C')).text,
          'NGUYEN VAN A-B.C');
      expect(format(TextEditingValue.empty, typed('CONG TY 123')).text,
          'CONG TY 123');
    });

    test('chuỗi đã hợp lệ thì trả về nguyên vẹn, không đụng vào composing', () {
      final valid = typed(
        'NGUYEN VAN A',
        composing: const TextRange(start: 0, end: 6),
      );

      expect(identical(format(TextEditingValue.empty, valid), valid), isTrue);
    });
  });
}
