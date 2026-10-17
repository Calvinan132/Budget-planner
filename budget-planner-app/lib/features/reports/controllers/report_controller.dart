import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/daily_expense_model.dart';
import '../../../models/report_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../services/report_service.dart';

final reportServiceProvider = Provider<ReportService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ReportService(dioClient);
});

class MonthlyReportState {
  final MonthlyReportModel? report;
  final List<DailyExpenseModel> history;
  final bool isLoading;
  final String? errorMessage;

  MonthlyReportState({
    this.report,
    this.history = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  MonthlyReportState copyWith({
    MonthlyReportModel? report,
    List<DailyExpenseModel>? history,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MonthlyReportState(
      report: report ?? this.report,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class MonthlyReportController extends StateNotifier<MonthlyReportState> {
  final ReportService _service;

  MonthlyReportController(this._service) : super(MonthlyReportState()) {
    final now = DateTime.now();
    loadReport(now.month, now.year);
  }

  Future<void> loadReport(int month, int year) async {
    state = state.copyWith(isLoading: true);
    try {
      final report = await _service.getMonthlyReport(month, year);
      final history = await _service.getHistoryTimeline(month, year);
      state = state.copyWith(
        report: report,
        history: history,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final monthlyReportControllerProvider =
    StateNotifierProvider<MonthlyReportController, MonthlyReportState>((ref) {
  final service = ref.watch(reportServiceProvider);
  return MonthlyReportController(service);
});
