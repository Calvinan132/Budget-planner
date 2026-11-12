import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../auth/controllers/auth_controller.dart';

final fcmReminderEnabledProvider = StateProvider<bool>((ref) => true);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Đăng xuất', style: AppTextStyles.headingSmall()),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất không?',
          style: AppTextStyles.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Hủy',
              style: AppTextStyles.button(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warningRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Đăng xuất', style: AppTextStyles.button()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      await ref.read(authControllerProvider.notifier).signOut();
      
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();
      // Navigate to welcome/login screen
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    final currentTheme = ref.watch(themeModeProvider);
    final themeLabel = currentTheme == ThemeMode.light
        ? 'Sáng'
        : currentTheme == ThemeMode.dark
            ? 'Tối'
            : 'Hệ thống';

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
          'Tài khoản',
          style: AppTextStyles.headingMedium(color: AppColors.primaryDark)
              .copyWith(fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? Text(
                            user?.displayName.isNotEmpty == true
                                ? user!.displayName[0].toUpperCase()
                                : 'U',
                            style: AppTextStyles.headingLarge(
                                color: AppColors.primaryDark),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? 'Người dùng',
                    style: AppTextStyles.headingSmall(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'Chưa cập nhật email',
                    style: AppTextStyles.bodyMedium(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings & Preferences
            _buildSection(
              title: 'Tùy chỉnh',
              children: [
                _buildListTile(
                  icon: Icons.notifications_outlined,
                  title: 'Thông báo FCM',
                  subtitle: 'Nhắc nhở điểm danh hàng ngày',
                  onTap: () => _showFcmDialog(context, ref),
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.palette_outlined,
                  title: 'Giao diện',
                  subtitle: themeLabel,
                  onTap: () => _showThemeDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Support & About
            _buildSection(
              title: 'Hỗ trợ & Thông tin',
              children: [
                _buildListTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Trung tâm trợ giúp',
                  subtitle: 'Hướng dẫn sử dụng & câu hỏi thường gặp',
                  onTap: () => _showHelpCenter(context),
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Về ứng dụng',
                  subtitle: 'Phiên bản 1.0.0 • Financial Serenity',
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleSignOut(context, ref),
                icon: const Icon(Icons.logout_rounded, color: AppColors.warningRed),
                label: Text(
                  'Đăng xuất',
                  style: AppTextStyles.button(color: AppColors.warningRed),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.warningRed, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: AppTextStyles.headingSmall(color: AppColors.textPrimary)
                .copyWith(fontSize: 15),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryDark, size: 22),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge(color: AppColors.textPrimary)
            .copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTextStyles.bodyMedium(color: AppColors.textSecondary)
                  .copyWith(fontSize: 12),
            )
          : null,
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.borderLight,
      indent: 60,
      endIndent: 16,
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(themeModeProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Chọn giao diện', style: AppTextStyles.headingSmall()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Chế độ Sáng'),
              value: ThemeMode.light,
              groupValue: currentTheme,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  ref.read(themeModeProvider.notifier).state = val;
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Chế độ Tối'),
              value: ThemeMode.dark,
              groupValue: currentTheme,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  ref.read(themeModeProvider.notifier).state = val;
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Theo hệ thống'),
              value: ThemeMode.system,
              groupValue: currentTheme,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  ref.read(themeModeProvider.notifier).state = val;
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFcmDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final isEnabled = ref.watch(fcmReminderEnabledProvider);
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Thông báo & Nhắc nhở',
                        style: AppTextStyles.headingSmall(color: AppColors.primaryDark),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Nhắc nhở chi tiêu hàng ngày'),
                    subtitle: const Text('Nhận thông báo nhắc nhở vào 20:00 mỗi tối'),
                    value: isEnabled,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      ref.read(fcmReminderEnabledProvider.notifier).state = val;
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Firebase Cloud Messaging đã được kết nối.',
                            style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await NotificationService().showTestNotification();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã gửi thông báo thử nghiệm! Vui lòng kiểm tra thanh thông báo.'),
                              backgroundColor: AppColors.primaryDark,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      label: const Text('Gửi thông báo kiểm tra ngay', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showHelpCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Trung tâm trợ giúp', style: AppTextStyles.headingMedium(color: AppColors.primaryDark)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                '💰 Kế hoạch ngân sách là gì?',
                'Bạn nhập số tiền tổng có thể sử dụng trong tháng, sau đó thiết lập các khoản chi hàng ngày, hàng tuần và cố định. Ứng dụng tự động tính toán tổng chi và số tiền dư dự kiến.',
              ),
              _buildHelpItem(
                '🐷 Quỹ Heo đất hoạt động thế nào?',
                'Mỗi ngày khi bạn điểm danh chi tiêu: nếu bạn chọn "Không tiêu" cho một khoản nào đó, số tiền đó sẽ tự động được tích lũy vào Quỹ Heo Đất của bạn!',
              ),
              _buildHelpItem(
                '⚡ Chi phí phát sinh',
                'Khi có khoản chi đột xuất ngoài kế hoạch, hãy nhấn nút "+" trên trang chủ để ghi lại. Khoản này sẽ được tính vào tổng chi tiêu thực tế của ngày.',
              ),
              _buildHelpItem(
                '📊 Báo cáo & Lịch sử',
                'Xem biểu đồ chi tiêu và theo dõi mức độ tuân thủ ngân sách tại tab Goals/Báo cáo. Bạn cũng có thể xem lịch sử chi tiêu theo từng tháng dễ dàng.',
              ),
              _buildHelpItem(
                '📧 Liên hệ hỗ trợ',
                'Nếu bạn gặp sự cố hoặc cần hỗ trợ, vui lòng gửi email về:\nsupport@budgetplanner.app',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.savings_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 10),
            Text('Budget Planner'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Serenity',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 6),
            const Text('Phiên bản: 1.0.0'),
            const SizedBox(height: 12),
            Text(
              'Ứng dụng lập kế hoạch ngân sách và theo dõi chi tiêu cá nhân thông minh, mang lại sự thảnh thơi và an tâm tài chính cho bạn mỗi ngày.',
              style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            const Text(
              '© 2026 Budget Planner Team. All rights reserved.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
