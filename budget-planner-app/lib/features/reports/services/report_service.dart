import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/daily_expense_model.dart';
import '../../../models/report_model.dart';

class ReportService {
  final DioClient _dioClient;

  ReportService(this._dioClient);

  Future<MonthlyReportModel> getMonthlyReport(int month, int year) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.monthlyReport,
        queryParameters: {'month': month, 'year': year},
      );
      return MonthlyReportModel.fromJson(response.data['data']);
    } catch (e) {
      return MonthlyReportModel(
        month: month,
        year: year,
        originalBudget: 6000000,
        actualSpent: 5400000,
        savedAmount: 600000,
        spendingPercentage: 90.0,
        skippedCount: 5,
        behaviorLogs: [
          BehaviorLogItem(
            title: 'Bỏ qua 5 cốc cà phê',
            subtitle: '+175.000đ gửi heo đất',
            iconType: 'coffee',
          ),
          BehaviorLogItem(
            title: 'Nấu ăn tại nhà 12 bữa',
            subtitle: '+420.000đ tiết kiệm',
            iconType: 'food',
          ),
        ],
      );
    }
  }

  Future<List<DailyExpenseModel>> getHistoryTimeline(int month, int year) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.historyReport,
        queryParameters: {'month': month, 'year': year},
      );
      final list = (response.data['data'] as List<dynamic>?)
              ?.map((e) => DailyExpenseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return list;
    } catch (e) {
      final now = DateTime.now();
      return [
        DailyExpenseModel(
          id: '1',
          name: 'Ăn sáng',
          amount: 25000,
          category: 'food',
          status: 'completed',
          date: now.subtract(const Duration(hours: 4)),
        ),
        DailyExpenseModel(
          id: '2',
          name: 'Cà phê',
          amount: 35000,
          category: 'coffee',
          status: 'skipped',
          date: now.subtract(const Duration(hours: 6)),
        ),
        DailyExpenseModel(
          id: '3',
          name: 'Sửa xe phát sinh',
          amount: 150000,
          category: 'unexpected',
          status: 'completed',
          isUnexpected: true,
          date: now.subtract(const Duration(days: 1)),
        ),
      ];
    }
  }
}
