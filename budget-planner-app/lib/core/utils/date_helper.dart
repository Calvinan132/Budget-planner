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

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Số ngày trong tháng (28, 29, 30 hoặc 31)
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Số ngày còn lại trong tháng (tính cả hôm nay)
  static int getRemainingDaysInMonth([DateTime? date]) {
    final now = date ?? DateTime.now();
    final totalDays = getDaysInMonth(now.year, now.month);
    return (totalDays - now.day + 1).clamp(1, totalDays);
  }
}
