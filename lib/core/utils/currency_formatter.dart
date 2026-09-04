import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Single source of truth for money rendering so every screen shows the same
/// grouping and symbol placement. VND has no minor unit, hence
/// `decimalDigits: 0`.
abstract class CurrencyFormatter {
  static final NumberFormat _vnd = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static String vnd(num amount) => _vnd.format(amount);
  static String formatVND(num amount) => _vnd.format(amount);

  /// Signed variant for transaction rows: credits get a leading `+`, debits
  /// keep the `-` that [format] already produces.
  static String vndSigned(num amount) =>
      amount > 0 ? '+${_vnd.format(amount)}' : _vnd.format(amount);

  static String formatInput(int amount) =>
      NumberFormat.decimalPattern('vi_VN').format(amount);

  static int parseInput(String value) =>
      int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  static double parsePercent(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;

  static int percentToVnd(String value, int baseAmount) =>
      (baseAmount * parsePercent(value) / 100).round();

  static String vndToPercent(int amount, int baseAmount) {
    if (amount <= 0 || baseAmount <= 0) return '';
    final percent = amount * 100 / baseAmount;
    final fixed = percent.toStringAsFixed(2);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '').replaceAll('.', ',');
  }
}

/// Formats an integer VND value with Vietnamese thousands separators while
/// keeping the cursor beside the same logical digit during edits.
class VndTextInputFormatter extends TextInputFormatter {
  final int maxDigits;

  const VndTextInputFormatter({this.maxDigits = 11});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    if (digits.length > maxDigits) return oldValue;

    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final formatted = CurrencyFormatter.formatInput(int.parse(digits));
    final cursor = newValue.selection.end.clamp(0, newValue.text.length);
    final digitsBeforeCursor = newValue.text
        .substring(0, cursor)
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;

    var formattedCursor = 0;
    var seenDigits = 0;
    while (formattedCursor < formatted.length &&
        seenDigits < digitsBeforeCursor) {
      if (RegExp(r'[0-9]').hasMatch(formatted[formattedCursor])) {
        seenDigits++;
      }
      formattedCursor++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formattedCursor),
    );
  }
}

/// Accepts percentages from 0 to 100 with at most two decimal places.
/// Both comma and dot are accepted, while the displayed separator is comma.
class PercentTextInputFormatter extends TextInputFormatter {
  const PercentTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return const TextEditingValue();

    final normalized = newValue.text.replaceAll('.', ',');
    if (!RegExp(r'^\d{0,3}(,\d{0,2})?$').hasMatch(normalized)) {
      return oldValue;
    }
    final percent = CurrencyFormatter.parsePercent(normalized);
    if (percent > 100) return oldValue;

    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }
}
