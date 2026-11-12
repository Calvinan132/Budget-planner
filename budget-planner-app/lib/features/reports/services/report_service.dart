import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/daily_expense_model.dart';
import '../../../models/report_model.dart';

/// Service báo cáo — gọi API thật, KHÔNG giả lập mock khi lỗi mạng.
/// Lỗi sẽ được đẩy lên controller để hiển thị trạng thái lỗi cho người dùng.
class ReportService {
  final DioClient _dioClient;

  ReportService(this._dioClient);

  Future<MonthlyReportModel> getMonthlyReport(int month, int year) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.monthlyReport,
      queryParameters: {'month': month, 'year': year},
    );
    return MonthlyReportModel.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }

  /// Backend trả về { month, year, daysCount, logs: DailyLog[] } — cần bung
  /// mỗi DailyLog thành danh sách chi tiêu phẳng theo ngày.
  Future<List<DailyExpenseModel>> getHistoryTimeline(int month, int year) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.historyReport,
      queryParameters: {'month': month, 'year': year},
    );

    final dynamic data = response.data['data'];
    final List<dynamic> logs = data is Map && data['logs'] is List
        ? data['logs'] as List<dynamic>
        : (data is List ? data : const <dynamic>[]);

    final list = <DailyExpenseModel>[];
    for (final log in logs) {
      final logMap = Map<String, dynamic>.from(log as Map);
      final DateTime logDate = DateTime.tryParse('${logMap['date']}') ?? DateTime.now();

      for (final item in (logMap['items'] as List<dynamic>? ?? const <dynamic>[])) {
        final m = Map<String, dynamic>.from(item as Map);
        list.add(DailyExpenseModel(
          id: (m['id'] ?? '') as String,
          name: (m['name'] ?? '') as String,
          amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
          category: m['category'] as String? ?? 'general',
          status: m['status'] as String? ?? 'pending',
          date: logDate,
        ));
      }

      for (final exp in (logMap['unexpectedExpenses'] as List<dynamic>? ?? const <dynamic>[])) {
        final m = Map<String, dynamic>.from(exp as Map);
        list.add(DailyExpenseModel(
          id: (m['id'] ?? '') as String,
          name: (m['reason'] ?? 'Phát sinh') as String,
          amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
          category: 'unexpected',
          status: 'completed',
          isUnexpected: true,
          date: logDate,
        ));
      }
    }

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}
