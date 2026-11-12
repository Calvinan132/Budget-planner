import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

class RemainingDaysBudgetCard extends StatelessWidget {
  final int remainingDays;
  final double dailyBudget;

  const RemainingDaysBudgetCard({
    super.key,
    required this.remainingDays,
    required this.dailyBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_bottom_rounded, size: 16, color: AppColors.primaryDark),
              const SizedBox(width: 6),
              Text(
                'Còn $remainingDays ngày trong tháng',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (dailyBudget > 0)
            Text(
              'Hạn mức: ${CurrencyFormatter.formatShort(dailyBudget)}/ngày',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
        ],
      ),
    );
  }
}
