import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../utils/currency_formatter.dart';
import '../widgets/user_avatar.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/budget_setup/controllers/budget_plan_controller.dart';
import '../../features/daily_checkin/controllers/daily_checkin_controller.dart';
import '../../features/reports/controllers/report_controller.dart';
import '../../features/reports/screens/history_timeline_screen.dart';

/// Provider lưu tab index hiện tại của MainShellScreen
final mainNavIndexProvider = StateProvider<int>((ref) => 0);

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primaryDark, size: 22),
      title: Text(
        label,
        style: AppTextStyles.bodyMedium(
          color: textColor ?? AppColors.textPrimary,
        ).copyWith(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: onTap,
    );
  }

  void _navigateToTab(BuildContext context, WidgetRef ref, int targetIndex) {
    Navigator.pop(context); // Đóng drawer

    // Nếu màn hình hiện tại đang được push từ navigator (canPop)
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    ref.read(mainNavIndexProvider.notifier).state = targetIndex;

    // Refresh dữ liệu tương ứng
    final now = DateTime.now();
    if (targetIndex == 0) {
      ref.read(dailyCheckInControllerProvider.notifier).loadTodayData();
    } else if (targetIndex == 1) {
      ref.read(budgetPlanControllerProvider.notifier).fetchCurrentPlan();
    } else if (targetIndex == 2) {
      ref.read(monthlyReportControllerProvider.notifier).loadReport(now.month, now.year);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final planState = ref.watch(dailyCheckInControllerProvider);
    final now = DateTime.now();

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header with user info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE8F8F0), Color(0xFFD1FAE5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(
                    radius: 30,
                    photoUrl: user?.photoUrl,
                    displayName: user?.displayName,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'Người dùng',
                    style: AppTextStyles.headingSmall(color: AppColors.primaryDark).copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Heo đất: ${CurrencyFormatter.formatShort(planState.piggyBankSavings)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Navigation items
            _buildDrawerItem(
              context,
              icon: Icons.home_rounded,
              label: 'Trang chủ',
              onTap: () => _navigateToTab(context, ref, 0),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.history_rounded,
              label: 'Lịch sử chi tiêu',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryTimelineScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.calendar_month_rounded,
              label: 'Chọn ngày xem chi tiết',
              onTap: () async {
                Navigator.pop(context);
                final picked = await showDatePicker(
                  context: context,
                  initialDate: now,
                  firstDate: DateTime(2020),
                  lastDate: now,
                );
                if (picked != null && context.mounted) {
                  _navigateToTab(context, ref, 0);
                  await ref
                      .read(dailyCheckInControllerProvider.notifier)
                      .setSelectedDate(picked);
                }
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.account_balance_wallet_rounded,
              label: 'Kế hoạch ngân sách',
              onTap: () => _navigateToTab(context, ref, 1),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.bar_chart_rounded,
              label: 'Báo cáo tháng',
              onTap: () => _navigateToTab(context, ref, 2),
            ),

            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 8),

            _buildDrawerItem(
              context,
              icon: Icons.person_outline_rounded,
              label: 'Hồ sơ cá nhân',
              onTap: () => _navigateToTab(context, ref, 3),
            ),

            const Spacer(),

            // Logout
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Đăng xuất', style: AppTextStyles.headingSmall()),
                      content: Text('Bạn có chắc muốn đăng xuất?', style: AppTextStyles.bodyMedium()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hủy'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.warningRed),
                          child: const Text('Đăng xuất'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    Navigator.pop(context); // close drawer
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                    }
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, color: AppColors.warningRed, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Đăng xuất',
                        style: AppTextStyles.button(color: AppColors.warningRed).copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
