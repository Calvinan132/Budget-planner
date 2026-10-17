class DailyExpenseModel {
  final String id;
  final String name;
  final double amount;
  final String category;
  final String status; // 'pending' | 'completed' | 'skipped'
  final DateTime date;
  final bool isUnexpected;
  final String? note;

  DailyExpenseModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    this.status = 'pending',
    required this.date,
    this.isUnexpected = false,
    this.note,
  });

  bool get isCompleted => status == 'completed';
  bool get isSkipped => status == 'skipped';

  factory DailyExpenseModel.fromJson(Map<String, dynamic> json) {
    return DailyExpenseModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? json['reason'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? (json['isUnexpected'] == true ? 'unexpected' : 'general'),
      status: json['status'] ?? 'pending',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      isUnexpected: json['isUnexpected'] ?? false,
      note: json['note'] ?? json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'status': status,
      'date': date.toIso8601String(),
      'isUnexpected': isUnexpected,
      'note': note,
    };
  }

  DailyExpenseModel copyWith({
    String? id,
    String? name,
    double? amount,
    String? category,
    String? status,
    DateTime? date,
    bool? isUnexpected,
    String? note,
  }) {
    return DailyExpenseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      status: status ?? this.status,
      date: date ?? this.date,
      isUnexpected: isUnexpected ?? this.isUnexpected,
      note: note ?? this.note,
    );
  }
}

class DailyHomeData {
  final double piggyBankSavings; // "+240.000đ"
  final double savingsGoal; // "500k"
  final List<DailyExpenseModel> expenses;

  DailyHomeData({
    required this.piggyBankSavings,
    this.savingsGoal = 500000,
    required this.expenses,
  });
}
