import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static String formatVND(num amount, {bool showSymbol = true}) {
    final formatted = _vndFormat.format(amount);
    if (!showSymbol) {
      return formatted.replaceAll('đ', '').trim();
    }
    return formatted;
  }

  static String formatShort(num amount) {
    if (amount >= 1000000) {
      final val = amount / 1000000;
      return val % 1 == 0 ? '${val.toInt()}M' : '${val.toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      final val = amount / 1000;
      return val % 1 == 0 ? '${val.toInt()}k' : '${val.toStringAsFixed(0)}k';
    }
    return amount.toString();
  }

  static double parseAmount(String text) {
    final clean = text.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(clean) ?? 0;
  }
}
