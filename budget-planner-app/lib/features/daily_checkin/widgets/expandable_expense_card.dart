import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/daily_expense_model.dart';

class ExpandableExpenseCard extends StatefulWidget {
  final DailyExpenseModel expense;
  final Function(String status) onStatusChange;

  /// Chi dung cho khoan chi phat sinh (isUnexpected): mo sheet Sua / Xoa.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExpandableExpenseCard({
    super.key,
    required this.expense,
    required this.onStatusChange,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ExpandableExpenseCard> createState() => _ExpandableExpenseCardState();
}

class _ExpandableExpenseCardState extends State<ExpandableExpenseCard> {
  bool _isExpanded = false;
  bool _isDismissing = false;

  void _handleAction(String status) async {
    // Haptic Feedback
    if (status == 'skipped') {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    // 1. Collapse card & start dismiss animation
    setState(() {
      _isExpanded = false;
      _isDismissing = true;
    });

    // 2. Chờ animation hoàn thành rồi mới gọi callback
    await Future.delayed(const Duration(milliseconds: 320));

    // 3. Notify parent — triggers Riverpod state update & removes from list
    widget.onStatusChange(status);
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'coffee':
        return Icons.local_cafe_rounded;
      case 'transport':
        return Icons.directions_bus_rounded;
      case 'unexpected':
        return Icons.add_circle_outline_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFFDCFCE7);
      case 'skipped':
        return const Color(0xFFF0FDF4);
      default:
        return Colors.transparent;
    }
  }

  Widget _buildStatusBadge(String status) {
    if (status == 'pending') return const SizedBox.shrink();
    final isCompleted = status == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFD1FAE5) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 12,
            color: isCompleted ? AppColors.primaryDark : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            isCompleted ? 'Da tieu' : 'Khong tieu',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isCompleted ? AppColors.primaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.expense.status;
    final isDone = status == 'completed' || status == 'skipped';

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _isDismissing
          ? const SizedBox.shrink()
          : _buildCard(context, status, isDone),
    );
  }

  Widget _buildCard(BuildContext context, String status, bool isDone) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: isDone ? _getStatusColor(status) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone
              ? (status == 'completed' ? const Color(0xFFBBF7D0) : const Color(0xFFD1D5DB))
              : AppColors.borderLight,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
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
                    // Icon badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.expense.isUnexpected
                            ? const Color(0xFFFFEDD5)
                            : (status == 'completed'
                                ? const Color(0xFFD1FAE5)
                                : status == 'skipped'
                                    ? const Color(0xFFE5E7EB)
                                    : const Color(0xFFD1FAE5)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getCategoryIcon(widget.expense.category),
                        color: widget.expense.isUnexpected
                            ? AppColors.orangeTag
                            : (status == 'skipped' ? AppColors.textSecondary : AppColors.primaryDark),
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
                              decoration: status == 'skipped' ? TextDecoration.lineThrough : null,
                              decorationColor: AppColors.textSecondary,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                CurrencyFormatter.formatShort(widget.expense.amount),
                                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(status),
                            ],
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

                // Expanded Action Buttons
                if (_isExpanded) ...[
                  const SizedBox(height: 16),
                  if (widget.expense.isUnexpected)
                    // Khoan chi phat sinh: cho phep Sua / Xoa (khong phai check-in)
                    Row(
                      children: [
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
                            onPressed: () {
                              setState(() => _isExpanded = false);
                              widget.onEdit?.call();
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_rounded, size: 18),
                                SizedBox(width: 6),
                                Text('Sua', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEF2F2),
                              foregroundColor: AppColors.warningRed,
                              elevation: 0,
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              setState(() => _isExpanded = false);
                              widget.onDelete?.call();
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18),
                                SizedBox(width: 6),
                                Text('Xoa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                      // Green button [Co tieu]
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: status == 'completed'
                                ? AppColors.primaryDark.withValues(alpha: 0.5)
                                : AppColors.primaryDark,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _handleAction(status == 'completed' ? 'pending' : 'completed'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_rounded, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                status == 'completed' ? 'Hoan tac' : 'Co tieu',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Gray button [Khong tieu]
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: status == 'skipped'
                                ? const Color(0xFFD1D5DB)
                                : const Color(0xFFE5E7EB),
                            foregroundColor: AppColors.textPrimary,
                            elevation: 0,
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _handleAction(status == 'skipped' ? 'pending' : 'skipped'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                status == 'skipped' ? 'Hoan tac' : 'Khong tieu',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
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
      ),
    );
  }
}
