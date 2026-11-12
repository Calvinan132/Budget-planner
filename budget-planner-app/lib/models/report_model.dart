import '../../core/utils/currency_formatter.dart';

class BehaviorLogItem {
  final String title;
  final String subtitle;
  final String iconType; // 'food', 'coffee', 'transport', 'tip'

  BehaviorLogItem({
    required this.title,
    required this.subtitle,
    required this.iconType,
  });

  factory BehaviorLogItem.fromJson(Map<String, dynamic> json) {
    return BehaviorLogItem(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      iconType: json['iconType'] ?? 'tip',
    );
  }
}

class MonthlyReportModel {
  final int month;
  final int year;
  final double originalBudget;
  final double actualSpent;
  final double savedAmount;
  final double spendingPercentage;
  final int skippedCount;
  final List<BehaviorLogItem> behaviorLogs;

  MonthlyReportModel({
    required this.month,
    required this.year,
    required this.originalBudget,
    required this.actualSpent,
    required this.savedAmount,
    required this.spendingPercentage,
    required this.skippedCount,
    required this.behaviorLogs,
  });

  /// Parse theo đúng shape backend trả về:
  /// { month, year, totalPlanned, actualSpent, savedAmount,
  ///   skippedItemsInsights: [{name, skippedCount, totalSavedAmount}],
  ///   topUnexpectedExpenses: [{id, date, amount, reason}] }
  /// Không còn fallback số liệu giả lập — thiếu dữ liệu thì là 0/rỗng.
  factory MonthlyReportModel.fromJson(Map<String, dynamic> json) {
    final double originalBudget = (json['totalPlanned'] as num?)?.toDouble() ??
        (json['originalBudget'] as num?)?.toDouble() ??
        0.0;
    final double actualSpent = (json['actualSpent'] as num?)?.toDouble() ?? 0.0;
    final double savedAmount = (json['savedAmount'] as num?)?.toDouble() ?? 0.0;

    // Backend không trả spendingPercentage → tự tính từ actualSpent/totalPlanned.
    final double spendingPercentage =
        (json['spendingPercentage'] as num?)?.toDouble() ??
            (originalBudget > 0 ? (actualSpent / originalBudget) * 100 : 0.0);

    final List<dynamic> insights = (json['skippedItemsInsights'] as List<dynamic>?) ?? const [];
    final List<dynamic> topUnexpected =
        (json['topUnexpectedExpenses'] as List<dynamic>?) ?? const [];

    int skippedCount = 0;
    if (json['skippedCount'] != null) {
      skippedCount = (json['skippedCount'] as num).toInt();
    } else {
      for (final raw in insights) {
        final m = Map<String, dynamic>.from(raw as Map);
        skippedCount += (m['skippedCount'] as num?)?.toInt() ?? 0;
      }
    }

    // Ưu tiên behaviorLogs có sẵn (cache cũ); nếu không có thì dựng từ insights của backend.
    List<BehaviorLogItem> behaviorLogs;
    if (json['behaviorLogs'] is List) {
      behaviorLogs = (json['behaviorLogs'] as List<dynamic>)
          .map((e) => BehaviorLogItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else {
      behaviorLogs = <BehaviorLogItem>[];
      for (final raw in insights) {
        final m = Map<String, dynamic>.from(raw as Map);
        final name = (m['name'] as String?) ?? 'khoản chi';
        final count = (m['skippedCount'] as num?)?.toInt() ?? 0;
        final saved = (m['totalSavedAmount'] as num?)?.toDouble() ?? 0.0;
        behaviorLogs.add(BehaviorLogItem(
          title: 'Bỏ qua $count× $name',
          subtitle: '${CurrencyFormatter.formatVND(saved)} gửi heo đất',
          iconType: iconTypeFor(name),
        ));
      }
      for (final raw in topUnexpected) {
        final m = Map<String, dynamic>.from(raw as Map);
        final reason = (m['reason'] as String?) ?? 'Khoản phát sinh';
        final amount = (m['amount'] as num?)?.toDouble() ?? 0.0;
        behaviorLogs.add(BehaviorLogItem(
          title: reason,
          subtitle: 'Chi phát sinh ${CurrencyFormatter.formatVND(amount)}',
          iconType: iconTypeFor(reason),
        ));
      }
    }

    return MonthlyReportModel(
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      originalBudget: originalBudget,
      actualSpent: actualSpent,
      savedAmount: savedAmount,
      spendingPercentage: spendingPercentage,
      skippedCount: skippedCount,
      behaviorLogs: behaviorLogs,
    );
  }

  /// Suy ra loại icon hành vi từ tên khoản chi (tiếng Việt).
  static String iconTypeFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('cà phê') || n.contains('cafe') || n.contains('coffee')) {
      return 'coffee';
    }
    if (n.contains('ăn') ||
        n.contains('nấu') ||
        n.contains('bún') ||
        n.contains('phở') ||
        n.contains('cơm') ||
        n.contains('trà')) {
      return 'food';
    }
    if (n.contains('xe') ||
        n.contains('xăng') ||
        n.contains('bus') ||
        n.contains('metro') ||
        n.contains('grab')) {
      return 'transport';
    }
    return 'tip';
  }
}
