import 'package:intl/intl.dart';

class DateHelper {
  static String formatMonthYear(DateTime date) {
    return 'Tháng ${date.month}, ${date.year}';
  }

  static String formatDayMonth(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String formatShortDay(DateTime date) {
    final DateFormat formatter = DateFormat('dd/MM');
    return formatter.format(date);
  }

  static String getTodayFormatted() {
    final now = DateTime.now();
    return 'Hôm nay, ${now.day} tháng ${now.month}';
  }
}
