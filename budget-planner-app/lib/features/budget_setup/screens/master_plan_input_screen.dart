import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/budget_plan_model.dart';
import '../controllers/budget_plan_controller.dart';

class MasterPlanInputScreen extends ConsumerStatefulWidget {
  const MasterPlanInputScreen({super.key});

  @override
  ConsumerState<MasterPlanInputScreen> createState() => _MasterPlanInputScreenState();
}

class _MasterPlanInputScreenState extends ConsumerState<MasterPlanInputScreen> {
  final List<RoutineItem> _dailyRoutines = [
    RoutineItem(id: '1', name: 'Ăn sáng', amount: 20000),
    RoutineItem(id: '2', name: 'Cà phê', amount: 35000),
  ];

  final List<RoutineItem> _weeklyRoutines = [
    RoutineItem(id: '3', name: 'Đi siêu thị', amount: 500000, frequencyPerWeek: 1),
  ];

  final List<RoutineItem> _monthlyFixed = [
    RoutineItem(id: '4', name: 'Tiền nhà', amount: 3500000),
    RoutineItem(id: '5', name: 'Điện nước', amount: 500000),
    RoutineItem(id: '6', name: 'Internet', amount: 250000),
  ];

  double get _calculatedTotal {
    double daily = _dailyRoutines.fold(0, (sum, item) => sum + (item.amount * 30));
    double weekly = _weeklyRoutines.fold(
        0, (sum, item) => sum + (item.amount * item.frequencyPerWeek * 4.33));
    double fixed = _monthlyFixed.fold(0, (sum, item) => sum + item.amount);
    return daily + weekly + fixed;
  }

  void _addDailyItem() {
    setState(() {
      _dailyRoutines.add(RoutineItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Khoản mới',
        amount: 20000,
      ));
    });
  }

  void _addWeeklyItem() {
    setState(() {
      _weeklyRoutines.add(RoutineItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Khoản tuần mới',
        amount: 100000,
        frequencyPerWeek: 1,
      ));
    });
  }

  void _addMonthlyItem() {
    setState(() {
      _monthlyFixed.add(RoutineItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Chi phí mới',
        amount: 100000,
      ));
    });
  }

  void _submitPlan() async {
    final calculated = _calculatedTotal;
    final plan = BudgetPlanModel(
      dailyRoutines: _dailyRoutines,
      weeklyRoutines: _weeklyRoutines,
      monthlyFixed: _monthlyFixed,
      totalPlanned: calculated,
      actualSpent: calculated, // Phase 1: Assumed full spend baseline
      savedAmount: 0.0,
      isLocked: true,
    );

    final success = await ref
        .read(budgetPlanControllerProvider.notifier)
        .savePlan(plan);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kịch bản ngân sách đã được kích hoạt thành công!')),
      );
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.primaryDark),
          onPressed: () {},
        ),
        title: Text(
          'Financial Serenity',
          style: AppTextStyles.headingMedium(color: AppColors.primaryDark).copyWith(
            fontSize: 18,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lên kế hoạch tháng mới',
                    style: AppTextStyles.headingLarge(color: AppColors.textPrimary).copyWith(
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Thiết lập ngân sách theo từng chu kỳ để dễ dàng quản lý.',
                    style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 1: Chi phí Hàng ngày
                  _buildSectionCard(
                    icon: Icons.calendar_today_rounded,
                    title: 'Chi phí Hàng ngày',
                    items: _dailyRoutines,
                    onAddPressed: _addDailyItem,
                    addLabel: '+ Thêm khoản ngày',
                    showFrequency: false,
                  ),

                  const SizedBox(height: 16),

                  // Section 2: Chi phí Hàng tuần
                  _buildSectionCard(
                    icon: Icons.grid_view_rounded,
                    title: 'Chi phí Hàng tuần',
                    items: _weeklyRoutines,
                    onAddPressed: _addWeeklyItem,
                    addLabel: '+ Thêm khoản tuần',
                    showFrequency: true,
                  ),

                  const SizedBox(height: 16),

                  // Section 3: Chi phí Hàng tháng (Cố định)
                  _buildSectionCard(
                    icon: Icons.account_balance_outlined,
                    title: 'Chi phí Hàng tháng (Cố định)',
                    items: _monthlyFixed,
                    onAddPressed: _addMonthlyItem,
                    addLabel: '+ Thêm khoản tháng',
                    showFrequency: false,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Sticky Bottom Card matching Stitch AI Image 5
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dự kiến chi tiêu',
                            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                          ),
                          Text(
                            'thực tế:',
                            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Text(
                        '${CurrencyFormatter.formatVND(_calculatedTotal, showSymbol: true)}/tháng',
                        style: AppTextStyles.headingMedium(color: AppColors.primaryDark).copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _submitPlan,
                    child: Text(
                      'Kích hoạt kịch bản tháng',
                      style: AppTextStyles.button(color: Colors.white).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<RoutineItem> items,
    required VoidCallback onAddPressed,
    required String addLabel,
    required bool showFrequency,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.headingSmall(color: AppColors.textPrimary).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Name field
                      Expanded(
                        flex: 5,
                        child: TextFormField(
                          initialValue: item.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            fillColor: const Color(0xFFF3F4F6),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) => item.name = val,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Amount field
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          initialValue: CurrencyFormatter.formatVND(item.amount, showSymbol: true),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            fillColor: const Color(0xFFF3F4F6),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              item.amount = CurrencyFormatter.parseAmount(val);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                        onPressed: () {
                          setState(() {
                            items.removeAt(idx);
                          });
                        },
                      ),
                    ],
                  ),

                  // Frequency counter for weekly items matching Stitch AI Image 5
                  if (showFrequency) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tần suất:',
                            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(fontSize: 13),
                          ),
                          Row(
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.remove_rounded, size: 18, color: AppColors.primaryDark),
                                onPressed: () {
                                  if (item.frequencyPerWeek > 1) {
                                    setState(() {
                                      item.frequencyPerWeek--;
                                    });
                                  }
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '${item.frequencyPerWeek} lần/tuần',
                                  style: AppTextStyles.bodyLarge(color: AppColors.primaryDark).copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primaryDark),
                                onPressed: () {
                                  setState(() {
                                    item.frequencyPerWeek++;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // Add item soft mint button matching Stitch AI
          InkWell(
            onTap: onAddPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFC7F2DA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  addLabel,
                  style: AppTextStyles.button(color: AppColors.primaryDark).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
