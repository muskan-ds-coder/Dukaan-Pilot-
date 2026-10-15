import 'package:intl/intl.dart';

/// Formatter ensuring integer-paise calculations to completely prevent floating-point rounding errors.
class CurrencyFormatter {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _inrFormatterWhole = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Converts paise (integer) to formatted currency string (e.g. 150000 paise -> ₹1,500)
  static String formatPaise(int paise, {bool showDecimalsIfZero = false}) {
    final double rupees = paise / 100.0;
    if (!showDecimalsIfZero && paise % 100 == 0) {
      return _inrFormatterWhole.format(rupees);
    }
    return _inrFormatter.format(rupees);
  }

  /// Converts rupee double value to safe integer paise
  static int rupeesToPaise(num rupees) {
    return (rupees * 100).round();
  }

  /// Converts safe integer paise to display double
  static double paiseToRupees(int paise) {
    return paise / 100.0;
  }

  /// Parses user entered string into safe paise
  static int parseToPaise(String input) {
    if (input.trim().isEmpty) return 0;
    final sanitized = input.replaceAll('₹', '').replaceAll(',', '').trim();
    final doubleVal = double.tryParse(sanitized) ?? 0.0;
    return (doubleVal * 100).round();
  }
}
