import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/budget_plan_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../services/budget_plan_service.dart';

final budgetPlanServiceProvider = Provider<BudgetPlanService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return BudgetPlanService(dioClient);
});

class BudgetPlanState {
  final BudgetPlanModel? plan;
  final bool isLoading;
  final String? errorMessage;

  BudgetPlanState({
    this.plan,
    this.isLoading = false,
    this.errorMessage,
  });

  BudgetPlanState copyWith({
    BudgetPlanModel? plan,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BudgetPlanState(
      plan: plan ?? this.plan,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class BudgetPlanController extends StateNotifier<BudgetPlanState> {
  final BudgetPlanService _service;

  BudgetPlanController(this._service) : super(BudgetPlanState()) {
    fetchCurrentPlan();
  }

  Future<void> fetchCurrentPlan() async {
    state = state.copyWith(isLoading: true);
    try {
      final plan = await _service.getCurrentPlan();
      state = state.copyWith(plan: plan, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> savePlan(BudgetPlanModel plan) async {
    state = state.copyWith(isLoading: true);
    try {
      final savedPlan = await _service.createPlan(plan);
      state = state.copyWith(plan: savedPlan, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void incrementActualSpent(double amount) {
    if (state.plan == null) return;
    
    final currentPlan = state.plan!;
    final updatedPlan = BudgetPlanModel(
      id: currentPlan.id,
      dailyRoutines: currentPlan.dailyRoutines,
      weeklyRoutines: currentPlan.weeklyRoutines,
      monthlyFixed: currentPlan.monthlyFixed,
      createdAt: currentPlan.createdAt,
      totalPlanned: currentPlan.totalPlanned,
      actualSpent: currentPlan.actualSpent + amount,
      savedAmount: currentPlan.savedAmount,
      isLocked: currentPlan.isLocked,
    );

    state = state.copyWith(plan: updatedPlan);
  }
}

final budgetPlanControllerProvider =
    StateNotifierProvider<BudgetPlanController, BudgetPlanState>((ref) {
  final service = ref.watch(budgetPlanServiceProvider);
  return BudgetPlanController(service);
});
