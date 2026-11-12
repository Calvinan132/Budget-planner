import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/daily_expense_model.dart';
import '../../../models/budget_plan_model.dart';

class OfflineCacheService {
  static const String _keyDailyExpenses = 'offline_daily_expenses';
  static const String _keyPiggySavings = 'offline_piggy_savings';
  static const String _keySavingsGoal = 'offline_savings_goal';
  static const String _keyDailyDate = 'offline_daily_date';
  static const String _keyCurrentPlan = 'offline_current_plan';
  static const String _keyPendingActions = 'offline_pending_actions';

  static final OfflineCacheService _instance = OfflineCacheService._internal();
  factory OfflineCacheService() => _instance;
  OfflineCacheService._internal();

  /// Cache today's expenses and balance
  Future<void> cacheTodayData({
    required List<DailyExpenseModel> expenses,
    required double piggyBankSavings,
    required double savingsGoal,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expensesJson = jsonEncode(expenses.map((e) => e.toJson()).toList());
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      await prefs.setString(_keyDailyExpenses, expensesJson);
      await prefs.setDouble(_keyPiggySavings, piggyBankSavings);
      await prefs.setDouble(_keySavingsGoal, savingsGoal);
      await prefs.setString(_keyDailyDate, todayStr);
    } catch (e) {
      debugPrint('[OfflineCacheService] cacheTodayData error: $e');
    }
  }

  /// Retrieve cached today data if available
  Future<DailyHomeData?> getCachedTodayData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDate = prefs.getString(_keyDailyDate);
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      // Only return if cache is from today
      if (cachedDate != todayStr) {
        return null;
      }

      final expensesJson = prefs.getString(_keyDailyExpenses);
      final piggySavings = prefs.getDouble(_keyPiggySavings) ?? 240000;
      final savingsGoal = prefs.getDouble(_keySavingsGoal) ?? 500000;

      if (expensesJson == null) return null;

      final List<dynamic> list = jsonDecode(expensesJson);
      final expenses = list.map((e) => DailyExpenseModel.fromJson(e as Map<String, dynamic>)).toList();

      return DailyHomeData(
        piggyBankSavings: piggySavings,
        savingsGoal: savingsGoal,
        expenses: expenses,
      );
    } catch (e) {
      debugPrint('[OfflineCacheService] getCachedTodayData error: $e');
      return null;
    }
  }

  /// Cache master budget plan
  Future<void> cacheCurrentPlan(BudgetPlanModel plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCurrentPlan, jsonEncode(plan.toJson()));
    } catch (e) {
      debugPrint('[OfflineCacheService] cacheCurrentPlan error: $e');
    }
  }

  /// Retrieve cached master budget plan
  Future<BudgetPlanModel?> getCachedCurrentPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final planJson = prefs.getString(_keyCurrentPlan);
      if (planJson == null) return null;
      return BudgetPlanModel.fromJson(jsonDecode(planJson));
    } catch (e) {
      debugPrint('[OfflineCacheService] getCachedCurrentPlan error: $e');
      return null;
    }
  }

  /// Enqueue an action to be synchronized when back online
  Future<void> addPendingAction(Map<String, dynamic> action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actions = await getPendingActions();
      action['createdAt'] = DateTime.now().toIso8601String();
      actions.add(action);
      await prefs.setString(_keyPendingActions, jsonEncode(actions));
      debugPrint('[OfflineCacheService] Enqueued offline action: ${action['type']} (Total: ${actions.length})');
    } catch (e) {
      debugPrint('[OfflineCacheService] addPendingAction error: $e');
    }
  }

  /// Get all pending offline actions
  Future<List<Map<String, dynamic>>> getPendingActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actionsJson = prefs.getString(_keyPendingActions);
      if (actionsJson == null) return [];
      final List<dynamic> list = jsonDecode(actionsJson);
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear pending offline actions
  Future<void> clearPendingActions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPendingActions);
  }

  /// Check if there are pending actions
  Future<bool> hasPendingActions() async {
    final actions = await getPendingActions();
    return actions.isNotEmpty;
  }
}
