class RoutineItem {
  String id;
  String name;
  double amount;
  int frequencyPerWeek; // Only for weekly items (e.g. 1, 2)

  RoutineItem({
    required this.id,
    required this.name,
    required this.amount,
    this.frequencyPerWeek = 1,
  });

  factory RoutineItem.fromJson(Map<String, dynamic> json) {
    return RoutineItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      frequencyPerWeek: (json['frequencyPerWeek'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'frequencyPerWeek': frequencyPerWeek,
    };
  }
}

class BudgetPlanModel {
  final String? id;
  final List<RoutineItem> dailyRoutines;
  final List<RoutineItem> weeklyRoutines;
  final List<RoutineItem> monthlyFixed;
  final DateTime? createdAt;
  
  // Phase 1 / Phase 3 System Spec fields
  final double totalPlanned;
  final double actualSpent;
  final double savedAmount;
  final bool isLocked;

  BudgetPlanModel({
    this.id,
    required this.dailyRoutines,
    required this.weeklyRoutines,
    required this.monthlyFixed,
    this.createdAt,
    this.totalPlanned = 0.0,
    this.actualSpent = 0.0,
    this.savedAmount = 0.0,
    this.isLocked = true,
  });

  double get totalMonthlyBudget {
    double dailyTotal = dailyRoutines.fold(0, (sum, item) => sum + (item.amount * 30));
    double weeklyTotal = weeklyRoutines.fold(0, (sum, item) => sum + (item.amount * item.frequencyPerWeek * 4.33));
    double fixedTotal = monthlyFixed.fold(0, (sum, item) => sum + item.amount);
    return dailyTotal + weeklyTotal + fixedTotal;
  }

  factory BudgetPlanModel.fromJson(Map<String, dynamic> json) {
    return BudgetPlanModel(
      id: json['id'] ?? json['_id'],
      dailyRoutines: (json['dailyRoutines'] as List<dynamic>?)
              ?.map((e) => RoutineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      weeklyRoutines: (json['weeklyRoutines'] as List<dynamic>?)
              ?.map((e) => RoutineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      monthlyFixed: (json['monthlyFixed'] as List<dynamic>?)
              ?.map((e) => RoutineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      totalPlanned: (json['totalPlanned'] as num?)?.toDouble() ?? 0.0,
      actualSpent: (json['actualSpent'] as num?)?.toDouble() ?? 0.0,
      savedAmount: (json['savedAmount'] as num?)?.toDouble() ?? 0.0,
      isLocked: json['isLocked'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'dailyRoutines': dailyRoutines.map((e) => e.toJson()).toList(),
      'weeklyRoutines': weeklyRoutines.map((e) => e.toJson()).toList(),
      'monthlyFixed': monthlyFixed.map((e) => e.toJson()).toList(),
      'totalPlanned': totalPlanned > 0 ? totalPlanned : totalMonthlyBudget,
      'actualSpent': actualSpent > 0 ? actualSpent : totalMonthlyBudget,
      'savedAmount': savedAmount,
      'isLocked': isLocked,
    };
  }
}
