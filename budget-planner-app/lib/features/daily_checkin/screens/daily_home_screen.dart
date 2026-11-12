import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../budget_setup/screens/plan_overview_screen.dart';
import '../../reports/screens/monthly_report_screen.dart';
import '../../reports/screens/history_timeline_screen.dart';
import '../controllers/daily_checkin_controller.dart';
import '../widgets/expandable_expense_card.dart';
import '../widgets/unexpected_expense_sheet.dart';
import '../widgets/piggy_bank_card.dart';
import '../widgets/remaining_days_budget_card.dart';
import '../widgets/daily_checkin_header.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../budget_setup/controllers/budget_plan_controller.dart';
import '../../reports/controllers/report_controller.dart';
import '../../profile/screens/profile_screen.dart';

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key});

  static const List<Widget> _screens = [
    DailyHomeScreen(),
    PlanOverviewScreen(),
    MonthlyReportScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainNavIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            ref.read(mainNavIndexProvider.notifier).state = index;
            final now = DateTime.now();
            if (index == 0) {
              ref.read(dailyCheckInControllerProvider.notifier).loadTodayData();
            } else if (index == 1) {
              ref.read(budgetPlanControllerProvider.notifier).fetchCurrentPlan();
            } else if (index == 2) {
              ref.read(monthlyReportControllerProvider.notifier).loadReport(now.month, now.year);
            }
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

class DailyHomeScreen extends ConsumerStatefulWidget {
  const DailyHomeScreen({super.key});

  @override
  ConsumerState<DailyHomeScreen> createState() => _DailyHomeScreenState();
}

class _DailyHomeScreenState extends ConsumerState<DailyHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(dailyCheckInControllerProvider);
    final user = ref.watch(authControllerProvider).user;
    final pendingExpenses = homeState.expenses.where((e) => e.status == 'pending').toList();
    final doneCount = homeState.expenses.where((e) => e.status != 'pending').length;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.scaffoldBackground,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.primaryDark),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'Financial Serenity',
          style: AppTextStyles.headingMedium(color: AppColors.primaryDark).copyWith(
            fontSize: 18,
          ),
        ),
        actions: [
          if (homeState.isSyncing)
            const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                ),
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
      body: homeState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primaryDark,
              onRefresh: () => ref.read(dailyCheckInControllerProvider.notifier).syncOfflineData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bộ chọn ngày xem lịch sử chi tiêu
                    DailyCheckInHeader(
                      selectedDate: homeState.selectedDate,
                      onSelectDate: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: homeState.selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null && context.mounted) {
                          await ref
                              .read(dailyCheckInControllerProvider.notifier)
                              .setSelectedDate(picked);
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Piggy Bank Header Card
                    PiggyBankCard(
                      currentSavings: homeState.piggyBankSavings,
                      savingsGoal: homeState.savingsGoal,
                    ),

                    const SizedBox(height: 14),

                    // Badge thông tin số ngày còn lại & hạn mức TB mỗi ngày
                    Builder(
                      builder: (context) {
                        final now = DateTime.now();
                        final remainingDays = DateHelper.getRemainingDaysInMonth(now);
                        final plan = ref.watch(budgetPlanControllerProvider).plan;
                        final totalBudget = plan != null && plan.initialBudget > 0
                            ? plan.initialBudget
                            : homeState.savingsGoal;
                        final dailyBudget = remainingDays > 0 && totalBudget > 0
                            ? (totalBudget / remainingDays)
                            : 0.0;

                        return RemainingDaysBudgetCard(
                          remainingDays: remainingDays,
                          dailyBudget: dailyBudget,
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateHelper.isSameDay(homeState.selectedDate, DateTime.now())
                              ? 'Danh sách chi tiêu hôm nay'
                              : 'Danh sách chi tiêu ${DateHelper.formatShortDay(homeState.selectedDate)}',
                          style: AppTextStyles.headingSmall(color: AppColors.textPrimary).copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (homeState.expenses.any((e) => e.status == 'pending'))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${homeState.expenses.where((e) => e.status == "pending").length} khoản còn lại',
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (pendingExpenses.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              const Color(0xFFF0FDF4).withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFDCFCE7),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.celebration_rounded,
                                  size: 38,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Tuyệt vời! 🎉',
                              style: AppTextStyles.headingLarge(color: AppColors.primaryDark).copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bạn đã hoàn thành tất cả chi tiêu hôm nay',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyLarge(color: AppColors.textPrimary).copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Mọi khoản "Không tiêu" đã được cộng dồn an toàn vào Heo đất. Xem lại các mục đã chọn trong mục "Lịch sử chi tiêu" ở thanh bên.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.primaryDark),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const HistoryTimelineScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.history_rounded, size: 18, color: AppColors.primaryDark),
                                  label: Text(
                                    'Xem lịch sử ($doneCount đã chọn)',
                                    style: AppTextStyles.bodyMedium(color: AppColors.primaryDark).copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.textMuted),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => const UnexpectedExpenseSheet(),
                                );
                              },
                              icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.textPrimary),
                              label: Text(
                                'Có chi phí phát sinh?',
                                style: AppTextStyles.bodyMedium(color: AppColors.textPrimary).copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pendingExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = pendingExpenses[index];
                          return ExpandableExpenseCard(
                            key: ValueKey(expense.id),
                            expense: expense,
                            onStatusChange: (status) async {
                              final success = await ref
                                  .read(dailyCheckInControllerProvider.notifier)
                                  .processCheckIn(
                                      date: homeState.selectedDate,
                                      itemId: expense.id,
                                      status: status);
                              
                              if (!success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Lỗi: Không thể lưu thay đổi, hệ thống đã hoàn tác.'),
                                    backgroundColor: AppColors.warningRed,
                                  ),
                                );
                              }
                            },
                            onEdit: expense.isUnexpected
                                ? () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => UnexpectedExpenseSheet(editingExpense: expense),
                                    );
                                  }
                                : null,
                            onDelete: expense.isUnexpected
                                ? () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        title: const Text('Xóa khoản chi phát sinh?'),
                                        content: Text(
                                          'Bạn chắc chắn muốn xóa "${expense.name}" (${CurrencyFormatter.formatVND(expense.amount)})?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Hủy'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text(
                                              'Xóa',
                                              style: TextStyle(color: AppColors.warningRed),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true && context.mounted) {
                                      await ref
                                          .read(dailyCheckInControllerProvider.notifier)
                                          .deleteUnexpectedExpense(expense.id);
                                    }
                                  }
                                : null,
                          );
                        },
                      ),

                    const SizedBox(height: 80), // Padding for FAB
                  ],
                ),
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

