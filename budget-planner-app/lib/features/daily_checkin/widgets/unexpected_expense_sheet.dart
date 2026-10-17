import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../controllers/daily_checkin_controller.dart';
import '../../budget_setup/controllers/budget_plan_controller.dart';

class UnexpectedExpenseSheet extends ConsumerStatefulWidget {
  const UnexpectedExpenseSheet({super.key});

  @override
  ConsumerState<UnexpectedExpenseSheet> createState() => _UnexpectedExpenseSheetState();
}

class _UnexpectedExpenseSheetState extends ConsumerState<UnexpectedExpenseSheet> {
  String _amountStr = '0';
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'back') {
        if (_amountStr.length > 1) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        } else {
          _amountStr = '0';
        }
      } else if (key == '.') {
        if (!_amountStr.contains('.')) {
          _amountStr += '.';
        }
      } else {
        if (_amountStr == '0') {
          _amountStr = key;
        } else {
          _amountStr += key;
        }
      }
    });
  }

  void _submit() async {
    final double amount = double.tryParse(_amountStr) ?? 0;
    final String reason = _reasonController.text.trim();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ.')),
      );
      return;
    }

    // Optimistic UI for Budget Plan (actualSpent += amount)
    final budgetNotifier = ref.read(budgetPlanControllerProvider.notifier);
    budgetNotifier.incrementActualSpent(amount);

    final success = await ref
        .read(dailyCheckInControllerProvider.notifier)
        .addUnexpectedExpense(amount, reason.isEmpty ? 'Phát sinh' : reason);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã ghi nhận khoản chi phát sinh!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } else if (!success && mounted) {
      // Rollback
      budgetNotifier.incrementActualSpent(-amount);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi hệ thống, đã hoàn tác khoản chi.'),
          backgroundColor: AppColors.warningRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double currentAmount = double.tryParse(_amountStr) ?? 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Title and Close Button matching Stitch AI Image 2 Right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32),
                  Text(
                    'Quick Log',
                    style: AppTextStyles.headingMedium(color: AppColors.textPrimary).copyWith(
                      fontSize: 18,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Text(
                'Số tiền phát sinh (đ)',
                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),

              // Large formatted currency display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'đ ',
                    style: AppTextStyles.currencyBig(color: AppColors.textMuted).copyWith(
                      fontSize: 26,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatVND(currentAmount, showSymbol: false),
                    style: AppTextStyles.currencyBig(color: AppColors.primaryDark).copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Text input field: "Lý do phát sinh"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F9F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'e.g., Sửa xe, Cà phê...',
                    labelText: 'Lý do phát sinh',
                    labelStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Custom Numeric Keypad matching Stitch AI Image 2 Right
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 1.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  '1', '2', '3',
                  '4', '5', '6',
                  '7', '8', '9',
                  '.', '0', 'back',
                ].map((key) {
                  if (key == 'back') {
                    return _buildKeypadButton(
                      child: const Icon(Icons.backspace_outlined, size: 20, color: AppColors.textPrimary),
                      onTap: () => _onKeyPress('back'),
                    );
                  }
                  return _buildKeypadButton(
                    child: Text(
                      key,
                      style: AppTextStyles.headingSmall(color: AppColors.textPrimary).copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => _onKeyPress(key),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Submit Button: ✓ Save Expense matching Stitch AI
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _submit,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Save Expense',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton({required Widget child, required VoidCallback onTap}) {
    return Material(
      color: const Color(0xFFEFF4F1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Center(child: child),
      ),
    );
  }
}
