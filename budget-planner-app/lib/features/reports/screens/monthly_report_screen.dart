import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/report_controller.dart';
import 'history_timeline_screen.dart';

class MonthlyReportScreen extends ConsumerWidget {
  const MonthlyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(monthlyReportControllerProvider);
    final report = reportState.report;
    final user = ref.watch(authControllerProvider).user;

    final isExceeded = (report?.spendingPercentage ?? 0) > 100;
    final progressColor = isExceeded ? AppColors.warningRed : AppColors.primaryDark;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            if (Navigator.canPop(context)) {
              return IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryDark),
                onPressed: () => Navigator.pop(context),
              );
            }
            return IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.primaryDark),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Text(
          'Financial Serenity',
          style: AppTextStyles.headingMedium(color: AppColors.primaryDark).copyWith(
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: UserAvatar(
              radius: 18,
              photoUrl: user?.photoUrl,
              displayName: user?.displayName,
            ),
          ),
        ],
      ),
      body: reportState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primaryDark,
              onRefresh: () async {
                final now = DateTime.now();
                await ref
                    .read(monthlyReportControllerProvider.notifier)
                    .loadReport(now.month, now.year);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Báo cáo cuối tháng',
                            style: AppTextStyles.headingLarge(color: AppColors.textPrimary).copyWith(
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tháng ${report?.month ?? DateTime.now().month}, ${report?.year ?? DateTime.now().year}',
                            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.history_rounded, color: AppColors.primaryDark),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HistoryTimelineScreen()),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Báo lỗi tải báo cáo (không còn hiển thị dữ liệu giả lập khi lỗi mạng)
                  if (reportState.errorMessage != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off_rounded, color: AppColors.warningRed, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Không thể tải báo cáo từ máy chủ. Vui lòng kiểm tra kết nối và thử lại.',
                              style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Spending progress bar card matching Stitch AI Image 3
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderLight, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isExceeded ? 'Vượt mức ngân sách' : 'Tiết kiệm / Trong tầm kiểm soát',
                              style: AppTextStyles.bodyMedium(color: isExceeded ? AppColors.warningRed : AppColors.textPrimary).copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${report?.spendingPercentage.toInt() ?? 0}%',
                              style: AppTextStyles.headingMedium(color: progressColor).copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: ((report?.spendingPercentage ?? 0) / 100).clamp(0.0, 1.0),
                            minHeight: 12,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2 Metric Grid Cards matching Stitch AI Image 3
                  Row(
                    children: [
                      // Card 1: Ngân sách gốc
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderLight, width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8F5E9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.account_balance_outlined,
                                  color: AppColors.primaryDark,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Ngân sách gốc',
                                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.formatShort(report?.originalBudget ?? 0),
                                style: AppTextStyles.headingMedium(color: AppColors.textPrimary).copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Card 2: Thực tế đã chi
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderLight, width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEE2E2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: AppColors.warningRed,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Thực tế đã chi',
                                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.formatShort(report?.actualSpent ?? 0),
                                style: AppTextStyles.headingMedium(color: AppColors.textPrimary).copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Large Emerald Savings Banner Card matching Stitch AI Image 3
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tiết kiệm thành công',
                              style: AppTextStyles.bodyMedium(color: Colors.white70).copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.formatShort(report?.savedAmount ?? 0),
                              style: AppTextStyles.headingLarge(color: Colors.white).copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),

                        // Piggy bank badge icon
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.savings_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Behavioral Journal Section matching Stitch AI Image 3
                  Text(
                    'Nhật ký hành vi',
                    style: AppTextStyles.headingSmall(color: AppColors.textPrimary).copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (report != null && report.behaviorLogs.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderLight, width: 0.8),
                      ),
                      child: Column(
                        children: report.behaviorLogs.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE8F5E9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getBehaviorIcon(item.iconType),
                                        color: AppColors.primaryDark,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: AppTextStyles.bodyLarge(color: AppColors.textPrimary).copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.subtitle,
                                            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (idx < report.behaviorLogs.length - 1)
                                const Divider(height: 1, color: AppColors.borderLight, indent: 56),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Soft Mint Tip Card matching Stitch AI Image 3
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F0),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.eco_rounded, color: AppColors.primaryDark, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Bạn đang làm rất tốt! Hãy duy trì nhịp độ này cho tháng sau.',
                            style: AppTextStyles.bodyMedium(color: AppColors.primaryDark).copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
    );
  }

  IconData _getBehaviorIcon(String type) {
    switch (type.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'coffee':
        return Icons.local_cafe_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      default:
        return Icons.insights_rounded;
    }
  }
}
