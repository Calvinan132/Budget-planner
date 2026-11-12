import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../models/budget_plan_model.dart';
import '../controllers/budget_plan_controller.dart';

class PlanOverviewScreen extends ConsumerWidget {
  const PlanOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planState = ref.watch(budgetPlanControllerProvider);
    final plan = planState.plan;
    final user = ref.watch(authControllerProvider).user;

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
          if (plan != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.primaryDark),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/setup',
                    arguments: plan,
                  );
                },
                tooltip: 'Chỉnh sửa kế hoạch',
              ),
            ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kế hoạch tổng thể',
              style: AppTextStyles.headingLarge(color: AppColors.textPrimary).copyWith(
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your budget overview for maintaining financial serenity.',
              style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            // Master Plan Card matching Stitch AI Image 2 (Left)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderLight, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'KẾ HOẠCH NGÂN SÁCH',
                    style: AppTextStyles.bodyMedium(color: AppColors.textMuted).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.formatVND(
                      (plan?.initialBudget != null && plan!.initialBudget > 0)
                          ? plan.initialBudget
                          : (plan?.totalMonthlyBudget ?? 0),
                    ),
                    style: AppTextStyles.headingLarge(color: AppColors.primaryDark).copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dự tính chi: ${CurrencyFormatter.formatVND(plan?.totalMonthlyBudget ?? 0)} • Mục tiêu tiết kiệm: ${CurrencyFormatter.formatVND(plan?.savedAmount ?? 0)}',
                    style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      minimumSize: const Size(140, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/setup',
                        arguments: plan,
                      );
                    },
                    child: const Text('Adjust Plan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Card Kịch bản tính theo số ngày còn lại trong tháng
            if (plan != null) ...[
              _buildRemainingDaysScenarioCard(context, plan),
              const SizedBox(height: 20),
            ],

            // Section 1: Khoản chi mỗi ngày
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Text(
                  'Khoản chi mỗi ngày',
                  style: AppTextStyles.headingSmall(color: AppColors.textPrimary).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (plan != null && plan.dailyRoutines.isNotEmpty)
              _buildExpenseGroupCard(
                plan.dailyRoutines.map((item) {
                  return _ExpenseDisplayItem(
                    icon: _getIconForName(item.name),
                    title: item.name,
                    subtitle: 'Mỗi ngày',
                    amount: item.amount,
                    iconBg: const Color(0xFFD1FAE5),
                    iconColor: AppColors.primaryDark,
                  );
                }).toList(),
              )
            else
              _buildEmptySection('Chưa có khoản chi mỗi ngày nào được thiết lập.'),

            // Section 2: Khoản chi hàng tuần
            if (plan != null && plan.weeklyRoutines.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.date_range_rounded, size: 20, color: AppColors.primaryDark),
                  const SizedBox(width: 8),
                  Text(
                    'Khoản chi hàng tuần',
                    style: AppTextStyles.headingSmall(color: AppColors.textPrimary).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildExpenseGroupCard(
                plan.weeklyRoutines.map((item) {
                  return _ExpenseDisplayItem(
                    icon: _getIconForName(item.name),
                    title: item.name,
                    subtitle: '${item.frequencyPerWeek} lần / tuần',
                    amount: item.amount,
                    iconBg: const Color(0xFFE0E7FF),
                    iconColor: const Color(0xFF4338CA),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            // Section 3: Khoản chi cố định tháng
            Row(
              children: [
                const Icon(Icons.account_balance_outlined, size: 20, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Text(
                  'Khoản chi cố định tháng',
                  style: AppTextStyles.headingSmall(color: AppColors.textPrimary).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (plan != null && plan.monthlyFixed.isNotEmpty)
              _buildExpenseGroupCard(
                plan.monthlyFixed.map((item) {
                  return _ExpenseDisplayItem(
                    icon: _getIconForName(item.name),
                    title: item.name,
                    subtitle: 'Cố định hàng tháng',
                    amount: item.amount,
                    iconBg: const Color(0xFFFEE2E2),
                    iconColor: const Color(0xFFEF4444),
                  );
                }).toList(),
              )
            else
              _buildEmptySection('Chưa có khoản chi cố định nào.'),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseGroupCard(List<_ExpenseDisplayItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 0.8),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: item.iconColor, size: 22),
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
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            item.subtitle,
                            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatVND(item.amount),
                      style: AppTextStyles.bodyLarge(color: AppColors.textPrimary).copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              if (idx < items.length - 1)
                const Divider(height: 1, color: AppColors.borderLight, indent: 70),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptySection(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 0.8),
      ),
      child: Center(
        child: Text(
          text,
          style: AppTextStyles.bodyMedium(color: AppColors.textMuted).copyWith(fontSize: 13),
        ),
      ),
    );
  }

  IconData _getIconForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ăn') || lower.contains('food') || lower.contains('cơm') || lower.contains('bánh')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('cà phê') || lower.contains('cafe') || lower.contains('coffee') || lower.contains('trà')) {
      return Icons.local_cafe_rounded;
    }
    if (lower.contains('xe') || lower.contains('xăng') || lower.contains('di chuyển') || lower.contains('bus')) {
      return Icons.directions_bus_rounded;
    }
    if (lower.contains('nhà') || lower.contains('thuê') || lower.contains('trọ') || lower.contains('rent')) {
      return Icons.home_rounded;
    }
    if (lower.contains('điện') || lower.contains('nước') || lower.contains('gas')) {
      return Icons.flash_on_rounded;
    }
    if (lower.contains('mạng') || lower.contains('net') || lower.contains('wifi')) {
      return Icons.wifi_rounded;
    }
    if (lower.contains('chợ') || lower.contains('siêu thị') || lower.contains('mua sắm')) {
      return Icons.shopping_cart_rounded;
    }
    return Icons.payments_outlined;
  }

  Widget _buildRemainingDaysScenarioCard(BuildContext context, BudgetPlanModel plan) {
    final now = DateTime.now();
    final remainingDays = DateHelper.getRemainingDaysInMonth(now);
    final totalDaysInMonth = DateHelper.getDaysInMonth(now.year, now.month);
    final passedDays = totalDaysInMonth - remainingDays;

    final effectiveBudget = plan.initialBudget > 0 ? plan.initialBudget : plan.totalMonthlyBudget;
    final dailyBudget = effectiveBudget / totalDaysInMonth;
    final dailyPlanned = plan.totalDailyPerDay;
    final plannedForRemainingDays = plan.calculatePlannedForDays(remainingDays, includeFixed: false);
    final savingsPerDay = (dailyBudget - dailyPlanned).clamp(0.0, double.infinity);
    final remainingSavingsPotential = savingsPerDay * remainingDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.hourglass_top_rounded, size: 18, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Phân bổ ngày còn lại',
                    style: AppTextStyles.headingSmall(color: AppColors.primaryDark).copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Text(
                  'Còn $remainingDays / $totalDaysInMonth ngày',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (passedDays / totalDaysInMonth).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Hạn mức mỗi ngày',
                  value: '${CurrencyFormatter.formatShort(dailyBudget)}/ngày',
                  subtitle: 'Tính trên ngân sách',
                  icon: Icons.payments_outlined,
                  color: const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  title: 'Kế hoạch chi ngày',
                  value: '${CurrencyFormatter.formatShort(dailyPlanned)}/ngày',
                  subtitle: '${plan.dailyRoutines.length} khoản chi/ngày',
                  icon: Icons.shopping_bag_outlined,
                  color: const Color(0xFFD97706),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Dự chi $remainingDays ngày tới',
                  value: CurrencyFormatter.formatShort(plannedForRemainingDays),
                  subtitle: 'Khoản ngày & tuần',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  title: 'Tiết kiệm thêm dự kiến',
                  value: '+${CurrencyFormatter.formatShort(remainingSavingsPotential)}',
                  subtitle: 'Vào heo nếu đúng hạn',
                  icon: Icons.savings_outlined,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ExpenseDisplayItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final double amount;
  final Color iconBg;
  final Color iconColor;

  _ExpenseDisplayItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.iconBg,
    required this.iconColor,
  });
}
