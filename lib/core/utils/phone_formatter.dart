/// Utilities for formatting and normalizing Vietnamese phone numbers.
class PhoneFormatter {
  /// Converts an E.164 phone number (e.g. `+84123456789`) to a local display format (e.g. `0123456789`).
  static String formatForDisplay(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '';
    var cleaned = phone.trim().replaceAll(RegExp(r'\s+'), '');
    if (cleaned.startsWith('+84')) {
      cleaned = '0${cleaned.substring(3)}';
    } else if (cleaned.startsWith('84') && cleaned.length >= 11) {
      cleaned = '0${cleaned.substring(2)}';
    }
    return cleaned;
  }

  /// Converts a local input (e.g. `0123456789`, `+84123456789`) to E.164 format (e.g. `+84123456789`).
  static String normalizeForApi(String phone) {
    var cleaned = phone.trim().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('+84')) {
      return cleaned;
    }
    if (cleaned.startsWith('84') && cleaned.length >= 11) {
      return '+$cleaned';
    }
    if (cleaned.startsWith('0')) {
      return '+84${cleaned.substring(1)}';
    }
    if (!cleaned.startsWith('+') && cleaned.isNotEmpty) {
      return '+84$cleaned';
    }
    return cleaned;
  }
}
