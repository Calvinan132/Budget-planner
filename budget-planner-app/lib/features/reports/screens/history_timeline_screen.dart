import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helper.dart';
import '../controllers/report_controller.dart';

class HistoryTimelineScreen extends ConsumerWidget {
  const HistoryTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      ),
      body: historyList.isEmpty
          ? Center(
              child: Text(
                'Chưa có dữ liệu lịch sử cho tháng này.',
                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
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
    );
  }
}
