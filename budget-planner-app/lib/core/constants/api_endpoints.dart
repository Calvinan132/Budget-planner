class ApiEndpoints {
  // Base URL can be changed for emulator (10.0.2.2) or real device/localhost
  static String baseUrl = 'http://10.0.2.2:5001/api';

  // Auth
  static const String syncUser = '/users/sync';

  // Master Budget Plan
  static const String createPlan = '/plans';
  static const String currentPlan = '/plans/current';

  // Daily Check-in
  static const String todayExpenses = '/daily/today';
  static const String checkInExpense = '/daily/check-in';
  static const String unexpectedExpense = '/daily/unexpected-expense';

  // Reports & History
  static const String monthlyReport = '/reports/monthly';
  static const String historyReport = '/reports/history';
}
