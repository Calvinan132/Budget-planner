import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner_app/models/budget_plan_model.dart';
import 'package:budget_planner_app/core/utils/currency_formatter.dart';

void main() {
  test('CurrencyFormatter formats VND correctly', () {
    final formatted = CurrencyFormatter.formatVND(45000000);
    expect(formatted.contains('45.000.000'), isTrue);
  });

  test('BudgetPlanModel totalMonthlyBudget calculation', () {
    final plan = BudgetPlanModel(
      dailyRoutines: [
        RoutineItem(id: '1', name: 'Ăn sáng', amount: 20000),
      ],
      weeklyRoutines: [
        RoutineItem(id: '2', name: 'Đi siêu thị', amount: 500000, frequencyPerWeek: 1),
      ],
      monthlyFixed: [
        RoutineItem(id: '3', name: 'Tiền nhà', amount: 3500000),
      ],
    );

    // daily: 20000 * 30 = 600000
    // weekly: 500000 * 1 * 4.33 = 2165000
    // fixed: 3500000
    // Total = 6265000
    expect(plan.totalMonthlyBudget, greaterThan(6000000));
  });
}
