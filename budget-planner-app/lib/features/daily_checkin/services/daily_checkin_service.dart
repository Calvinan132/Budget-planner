import 'package:flutter/foundation.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/offline_cache_service.dart';
import '../../../core/utils/date_helper.dart';
import '../../../models/daily_expense_model.dart';
import '../../../models/budget_plan_model.dart';

class DailyCheckInService {
  final DioClient _dioClient;
  final OfflineCacheService _cacheService = OfflineCacheService();

  DailyCheckInService(this._dioClient);

  Future<DailyHomeData> getTodayData(BudgetPlanModel? plan, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final dateStr = targetDate.toIso8601String().substring(0, 10);

    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.todayExpenses,
        queryParameters: {'date': dateStr},
      );
      final responseData = response.data['data'];

      // Backend trả items kèm DailyLog — dùng ngày của log để hiển thị lịch sử đúng.
      final DateTime logDate = responseData['date'] != null
          ? DateTime.tryParse('${responseData['date']}') ?? targetDate
          : targetDate;

      final expenses = (responseData['items'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => DailyExpenseModel.fromJson(
                Map<String, dynamic>.from(e as Map)..['date'] = responseData['date'],
              ))
          .toList();

      // Khoản chi phát sinh cũng cần hiển thị trên home (hỗ trợ Sửa/Xóa).
      for (final e in (responseData['unexpectedExpenses'] as List<dynamic>? ?? const <dynamic>[])) {
        final m = Map<String, dynamic>.from(e as Map);
        expenses.add(DailyExpenseModel(
          id: (m['id'] ?? '') as String,
          name: (m['reason'] ?? 'Phát sinh') as String,
          amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
          category: 'unexpected',
          status: 'completed',
          date: logDate,
          isUnexpected: true,
        ));
      }

      final piggySavings = plan?.savedAmount ?? 0.0;
      // Use initialBudget as the goal (how much user had available this month)
      // If not set, fall back to totalPlanned
      final savingsGoal = (plan?.initialBudget != null && plan!.initialBudget > 0)
          ? plan.initialBudget
          : (plan?.totalPlanned ?? 0.0);

      final data = DailyHomeData(
        piggyBankSavings: piggySavings,
        savingsGoal: savingsGoal,
        expenses: expenses,
      );

      // Chỉ cache dữ liệu hôm nay để dùng offline; ngày khác dựa trên mạng
      if (DateHelper.isSameDay(targetDate, DateTime.now())) {
        await _cacheService.cacheTodayData(
          expenses: expenses,
          piggyBankSavings: piggySavings,
          savingsGoal: savingsGoal,
        );
        // Tự động đồng bộ các hành động đang chờ khi kết nối lại
        syncPendingActions();
      }

      return data;
    } catch (e) {
      debugPrint('[DailyCheckInService] Network fetch failed, trying local offline cache: $e');
      
      // 1. Try reading from offline cache
      final cachedData = await _cacheService.getCachedTodayData();
      if (cachedData != null) {
        debugPrint('[DailyCheckInService] Loaded ${cachedData.expenses.length} expenses from offline cache');
        return cachedData;
      }

      // 2. Offline generation fallback based on Master Plan
      final now = DateTime.now();
      List<DailyExpenseModel> localExpenses = [];
      
      if (plan != null && plan.dailyRoutines.isNotEmpty) {
        localExpenses = plan.dailyRoutines.map((routine) => DailyExpenseModel(
          id: 'daily_${routine.id}_${now.day}',
          name: routine.name,
          amount: routine.amount,
          category: 'food',
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

      final fallbackData = DailyHomeData(
        piggyBankSavings: plan?.savedAmount ?? 0,
        savingsGoal: plan?.totalPlanned ?? 0,
        expenses: localExpenses,
      );

      // Save initial offline snapshot
      await _cacheService.cacheTodayData(
        expenses: localExpenses,
        piggyBankSavings: fallbackData.piggyBankSavings,
        savingsGoal: fallbackData.savingsGoal,
      );

      return fallbackData;
    }
  }

  /// Cập nhật trạng thái check-in vào một ngày nhất định.
  /// status: 'completed' | 'skipped' | 'pending' (cho phép hoàn tác chọn nhầm).
  Future<bool> checkInExpense(DateTime date, String itemId, String status) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    try {
      await _dioClient.dio.patch(
        ApiEndpoints.checkInExpense,
        queryParameters: {'date': dateStr},
        data: {
          'itemId': itemId,
          'status': status, // 'completed' | 'skipped' | 'pending'
        },
      );
      return true;
    } catch (e) {
      debugPrint('[DailyCheckInService] Direct checkInExpense failed for $dateStr (offline mode): $e');
      return false;
    }
  }

  /// Giữ nguyên API cũ (hôm nay).
  Future<bool> checkInExpenseToday(String itemId, String status) async {
    return checkInExpense(DateTime.now(), itemId, status);
  }

  Future<bool> addUnexpectedExpense(double amount, String reason, {DateTime? date}) async {
    try {
      await _dioClient.dio.post(
        ApiEndpoints.unexpectedExpense,
        queryParameters: date != null ? {'date': date.toIso8601String().substring(0, 10)} : null,
        data: {
          'amount': amount,
          'reason': reason,
        },
      );
      return true;
    } catch (e) {
      debugPrint('[DailyCheckInService] Direct addUnexpectedExpense failed (offline mode): $e');
      return false;
    }
  }

  /// Sửa một khoản chi phát sinh đã ghi nhận (PUT /daily/unexpected-expense/:id).
  Future<bool> updateUnexpectedExpense(
      String expenseId, double amount, String reason, DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    try {
      await _dioClient.dio.put(
        '${ApiEndpoints.unexpectedExpense}/$expenseId',
        queryParameters: {'date': dateStr},
        data: {
          'amount': amount,
          'reason': reason,
        },
      );
      return true;
    } catch (e) {
      debugPrint('[DailyCheckInService] updateUnexpectedExpense failed (offline mode): $e');
      return false;
    }
  }

  /// Xóa một khoản chi phát sinh (DELETE /daily/unexpected-expense/:id).
  Future<bool> deleteUnexpectedExpense(String expenseId, DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    try {
      await _dioClient.dio.delete(
        '${ApiEndpoints.unexpectedExpense}/$expenseId',
        queryParameters: {'date': dateStr},
      );
      return true;
    } catch (e) {
      debugPrint('[DailyCheckInService] deleteUnexpectedExpense failed (offline mode): $e');
      return false;
    }
  }

  /// Sync all pending offline actions to backend
  Future<void> syncPendingActions() async {
    final actions = await _cacheService.getPendingActions();
    if (actions.isEmpty) return;

    debugPrint('[DailyCheckInService] Syncing ${actions.length} offline actions to backend...');
    final remainingActions = <Map<String, dynamic>>[];

    for (final action in actions) {
      bool success = false;
      try {
        if (action['type'] == 'check_in') {
          // Đính kèm date để hành động offline áp đúng cho ngày đã chọn (kể cả khi sync ở ngày khác).
          final res = await _dioClient.dio.patch(
            ApiEndpoints.checkInExpense,
            queryParameters: action['date'] != null ? {'date': action['date']} : null,
            data: {
              'itemId': action['itemId'],
              'status': action['status'],
            },
          );
          success = res.statusCode == 200 || res.statusCode == 201;
        } else if (action['type'] == 'unexpected_expense') {
          final res = await _dioClient.dio.post(
            ApiEndpoints.unexpectedExpense,
            queryParameters: action['date'] != null ? {'date': action['date']} : null,
            data: {
              'amount': action['amount'],
              'reason': action['reason'],
            },
          );
          success = res.statusCode == 200 || res.statusCode == 201;
        } else if (action['type'] == 'update_unexpected') {
          final res = await _dioClient.dio.put(
            '${ApiEndpoints.unexpectedExpense}/${action['expenseId']}',
            queryParameters: action['date'] != null ? {'date': action['date']} : null,
            data: {
              'amount': action['amount'],
              'reason': action['reason'],
            },
          );
          success = res.statusCode == 200 || res.statusCode == 201;
        } else if (action['type'] == 'delete_unexpected') {
          final res = await _dioClient.dio.delete(
            '${ApiEndpoints.unexpectedExpense}/${action['expenseId']}',
            queryParameters: action['date'] != null ? {'date': action['date']} : null,
          );
          success = res.statusCode == 200 || res.statusCode == 201;
        }
      } catch (err) {
        debugPrint('[DailyCheckInService] Sync action failed, keeping in queue: $err');
        success = false;
      }

      if (!success) {
        remainingActions.add(action);
      }
    }

    if (remainingActions.isEmpty) {
      await _cacheService.clearPendingActions();
      debugPrint('[DailyCheckInService] All offline actions synced successfully!');
    } else {
      // Update queue with remaining actions
      await _cacheService.clearPendingActions();
      for (final rem in remainingActions) {
        await _cacheService.addPendingAction(rem);
      }
      debugPrint('[DailyCheckInService] ${remainingActions.length} actions remaining in offline queue.');
    }
  }
}
