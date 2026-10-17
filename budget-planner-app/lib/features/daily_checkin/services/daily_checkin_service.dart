import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/daily_expense_model.dart';

import '../../../models/budget_plan_model.dart';

class DailyCheckInService {
  final DioClient _dioClient;

  DailyCheckInService(this._dioClient);

  Future<DailyHomeData> getTodayData(BudgetPlanModel? plan) async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.todayExpenses);
      final responseData = response.data['data'];
      
      final expenses = (responseData['items'] as List<dynamic>?)
              ?.map((e) => DailyExpenseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
          
      // Backend does not return piggySavings in dailyLog, so we use plan or fallback
      final piggySavings = plan?.savedAmount ?? 240000;
      final savingsGoal = plan?.totalPlanned ?? 500000;

      return DailyHomeData(
        piggyBankSavings: piggySavings,
        savingsGoal: savingsGoal,
        expenses: expenses,
      );
    } catch (e) {
      // Phase 2 Simulation (Local fallback):
      // Auto-populate items from `dailyRoutines` with initial status: `pending`
      final now = DateTime.now();
      
      List<DailyExpenseModel> localExpenses = [];
      
      if (plan != null && plan.dailyRoutines.isNotEmpty) {
        localExpenses = plan.dailyRoutines.map((routine) => DailyExpenseModel(
          id: 'daily_${routine.id}_${now.day}',
          name: routine.name,
          amount: routine.amount,
          category: 'food', // Defaulting to food for UI icon rendering
          status: 'pending',
          date: now,
        )).toList();
      } else {
        localExpenses = [
          DailyExpenseModel(id: '1', name: 'Ăn sáng', amount: 25000, category: 'food', date: now),
          DailyExpenseModel(id: '2', name: 'Cà phê', amount: 35000, category: 'coffee', date: now),
          DailyExpenseModel(id: '3', name: 'Ăn trưa', amount: 50000, category: 'food', date: now),
        ];
      }

      return DailyHomeData(
        piggyBankSavings: plan?.savedAmount ?? 240000,
        savingsGoal: plan?.totalPlanned ?? 500000,
        expenses: localExpenses,
      );
    }
  }

  Future<bool> checkInExpense(String itemId, String status) async {
    try {
      await _dioClient.dio.patch(
        ApiEndpoints.checkInExpense,
        data: {
          'itemId': itemId,
          'status': status, // 'completed' | 'skipped'
        },
      );
      return true;
    } catch (e) {
      return true; // Local success fallback
    }
  }

  Future<bool> addUnexpectedExpense(double amount, String reason) async {
    try {
      await _dioClient.dio.post(
        ApiEndpoints.unexpectedExpense,
        data: {
          'amount': amount,
          'reason': reason,
        },
      );
      return true;
    } catch (e) {
      return true; // Local success fallback
    }
  }
}
