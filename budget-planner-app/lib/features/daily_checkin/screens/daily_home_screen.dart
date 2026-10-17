import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../budget_setup/screens/plan_overview_screen.dart';
import '../../reports/screens/monthly_report_screen.dart';
import '../controllers/daily_checkin_controller.dart';
import '../widgets/expandable_expense_card.dart';
import '../widgets/unexpected_expense_sheet.dart';
import '../../profile/screens/profile_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DailyHomeScreen(),
    PlanOverviewScreen(),
    MonthlyReportScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded, color: AppColors.primaryDark),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryDark),
              label: 'Budget',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline_rounded),
              activeIcon: Icon(Icons.pie_chart_rounded, color: AppColors.primaryDark),
              label: 'Goals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded, color: AppColors.primaryDark),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class DailyHomeScreen extends ConsumerWidget {
  const DailyHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(dailyCheckInControllerProvider);

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
              backgroundColor: Color(0xFFE5E7EB),
              child: Icon(Icons.person_rounded, size: 20, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      body: homeState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Piggy Bank Header Card matching Stitch AI Image 2 (Middle)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8F8F0), Color(0xFFD1FAE5)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Quỹ heo đất tiết kiệm tháng này:',
                          style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '+${CurrencyFormatter.formatVND(homeState.piggyBankSavings)}',
                          style: AppTextStyles.headingLarge(color: AppColors.primaryDark).copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Green progress bar matching Stitch AI
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (homeState.piggyBankSavings / homeState.savingsGoal).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.6),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Mục tiêu: ${CurrencyFormatter.formatShort(homeState.savingsGoal)}',
                            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Danh sách chi tiêu hôm nay',
                    style: AppTextStyles.headingSmall(color: AppColors.textPrimary).copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (homeState.expenses.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.successGreen),
                          const SizedBox(height: 12),
                          Text(
                            'Tốt lắm! Bạn đã hoàn thành điểm danh các khoản chi hôm nay.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: homeState.expenses.length,
                      itemBuilder: (context, index) {
                        final expense = homeState.expenses[index];
                        return ExpandableExpenseCard(
                          key: ValueKey(expense.id),
                          expense: expense,
                          onAction: (status) async {
                            final success = await ref
                                .read(dailyCheckInControllerProvider.notifier)
                                .processCheckIn(itemId: expense.id, status: status);
                            
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lỗi: Không thể lưu thay đổi, hệ thống đã hoàn tác.'),
                                  backgroundColor: AppColors.warningRed,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),

                  const SizedBox(height: 80), // Padding for FAB
                ],
              ),
            ),

      // Solid Emerald Green FAB [+] matching Stitch AI Image 2 (Middle)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const UnexpectedExpenseSheet(),
          );
        },
        backgroundColor: AppColors.primaryDark,
        child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
      ),
    );
  }
}

