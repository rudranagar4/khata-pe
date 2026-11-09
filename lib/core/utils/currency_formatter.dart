import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _numberFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '',
    decimalDigits: 0,
  );

  /// Formats amount in Indian numbering format: e.g. ₹1,25,000
  static String format(int amount, {bool includeSymbol = true}) {
    if (includeSymbol) {
      return _inrFormatter.format(amount).trim();
    } else {
      return _numberFormatter.format(amount).trim();
    }
  }

  /// Parses input string like "1,25,000" or "₹125000" into integer rupees
  static int parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }
}

