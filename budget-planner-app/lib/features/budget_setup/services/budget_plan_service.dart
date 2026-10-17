import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/budget_plan_model.dart';

class BudgetPlanService {
  final DioClient _dioClient;

  BudgetPlanService(this._dioClient);

  Future<BudgetPlanModel> createPlan(BudgetPlanModel plan) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.createPlan,
        data: plan.toJson(),
      );
      return BudgetPlanModel.fromJson(response.data['data']);
    } catch (e) {
      return plan; // Return local plan if backend is offline
    }
  }

  Future<BudgetPlanModel?> getCurrentPlan() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.currentPlan);
      return BudgetPlanModel.fromJson(response.data['data']);
    } catch (e) {
      // Default local plan fallback
      return BudgetPlanModel(
        id: 'default_plan',
        dailyRoutines: [
          RoutineItem(id: '1', name: 'Ăn sáng', amount: 25000),
          RoutineItem(id: '2', name: 'Cà phê', amount: 35000),
        ],
        weeklyRoutines: [
          RoutineItem(id: '3', name: 'Đi siêu thị', amount: 500000, frequencyPerWeek: 1),
        ],
        monthlyFixed: [
          RoutineItem(id: '4', name: 'Tiền thuê nhà', amount: 3500000),
          RoutineItem(id: '5', name: 'Điện nước', amount: 500000),
          RoutineItem(id: '6', name: 'Internet', amount: 250000),
        ],
        createdAt: DateTime.now(),
      );
    }
  }

  Future<BudgetPlanModel> updateCurrentPlan(BudgetPlanModel plan) async {
    try {
      final response = await _dioClient.dio.put(
        ApiEndpoints.currentPlan,
        data: plan.toJson(),
      );
      return BudgetPlanModel.fromJson(response.data['data']);
    } catch (e) {
      return plan;
    }
  }
}
