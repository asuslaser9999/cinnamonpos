import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _grouped = NumberFormat.decimalPattern('id_ID');

  static String format(num amount) => _formatter.format(amount);

  static String formatGrouped(num amount) => _grouped.format(amount.round());

  static String formatDate(DateTime date) =>
      DateFormat('d MMMM yyyy', 'id_ID').format(date);

  static String formatDateShort(DateTime date) =>
      DateFormat('d MMMM yyyy', 'id_ID').format(date);

  static String formatPeriod(DateTime start, DateTime end) {
    final a = DateTime(start.year, start.month, start.day);
    final b = DateTime(end.year, end.month, end.day);
    if (a == b) {
      return formatDate(a);
    }
    if (a.year == b.year && a.month == b.month) {
      return '${a.day}–${formatDate(b)}';
    }
    if (a.year == b.year) {
      return '${DateFormat('d MMMM', 'id_ID').format(a)} – ${formatDate(b)}';
    }
    return '${formatDate(a)} – ${formatDate(b)}';
  }

  static String formatTime(DateTime date) =>
      DateFormat('HH.mm', 'id_ID').format(date);

  static String formatDateTime(DateTime date) =>
      DateFormat('dd MMM yyyy HH.mm', 'id_ID').format(date);

  static double parse(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }
}

class AppDateRange {
  AppDateRange._();

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String isoDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);
}

/// Formats typed digits as Indonesian thousands, e.g. 150000 → 150.000
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue();
    }
    final formatted = CurrencyFormatter.formatGrouped(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
