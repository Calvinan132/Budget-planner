import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';

class PiggyBankCard extends StatelessWidget {
  final double currentSavings;
  final double savingsGoal;

  const PiggyBankCard({
    super.key,
    required this.currentSavings,
    required this.savingsGoal,
  });

  @override
  Widget build(BuildContext context) {
    final double safeGoal = savingsGoal > 0 ? savingsGoal : 1.0;
    final double progress = (currentSavings / safeGoal).clamp(0.0, 1.0);
    final String percentageStr = ((currentSavings / safeGoal) * 100).toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F8F0), Color(0xFFD1FAE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  size: 18,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Quỹ heo đất tiết kiệm tháng này',
                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Real-time Count-up Animation for Piggy Bank Balance
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: currentSavings),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, child) {
              return Text(
                '+${CurrencyFormatter.formatVND(animatedValue)}',
                style: AppTextStyles.headingLarge(color: AppColors.primaryDark).copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Animated Progress bar
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, animProgress, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: animProgress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.7),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiến độ: $percentageStr%',
                style: AppTextStyles.bodyMedium(color: AppColors.primaryDark).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Mục tiêu: ${CurrencyFormatter.formatShort(savingsGoal)}',
                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
