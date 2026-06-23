import 'package:intl/intl.dart';

/// Formatter untuk mata uang Rupiah
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _compactFormatter = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _numberFormatter = NumberFormat.decimalPattern('id_ID');

  /// Format angka ke Rupiah: 125874 → "Rp 125.874"
  static String format(double amount) {
    return _formatter.format(amount);
  }

  /// Format angka ke Rupiah ringkas: 1250000 → "Rp 1,25Jt"
  static String formatCompact(double amount) {
    return _compactFormatter.format(amount);
  }

  /// Format angka dengan separator: 125874 → "125.874"
  static String formatNumber(double amount) {
    return _numberFormatter.format(amount);
  }

  /// Parse string Rupiah ke double: "125.874" → 125874.0
  static double? parse(String text) {
    try {
      final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
      return double.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }

  /// Format persentase: 0.11 → "11%"
  static String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(value * 100 == (value * 100).roundToDouble() ? 0 : 1)}%';
  }

  /// Format persentase dari nilai langsung: 11 → "11%"
  static String formatPercentageDirect(double value) {
    return '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}%';
  }
}
