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

  factory MonthlyReportModel.fromJson(Map<String, dynamic> json) {
    return MonthlyReportModel(
      month: json['month'] ?? DateTime.now().month,
      year: json['year'] ?? DateTime.now().year,
      originalBudget: (json['originalBudget'] as num?)?.toDouble() ?? 6000000,
      actualSpent: (json['actualSpent'] as num?)?.toDouble() ?? 5400000,
      savedAmount: (json['savedAmount'] as num?)?.toDouble() ?? 600000,
      spendingPercentage: (json['spendingPercentage'] as num?)?.toDouble() ?? 90.0,
      skippedCount: (json['skippedCount'] as num?)?.toInt() ?? 5,
      behaviorLogs: (json['behaviorLogs'] as List<dynamic>?)
              ?.map((e) => BehaviorLogItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
