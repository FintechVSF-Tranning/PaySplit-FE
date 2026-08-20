/// Utilities for normalizing Vietnamese text, removing accents/diacritics for banking and search.
class VietnameseUtils {
  static const _vietnameseMap = {
    'a': 'áàạảãâấầậẩẫăắằặẳẵ',
    'A': 'ÁÀẠẢÃÂẤẦẬẨẪĂẮẰẶẲẴ',
    'e': 'éèẹẻẽêếềệểễ',
    'E': 'ÉÈẸẺẼÊẾỀỆỂỄ',
    'o': 'óòọỏõôốồộổỗơớờợởỡ',
    'O': 'ÓÒỌỎÕÔỐỒỘỔỖƠỚỜỢỞỠ',
    'u': 'úùụủũưứừựửữ',
    'U': 'ÚÙỤỦŨƯỨỪỰỬỮ',
    'i': 'íìịỉĩ',
    'I': 'ÍÌỊỈĨ',
    'd': 'đ',
    'D': 'Đ',
    'y': 'ýỳỵỷỹ',
    'Y': 'ÝỲỴỶỸ',
  };

  /// Removes Vietnamese accents and converts string to uppercase ASCII (e.g. `Nguyễn Văn A` -> `NGUYEN VAN A`).
  static String toBankHolderFormat(String input) {
    var result = input.trim();
    _vietnameseMap.forEach((replacement, chars) {
      for (final char in chars.split('')) {
        result = result.replaceAll(char, replacement);
      }
    });
    return result.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\s\.\-]'), '');
  }
}
