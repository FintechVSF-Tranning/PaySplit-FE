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

  /// Signed variant for transaction rows: credits get a leading `+`, debits
  /// keep the `-` that [format] already produces.
  static String vndSigned(num amount) =>
      amount > 0 ? '+${_vnd.format(amount)}' : _vnd.format(amount);
}
