import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/controllers/auth_controller.dart';

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
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
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
                    color: Colors.black.withOpacity(0.04),
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
                  subtitle: 'Cài đặt nhắc nhở chi tiêu',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tính năng đang được phát triển.'),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.palette_outlined,
                  title: 'Giao diện',
                  subtitle: 'Sáng / Tối',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tính năng đang được phát triển.'),
                      ),
                    );
                  },
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
                  onTap: () {},
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Về ứng dụng',
                  subtitle: 'Phiên bản 1.0.0',
                  onTap: () {},
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
}
