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

  /// Loại bỏ dấu tiếng Việt, giữ nguyên case.
  static String removeDiacritics(String input) {
    var result = input;
    _vietnameseMap.forEach((replacement, chars) {
      for (final char in chars.split('')) {
        result = result.replaceAll(char, replacement);
      }
    });
    return result;
  }

  /// Chuẩn hóa chuỗi để tìm kiếm: bỏ dấu, lowercase, trim và gộp khoảng trắng.
  static String normalizeForSearch(String input) {
    final noDiacritics = removeDiacritics(input).toLowerCase().trim();
    return noDiacritics.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Kiểm tra chuỗi [source] có chứa chuỗi tìm kiếm [query] hay không (hỗ trợ cả có dấu và không dấu).
  static bool matchesSearch(String source, String query) {
    final q = query.trim();
    if (q.isEmpty) return true;
    final normalizedQuery = normalizeForSearch(q);
    if (normalizedQuery.isEmpty) return true;

    final normalizedSource = normalizeForSearch(source);
    if (normalizedSource.contains(normalizedQuery)) return true;

    // Kiểm tra trực tiếp case-insensitive có dấu
    if (source.toLowerCase().contains(q.toLowerCase())) return true;

    return false;
  }

  /// Removes Vietnamese accents and converts string to uppercase ASCII (e.g. `Nguyễn Văn A` -> `NGUYEN VAN A`).
  static String toBankHolderFormat(String input) {
    final noDiacritics = removeDiacritics(input.trim());
    return noDiacritics.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\s\.\-]'), '');
  }
}

