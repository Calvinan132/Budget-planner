import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/daily_expense_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../budget_setup/controllers/budget_plan_controller.dart';
import '../services/daily_checkin_service.dart';

final dailyCheckInServiceProvider = Provider<DailyCheckInService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return DailyCheckInService(dioClient);
});

class DailyHomeState {
  final double piggyBankSavings;
  final double savingsGoal;
  final List<DailyExpenseModel> expenses;
  final bool isLoading;
  final String? errorMessage;

  DailyHomeState({
    this.piggyBankSavings = 240000,
    this.savingsGoal = 500000,
    this.expenses = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DailyHomeState copyWith({
    double? piggyBankSavings,
    double? savingsGoal,
    List<DailyExpenseModel>? expenses,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DailyHomeState(
      piggyBankSavings: piggyBankSavings ?? this.piggyBankSavings,
      savingsGoal: savingsGoal ?? this.savingsGoal,
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DailyCheckInController extends StateNotifier<DailyHomeState> {
  final DailyCheckInService _service;
  final Ref _ref;

  DailyCheckInController(this._service, this._ref) : super(DailyHomeState()) {
    loadTodayData();
  }

  Future<void> loadTodayData() async {
    state = state.copyWith(isLoading: true);
    try {
      // Access the master plan to simulate Phase 2 generation
      final planState = _ref.read(budgetPlanControllerProvider);
      
      final homeData = await _service.getTodayData(planState.plan);
      
      state = state.copyWith(
        piggyBankSavings: planState.plan?.savedAmount ?? homeData.piggyBankSavings,
        savingsGoal: planState.plan?.totalPlanned ?? homeData.savingsGoal,
        expenses: homeData.expenses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> processCheckIn({
    required String itemId,
    required String status, // 'completed' | 'skipped'
  }) async {
    // Idempotency guard: If item is no longer in state, it was already processed
    final itemIndex = state.expenses.indexWhere((e) => e.id == itemId);
    if (itemIndex == -1) return true; // Treat as success if already handled

    final item = state.expenses[itemIndex];
    
    // 1. Snapshot previous state for rollback
    final previousState = state;

    // 2. Optimistic Update (Immediate UI response)
    final updatedExpenses = List<DailyExpenseModel>.from(state.expenses)..removeAt(itemIndex);
    double newPiggySavings = state.piggyBankSavings;

    if (status == 'skipped') {
      newPiggySavings += item.amount;
    }

    state = state.copyWith(
      piggyBankSavings: newPiggySavings,
      expenses: updatedExpenses,
    );

    // 3. Network Request (Background)
    try {
      final success = await _service.checkInExpense(itemId, status);
      if (!success) {
        throw Exception('Backend check-in failed');
      }
      return true;
    } catch (e) {
      // 4. Rollback on failure
      state = previousState;
      return false;
    }
  }

  Future<bool> addUnexpectedExpense(double amount, String reason) async {
    final success = await _service.addUnexpectedExpense(amount, reason);
    if (success) {
      // Refresh home data
      await loadTodayData();
    }
    return success;
  }
}

final dailyCheckInControllerProvider =
    StateNotifierProvider<DailyCheckInController, DailyHomeState>((ref) {
  final service = ref.watch(dailyCheckInServiceProvider);
  return DailyCheckInController(service, ref);
});
