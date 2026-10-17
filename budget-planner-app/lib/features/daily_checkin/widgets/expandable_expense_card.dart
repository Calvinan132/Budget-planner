import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/daily_expense_model.dart';

class ExpandableExpenseCard extends StatefulWidget {
  final DailyExpenseModel expense;
  final Function(String status) onAction;

  const ExpandableExpenseCard({
    super.key,
    required this.expense,
    required this.onAction,
  });

  @override
  State<ExpandableExpenseCard> createState() => _ExpandableExpenseCardState();
}

class _ExpandableExpenseCardState extends State<ExpandableExpenseCard> {
  bool _isExpanded = false;
  bool _isDisappearing = false;

  void _handleAction(String status) async {
    setState(() {
      _isDisappearing = true;
    });
    await Future.delayed(const Duration(milliseconds: 250));
    widget.onAction(status);
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'coffee':
        return Icons.local_cafe_rounded;
      case 'transport':
        return Icons.directions_bus_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisappearing) {
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: 0.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 0,
          margin: EdgeInsets.zero,
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderLight, width: 0.8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  // Icon badge matching Stitch AI (soft green circle)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD1FAE5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(widget.expense.category),
                      color: AppColors.primaryDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name & Short Amount
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.expense.name,
                          style: AppTextStyles.bodyLarge(color: AppColors.textPrimary).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatShort(widget.expense.amount),
                          style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chevron indicator arrow
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                    size: 24,
                  ),
                ],
              ),

              // Expanded Action Buttons matching Stitch AI Image 2 (Middle)
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Green button [Có tiêu]
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _handleAction('completed'),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, size: 18),
                            SizedBox(width: 6),
                            Text('Có tiêu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Gray / Red button [Không tiêu]
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5E7EB),
                          foregroundColor: AppColors.textPrimary,
                          elevation: 0,
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _handleAction('skipped'),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                            SizedBox(width: 6),
                            Text('Không tiêu', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
