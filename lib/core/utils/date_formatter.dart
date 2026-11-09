import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _isoMonthFormat = DateFormat('yyyy-MM');

  /// Returns "YYYY-MM" string from DateTime
  static String toMonthKey(DateTime date) {
    return _isoMonthFormat.format(date);
  }

  /// Parses "YYYY-MM" string to DateTime (first day of month)
  static DateTime fromMonthKey(String monthKey) {
    try {
      final parts = monthKey.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
    } catch (_) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, 1);
    }
  }

  /// Returns "November 2026"
  static String formatMonthYear(DateTime date, {String? locale}) {
    return DateFormat('MMMM yyyy', locale).format(date);
  }

  /// Returns "Nov 2026"
  static String formatShortMonthYear(DateTime date, {String? locale}) {
    return DateFormat('MMM yyyy', locale).format(date);
  }

  /// Returns "05 Nov 2026"
  static String formatDate(DateTime date, {String? locale}) {
    return DateFormat('dd MMM yyyy', locale).format(date);
  }

  /// Returns previous month key
  static String getPreviousMonth(String currentMonthKey) {
    final current = fromMonthKey(currentMonthKey);
    final prev = DateTime(current.year, current.month - 1, 1);
    return toMonthKey(prev);
  }

  /// Returns next month key
  static String getNextMonth(String currentMonthKey) {
    final current = fromMonthKey(currentMonthKey);
    final next = DateTime(current.year, current.month + 1, 1);
    return toMonthKey(next);
  }
}

