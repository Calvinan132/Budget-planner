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
  final int startDay;    // Ngày bắt đầu tính kế hoạch (từ server)
  final int activeDays;  // Số ngày tính kế hoạch (từ server)
  final double initialBudget; // Số tiền người dùng có thể sử dụng trong tháng
  final double totalPlanned;  // Tổng chi phí dự kiến (theo activeDays, từ server)
  final double actualSpent;
  final double savedAmount;
  final bool isLocked;

  BudgetPlanModel({
    this.id,
    required this.dailyRoutines,
    required this.weeklyRoutines,
    required this.monthlyFixed,
    this.createdAt,
    this.startDay = 1,
    this.activeDays = 30,
    this.initialBudget = 0.0,
    this.totalPlanned = 0.0,
    this.actualSpent = 0.0,
    this.savedAmount = 0.0,
    this.isLocked = true,
  });

  /// Tính toán tổng chi phí theo toàn bộ 30 ngày (chỉ dùng để tham khảo, không hiển thị cho user)
  double get totalMonthlyBudget {
    double dailyTotal = dailyRoutines.fold(0, (sum, item) => sum + (item.amount * 30));
    double weeklyTotal = weeklyRoutines.fold(0, (sum, item) => sum + (item.amount * item.frequencyPerWeek * 4.33));
    double fixedTotal = monthlyFixed.fold(0, (sum, item) => sum + item.amount);
    return dailyTotal + weeklyTotal + fixedTotal;
  }

  /// Tính toán tổng chi phí kế hoạch cho một số ngày cụ thể (vd: số ngày còn lại trong tháng)
  double calculatePlannedForDays(int days, {bool includeFixed = true}) {
    double dailyTotal = dailyRoutines.fold(0, (sum, item) => sum + (item.amount * days));
    double weeks = days / 7.0;
    double weeklyTotal = weeklyRoutines.fold(
        0, (sum, item) => sum + (item.amount * item.frequencyPerWeek * weeks));
    double fixedTotal = includeFixed ? monthlyFixed.fold(0, (sum, item) => sum + item.amount) : 0;
    return dailyTotal + weeklyTotal + fixedTotal;
  }

  /// Tổng chi tiêu hàng ngày trên 1 ngày đơn lẻ
  double get totalDailyPerDay {
    return dailyRoutines.fold(0, (sum, item) => sum + item.amount);
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
      startDay: (json['startDay'] as num?)?.toInt() ?? 1,
      activeDays: (json['activeDays'] as num?)?.toInt() ?? 30,
      initialBudget: (json['initialBudget'] as num?)?.toDouble() ?? 0.0,
      totalPlanned: (json['totalPlanned'] as num?)?.toDouble() ?? 0.0,
      actualSpent: (json['actualSpent'] as num?)?.toDouble() ?? 0.0,
      savedAmount: (json['savedAmount'] as num?)?.toDouble() ?? 0.0,
      isLocked: json['isLocked'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'startDay': startDay,
      'activeDays': activeDays,
      'dailyRoutines': dailyRoutines.map((e) => e.toJson()).toList(),
      'weeklyRoutines': weeklyRoutines.map((e) => e.toJson()).toList(),
      'monthlyFixed': monthlyFixed.map((e) => e.toJson()).toList(),
      'initialBudget': initialBudget > 0 ? initialBudget : totalPlanned,
      'totalPlanned': totalPlanned > 0 ? totalPlanned : totalMonthlyBudget,
      'actualSpent': actualSpent,
      'savedAmount': savedAmount,
      'isLocked': isLocked,
    };
  }
}
