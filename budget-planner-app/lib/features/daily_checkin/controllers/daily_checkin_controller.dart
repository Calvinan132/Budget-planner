import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/offline_cache_service.dart';
import '../../../core/utils/date_helper.dart';
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
  final DateTime selectedDate; // Ngay dang xem (mac dinh hom nay)
  final bool isLoading;
  final bool isSyncing;
  final String? errorMessage;

  DailyHomeState({
    this.piggyBankSavings = 0,
    this.savingsGoal = 0,
    this.expenses = const [],
    required this.selectedDate,
    this.isLoading = false,
    this.isSyncing = false,
    this.errorMessage,
  });

  DailyHomeState copyWith({
    double? piggyBankSavings,
    double? savingsGoal,
    List<DailyExpenseModel>? expenses,
    DateTime? selectedDate,
    bool? isLoading,
    bool? isSyncing,
    String? errorMessage,
  }) {
    return DailyHomeState(
      piggyBankSavings: piggyBankSavings ?? this.piggyBankSavings,
      savingsGoal: savingsGoal ?? this.savingsGoal,
      expenses: expenses ?? this.expenses,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage,
    );
  }
}

class DailyCheckInController extends StateNotifier<DailyHomeState> {
  final DailyCheckInService _service;
  final OfflineCacheService _cacheService = OfflineCacheService();
  final Ref _ref;

  DailyCheckInController(this._service, this._ref)
      : super(DailyHomeState(selectedDate: DateTime.now())) {
    loadTodayData();
  }

  Future<void> loadTodayData() async {
    state = state.copyWith(isLoading: true);
    try {
      await _ref.read(budgetPlanControllerProvider.notifier).fetchCurrentPlan();
      final planState = _ref.read(budgetPlanControllerProvider);
      final homeData = await _service.getTodayData(planState.plan, date: state.selectedDate);
      
      final currentSavings = planState.plan?.savedAmount ?? homeData.piggyBankSavings;
      final currentGoal = (planState.plan?.initialBudget != null && planState.plan!.initialBudget > 0)
          ? planState.plan!.initialBudget
          : (planState.plan?.totalPlanned ?? homeData.savingsGoal);

      state = state.copyWith(
        piggyBankSavings: currentSavings,
        savingsGoal: currentGoal,
        expenses: homeData.expenses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Chuyển sang xem chi tiêu của một ngày khác (lịch sử).
  Future<void> setSelectedDate(DateTime date) async {
    state = state.copyWith(selectedDate: date, errorMessage: null);
    await loadTodayData();
  }

  Future<void> syncOfflineData() async {
    state = state.copyWith(isSyncing: true);
    try {
      await _service.syncPendingActions();
      await loadTodayData();
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  /// Cập nhật trạng thái check-in của một món vào một ngày nhất định.
  /// status: 'completed' | 'skipped' | 'pending' (cho phép hoàn tác nếu chọn nhầm).
  Future<bool> processCheckIn({
    required DateTime date,
    required String itemId,
    required String status,
  }) async {
    // Idempotency guard: nếu món không còn trong danh sách thì không có gì để thay đổi
    final itemIndex = state.expenses.indexWhere((e) => e.id == itemId);
    if (itemIndex == -1) return true;

    final item = state.expenses[itemIndex];
    final oldStatus = item.status;
    if (oldStatus == status) return true;

    // 1. Tính toán delta tiền về heo tiết kiệm
    double piggyDelta = 0;
    if (oldStatus == 'pending' && status == 'skipped') {
      piggyDelta = item.amount; // bỏ qua → tiền về heo
    } else if (oldStatus == 'completed' && status == 'skipped') {
      piggyDelta = item.amount; // hết "Có tiêu" → tiền về heo
    } else if (oldStatus == 'skipped' && status == 'completed') {
      piggyDelta = -item.amount; // hoàn tác bỏ qua → tirar khỏi heo
    } else if (oldStatus == 'skipped' && status == 'pending') {
      piggyDelta = -item.amount; // hoàn tác bỏ qua
    }
    // pending↔completed: không đổi heo

    // 2. Cập nhật tại chỗ (giữ món trong danh sách để sau này vẫn sửa lại được)
    final updatedExpenses = List<DailyExpenseModel>.from(state.expenses)
      ..[itemIndex] = item.copyWith(status: status);

    state = state.copyWith(
      piggyBankSavings: state.piggyBankSavings + piggyDelta,
      expenses: updatedExpenses,
    );

    // 3. Persist local cache (chỉ hôm nay)
    if (DateHelper.isSameDay(date, DateTime.now())) {
      await _cacheService.cacheTodayData(
        expenses: updatedExpenses,
        piggyBankSavings: state.piggyBankSavings,
        savingsGoal: state.savingsGoal,
      );
    }

    // 4. Gửi lên server
    final networkSuccess = await _service.checkInExpense(date, itemId, status);
    if (!networkSuccess) {
      // Chờ đồng bộ sau khi có kết nối (chỉ hôm nay)
      if (DateHelper.isSameDay(date, DateTime.now())) {
        await _cacheService.addPendingAction({
          'type': 'check_in',
          'itemId': itemId,
          'status': status,
          'date': date.toIso8601String().substring(0, 10),
        });
      }
    } else {
      _ref.read(budgetPlanControllerProvider.notifier).fetchCurrentPlan();
    }

    return true;
  }

  /// Giữ nguyên API cũ (hôm nay).
  Future<bool> processCheckInToday({
    required String itemId,
    required String status,
  }) async {
    return processCheckIn(date: DateTime.now(), itemId: itemId, status: status);
  }

  Future<bool> addUnexpectedExpense(double amount, String reason) async {
    // Ghi đúng vào ngày đang xem (hỗ trợ xem/sửa lịch sử ngày cũ).
    final date = state.selectedDate;
    final success = await _service.addUnexpectedExpense(amount, reason, date: date);
    if (!success) {
      // Offline mode: queue unexpected expense (kèm ngày để sync đúng ngày)
      await _cacheService.addPendingAction({
        'type': 'unexpected_expense',
        'amount': amount,
        'reason': reason,
        'date': date.toIso8601String().substring(0, 10),
      });
    }

    // Refresh home data or deduct from piggy bank
    await loadTodayData();
    return true;
  }

  /// Sửa một khoản chi phát sinh (optimistic UI + hàng đợi offline).
  Future<bool> updateUnexpectedExpense(
      String expenseId, double oldAmount, double newAmount, String reason) async {
    final date = state.selectedDate;

    // Cập nhật tại chỗ trong danh sách đang hiển thị
    final itemIndex = state.expenses.indexWhere((e) => e.id == expenseId);
    if (itemIndex != -1) {
      final updatedExpenses = List<DailyExpenseModel>.from(state.expenses)
        ..[itemIndex] = state.expenses[itemIndex].copyWith(name: reason, amount: newAmount);
      state = state.copyWith(expenses: updatedExpenses);
    }

    final success = await _service.updateUnexpectedExpense(expenseId, newAmount, reason, date);
    if (!success) {
      await _cacheService.addPendingAction({
        'type': 'update_unexpected',
        'expenseId': expenseId,
        'oldAmount': oldAmount,
        'amount': newAmount,
        'reason': reason,
        'date': date.toIso8601String().substring(0, 10),
      });
    }

    await loadTodayData();
    return true;
  }

  /// Xóa một khoản chi phát sinh (optimistic UI + hàng đợi offline).
  Future<bool> deleteUnexpectedExpense(String expenseId) async {
    final date = state.selectedDate;

    state = state.copyWith(
      expenses: state.expenses.where((e) => e.id != expenseId).toList(),
    );

    final success = await _service.deleteUnexpectedExpense(expenseId, date);
    if (!success) {
      await _cacheService.addPendingAction({
        'type': 'delete_unexpected',
        'expenseId': expenseId,
        'date': date.toIso8601String().substring(0, 10),
      });
    }

    await loadTodayData();
    return true;
  }
}

final dailyCheckInControllerProvider =
    StateNotifierProvider<DailyCheckInController, DailyHomeState>((ref) {
  final service = ref.watch(dailyCheckInServiceProvider);
  return DailyCheckInController(service, ref);
});
