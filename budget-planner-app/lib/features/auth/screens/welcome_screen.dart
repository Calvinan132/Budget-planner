import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controllers/auth_controller.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              const Spacer(),
              // Central App Icon matching Stitch AI (Rounded Emerald box with pin icon)
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 54,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Title and App Name
              Text(
                'Chào mừng bạn đến với',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingSmall(color: AppColors.textPrimary).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Budget Planner',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingLarge(color: AppColors.primaryDark).copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sự thanh thản tài chính bắt đầu từ\nđây.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                  fontSize: 15,
                  height: 1.4,
                ),
              ),

              const Spacer(),

              // Google Sign In Button (Matching Stitch AI Image 1)
              if (authState.isLoading)
                const CircularProgressIndicator(color: AppColors.primary)
              else
                Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 1,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                          side: const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                      onPressed: () async {
                        final success = await ref
                            .read(authControllerProvider.notifier)
                            .signInWithGoogle();
                        if (success && context.mounted) {
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                              width: 22,
                              height: 22,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.g_mobiledata, color: Colors.red, size: 28),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Đăng nhập bằng Google',
                            style: AppTextStyles.button(color: AppColors.textPrimary).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Navigation to Standard Email Sign In
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignInScreen()),
                            );
                          },
                          child: Text(
                            'Đăng nhập bằng Email',
                            style: AppTextStyles.bodyMedium(color: AppColors.primaryDark).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '•',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignUpScreen()),
                            );
                          },
                          child: Text(
                            'Tạo tài khoản mới',
                            style: AppTextStyles.bodyMedium(color: AppColors.primaryDark).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // Footer text matching Stitch AI
              Text(
                'Bằng việc tiếp tục, bạn đồng ý với Điều khoản và\nChính sách bảo mật.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(color: AppColors.textMuted).copyWith(
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
