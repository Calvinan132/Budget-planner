import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/offline_cache_service.dart';
import '../../../models/budget_plan_model.dart';

class BudgetPlanService {
  final DioClient _dioClient;
  final OfflineCacheService _cacheService = OfflineCacheService();

  BudgetPlanService(this._dioClient);

  Future<BudgetPlanModel> createPlan(BudgetPlanModel plan) async {
    try {
      // Backend yêu cầu month + year để tạo doc {uid}_{year}_{month} trong monthly_plans.
      // Gửi kèm tháng/năm hiện tại (giờ Việt Nam) để plan được lưu lên Firestore
      // thay vì bị từ chối validation và chỉ lưu cache cục bộ.
      final now = DateTime.now();
      final startDay = now.day;
      final daysInMonth = DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 1),
      ).duration.inDays;
      final activeDays = daysInMonth - startDay + 1;

      final response = await _dioClient.dio.post(
        ApiEndpoints.createPlan,
        data: {
          'month': now.month,
          'year': now.year,
          'startDay': startDay,
          'activeDays': activeDays,
          'totalPlanned': plan.totalPlanned, // Gửi lên totalPlanned đã tính đúng theo ngày còn lại
          ...plan.toJson(),
        },
      );
      final saved = BudgetPlanModel.fromJson(response.data['data']);
      await _cacheService.cacheCurrentPlan(saved);
      return saved;
    } catch (e) {
      debugPrint('[BudgetPlanService] Network create plan failed, saving to local cache: $e');
      await _cacheService.cacheCurrentPlan(plan);
      return plan;
    }
  }

  Future<BudgetPlanModel?> getCurrentPlan() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.currentPlan);
      if (response.data != null && response.data['data'] != null) {
        final plan = BudgetPlanModel.fromJson(response.data['data']);
        await _cacheService.cacheCurrentPlan(plan);
        return plan;
      }
      return null;
    } on DioException catch (dioErr) {
      if (dioErr.response?.statusCode == 404) {
        // Backend confirms: No plan exists for the current month!
        debugPrint('[BudgetPlanService] No active plan found for this month (404).');
        return null;
      }
      // If network unreachable, check if we have a cached plan for this month
      debugPrint('[BudgetPlanService] DioException checking cache: $dioErr');
      return await _cacheService.getCachedCurrentPlan();
    } catch (e) {
      debugPrint('[BudgetPlanService] Error fetching plan, checking offline cache: $e');
      return await _cacheService.getCachedCurrentPlan();
    }
  }

  Future<BudgetPlanModel> updateCurrentPlan(BudgetPlanModel plan) async {
    try {
      final now = DateTime.now();
      final startDay = now.day;
      final daysInMonth = DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 1),
      ).duration.inDays;
      final activeDays = daysInMonth - startDay + 1;

      final response = await _dioClient.dio.put(
        ApiEndpoints.currentPlan,
        data: {
          'startDay': startDay,
          'activeDays': activeDays,
          'totalPlanned': plan.totalPlanned,
          ...plan.toJson(),
        },
      );
      final updated = BudgetPlanModel.fromJson(response.data['data']);
      await _cacheService.cacheCurrentPlan(updated);
      return updated;
    } catch (e) {
      await _cacheService.cacheCurrentPlan(plan);
      return plan;
    }
  }
}
