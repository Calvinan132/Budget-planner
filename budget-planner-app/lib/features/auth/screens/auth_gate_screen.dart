import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../budget_setup/controllers/budget_plan_controller.dart';
import '../controllers/auth_controller.dart';

class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({super.key});

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Small delay for smooth splash presentation
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // 1. Check auto-login session
    final user = await ref.read(authControllerProvider.notifier).tryAutoLogin();

    if (!mounted) return;

    if (user == null) {
      // Not logged in -> Go to Welcome Screen
      Navigator.pushReplacementNamed(context, '/welcome');
      return;
    }

    // 2. Logged in -> Check if active plan exists for this month
    try {
      final planService = ref.read(budgetPlanServiceProvider);
      final currentPlan = await planService.getCurrentPlan().timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );

      if (!mounted) return;

      if (currentPlan != null) {
        // Plan exists -> Go to Daily Check-in Home
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // No plan for this month -> Go to Master Plan Setup
        Navigator.pushReplacementNamed(context, '/setup');
      }
    } catch (_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Budget Planner',
                  style: AppTextStyles.headingLarge(color: AppColors.primaryDark).copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sự thanh thản tài chính mỗi ngày',
                  style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
