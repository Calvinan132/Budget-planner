import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../controllers/budget_plan_controller.dart';
import 'master_plan_input_screen.dart';

class PlanOverviewScreen extends ConsumerWidget {
  const PlanOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planState = ref.watch(budgetPlanControllerProvider);
    final plan = planState.plan;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.primaryDark),
          onPressed: () {},
        ),
        title: Text(
          'Financial Serenity',
          style: AppTextStyles.headingMedium(color: AppColors.primaryDark).copyWith(
            fontSize: 18,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100'),
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
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'KỊCH BẢN GỐC',
                    style: AppTextStyles.bodyMedium(color: AppColors.textMuted).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.formatVND(plan?.totalMonthlyBudget ?? 45000000),
                    style: AppTextStyles.headingLarge(color: AppColors.primaryDark).copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MasterPlanInputScreen()),
                      );
                    },
                    child: const Text('Adjust Plan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

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
            _buildExpenseGroupCard([
              _ExpenseDisplayItem(
                icon: Icons.restaurant_rounded,
                title: 'Ăn uống',
                subtitle: 'Food & Dining',
                amount: 300000,
                iconBg: const Color(0xFFD1FAE5),
                iconColor: AppColors.primaryDark,
              ),
              _ExpenseDisplayItem(
                icon: Icons.directions_bus_rounded,
                title: 'Di chuyển',
                subtitle: 'Transport',
                amount: 100000,
                iconBg: const Color(0xFFD1FAE5),
                iconColor: AppColors.primaryDark,
              ),
              _ExpenseDisplayItem(
                icon: Icons.local_cafe_rounded,
                title: 'Cà phê',
                subtitle: 'Coffee & Snacks',
                amount: 50000,
                iconBg: const Color(0xFFD1FAE5),
                iconColor: AppColors.primaryDark,
              ),
            ]),

            const SizedBox(height: 24),

            // Section 2: Khoản chi cố định tháng
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
            _buildExpenseGroupCard([
              _ExpenseDisplayItem(
                icon: Icons.home_rounded,
                title: 'Tiền thuê nhà',
                subtitle: 'Rent',
                amount: 8000000,
                iconBg: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFEF4444),
              ),
              _ExpenseDisplayItem(
                icon: Icons.flash_on_rounded,
                title: 'Điện & Nước',
                subtitle: 'Utilities',
                amount: 1500000,
                iconBg: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFEF4444),
              ),
              _ExpenseDisplayItem(
                icon: Icons.wifi_rounded,
                title: 'Internet',
                subtitle: 'Subscriptions',
                amount: 350000,
                iconBg: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFEF4444),
              ),
            ]),

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
