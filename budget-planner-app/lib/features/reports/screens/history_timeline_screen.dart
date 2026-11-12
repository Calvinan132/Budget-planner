import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helper.dart';
import '../controllers/report_controller.dart';

class HistoryTimelineScreen extends ConsumerStatefulWidget {
  const HistoryTimelineScreen({super.key});

  @override
  ConsumerState<HistoryTimelineScreen> createState() => _HistoryTimelineScreenState();
}

class _HistoryTimelineScreenState extends ConsumerState<HistoryTimelineScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(monthlyReportControllerProvider.notifier)
          .loadReport(_selectedMonth.month, _selectedMonth.year);
    });
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
      ref
          .read(monthlyReportControllerProvider.notifier)
          .loadReport(_selectedMonth.month, _selectedMonth.year);
    }
  }

  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primaryDark),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
              ref
                  .read(monthlyReportControllerProvider.notifier)
                  .loadReport(_selectedMonth.month, _selectedMonth.year);
            },
            tooltip: 'Tháng trước',
          ),
          InkWell(
            onTap: _pickMonth,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryDark),
                  const SizedBox(width: 8),
                  Text(
                    'Tháng ${_selectedMonth.month}/${_selectedMonth.year}',
                    style: AppTextStyles.headingSmall(color: AppColors.primaryDark).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: isCurrentMonth ? AppColors.textMuted : AppColors.primaryDark,
            ),
            onPressed: isCurrentMonth
                ? null
                : () {
                    setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                    });
                    ref
                        .read(monthlyReportControllerProvider.notifier)
                        .loadReport(_selectedMonth.month, _selectedMonth.year);
                  },
            tooltip: 'Tháng sau',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(monthlyReportControllerProvider);
    final historyList = reportState.history;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Lịch sử chi tiêu',
          style: AppTextStyles.headingMedium(color: AppColors.textPrimary).copyWith(
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: AppColors.primaryDark),
            onPressed: _pickMonth,
            tooltip: 'Chọn tháng',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryDark,
              onRefresh: () async {
                await ref
                    .read(monthlyReportControllerProvider.notifier)
                    .loadReport(_selectedMonth.month, _selectedMonth.year);
              },
              child: reportState.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : historyList.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Text(
                                'Chưa có dữ liệu lịch sử cho Tháng ${_selectedMonth.month}/${_selectedMonth.year}.',
                                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          itemCount: historyList.length,
              itemBuilder: (context, index) {
                final item = historyList[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderLight, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        // Status Badge
                        if (item.isUnexpected)
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFEDD5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_circle_outline_rounded, color: AppColors.orangeTag, size: 20),
                          )
                        else if (item.isSkipped)
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.textMuted, size: 20),
                          )
                        else
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD1FAE5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryDark, size: 20),
                          ),
                        const SizedBox(width: 14),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: AppTextStyles.bodyLarge(color: AppColors.textPrimary).copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: item.isSkipped ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${DateHelper.formatShortDay(item.date)} • ${item.isUnexpected ? "Phát sinh" : (item.isSkipped ? "Đã bỏ qua" : "Đã tiêu")}',
                                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Amount
                        Text(
                          CurrencyFormatter.formatVND(item.amount),
                          style: AppTextStyles.bodyLarge(
                            color: item.isSkipped ? AppColors.textMuted : AppColors.textPrimary,
                          ).copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: item.isSkipped ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}
}
