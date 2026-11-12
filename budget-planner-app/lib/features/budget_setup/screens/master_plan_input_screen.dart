import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/budget_plan_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/app_drawer.dart';
import '../controllers/budget_plan_controller.dart';

class MasterPlanInputScreen extends ConsumerStatefulWidget {
  const MasterPlanInputScreen({super.key});

  @override
  ConsumerState<MasterPlanInputScreen> createState() => _MasterPlanInputScreenState();
}

class _MasterPlanInputScreenState extends ConsumerState<MasterPlanInputScreen> {
  List<RoutineItem> _dailyRoutines = [
    RoutineItem(id: '1', name: 'Ăn sáng', amount: 20000),
    RoutineItem(id: '2', name: 'Cà phê', amount: 35000),
  ];

  List<RoutineItem> _weeklyRoutines = [
    RoutineItem(id: '3', name: 'Đi siêu thị', amount: 500000, frequencyPerWeek: 1),
  ];

  List<RoutineItem> _monthlyFixed = [
    RoutineItem(id: '4', name: 'Tiền nhà', amount: 3500000),
    RoutineItem(id: '5', name: 'Điện nước', amount: 500000),
    RoutineItem(id: '6', name: 'Internet', amount: 250000),
  ];

  BudgetPlanModel? _editingPlan;
  bool _hasPopulatedFromPlan = false;
  bool _userHasModified = false;

  // So tien co the su dung trong thang nay
  final TextEditingController _initialBudgetController = TextEditingController();
  double _initialBudget = 0;

  // Luôn tính theo số ngày còn lại trong tháng
  int get _activeDays => DateHelper.getRemainingDaysInMonth(DateTime.now());

  double get _calculatedTotal {
    final days = _activeDays;
    double daily = _dailyRoutines.fold(0, (sum, item) => sum + (item.amount * days));
    double weeks = days / 7.0;
    double weekly = _weeklyRoutines.fold(
        0, (sum, item) => sum + (item.amount * item.frequencyPerWeek * weeks));
    double fixed = _monthlyFixed.fold(0, (sum, item) => sum + item.amount);
    return daily + weekly + fixed;
  }

  double get _budgetPerDay {
    if (_initialBudget <= 0 || _activeDays <= 0) return 0;
    return _initialBudget / _activeDays;
  }

  void _populateFromPlan(BudgetPlanModel targetPlan) {
    _editingPlan = targetPlan;
    _dailyRoutines = targetPlan.dailyRoutines
        .map((e) => RoutineItem(id: e.id, name: e.name, amount: e.amount))
        .toList();
    _weeklyRoutines = targetPlan.weeklyRoutines
        .map((e) => RoutineItem(
              id: e.id,
              name: e.name,
              amount: e.amount,
              frequencyPerWeek: e.frequencyPerWeek,
            ))
        .toList();
    _monthlyFixed = targetPlan.monthlyFixed
        .map((e) => RoutineItem(id: e.id, name: e.name, amount: e.amount))
        .toList();
    _initialBudget = targetPlan.initialBudget > 0
        ? targetPlan.initialBudget
        : targetPlan.totalPlanned;
    if (_initialBudget > 0) {
      _initialBudgetController.text = _initialBudget.toStringAsFixed(0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasPopulatedFromPlan) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is BudgetPlanModel) {
        _hasPopulatedFromPlan = true;
        _populateFromPlan(args);
      } else {
        final existingPlan = ref.read(budgetPlanControllerProvider).plan;
        if (existingPlan != null) {
          _hasPopulatedFromPlan = true;
          _populateFromPlan(existingPlan);
        }
      }
    }
  }

  @override
  void dispose() {
    _initialBudgetController.dispose();
    super.dispose();
  }


  void _addDailyItem() {
    _userHasModified = true;
    setState(() {
      _dailyRoutines.add(RoutineItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Khoản mới',
        amount: 20000,
      ));
    });
  }

  void _addWeeklyItem() {
    _userHasModified = true;
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
    _userHasModified = true;
    setState(() {
      _monthlyFixed.add(RoutineItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Chi phí mới',
        amount: 100000,
      ));
    });
  }

  void _submitPlan() async {
    // Validate: nguoi dung phai nhap so tien ngan sach
    if (_initialBudget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ban can nhap so tien co the su dung trong thang nay!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final calculated = _calculatedTotal;
    final isEditing = _editingPlan != null;

    final plan = BudgetPlanModel(
      id: isEditing ? _editingPlan!.id : null,
      dailyRoutines: _dailyRoutines,
      weeklyRoutines: _weeklyRoutines,
      monthlyFixed: _monthlyFixed,
      initialBudget: _initialBudget,
      totalPlanned: calculated,
      actualSpent: isEditing ? _editingPlan!.actualSpent : calculated,
      savedAmount: isEditing
          ? _editingPlan!.savedAmount
          : (_initialBudget - calculated).clamp(0, double.infinity),
      isLocked: isEditing ? _editingPlan!.isLocked : true,
    );

    final notifier = ref.read(budgetPlanControllerProvider.notifier);
    final success = isEditing
        ? await notifier.updatePlan(plan)
        : await notifier.savePlan(plan);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Ke hoach da duoc cap nhat!'
              : 'Kich ban ngan sach da duoc kich hoat thanh cong!'),
        ),
      );
      if (isEditing) {
        Navigator.pop(context); // Quay lai man hinh tong ke hoach
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final planState = ref.watch(budgetPlanControllerProvider);

    if (!_hasPopulatedFromPlan && !_userHasModified) {
      final currentPlan = planState.plan;
      if (currentPlan != null) {
        _hasPopulatedFromPlan = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _populateFromPlan(currentPlan);
            });
          }
        });
      }
    }

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
          'Financial Serenity',
          style: AppTextStyles.headingMedium(color: AppColors.primaryDark).copyWith(
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: UserAvatar(
              radius: 18,
              photoUrl: user?.photoUrl,
              displayName: user?.displayName,
            ),
          ),
        ],
      ),
      body: planState.isLoading && _editingPlan == null && !_hasPopulatedFromPlan
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
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

                  // Step 0: User enters their monthly available budget
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8F8F0), Color(0xFFD1FAE5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF86EFAC), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.savings_rounded, size: 22, color: AppColors.primaryDark),
                            const SizedBox(width: 8),
                            Text(
                              'So tien co the tieu thang nay',
                              style: AppTextStyles.headingSmall(color: AppColors.primaryDark).copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Nhap tong so tien ban co the su dung trong thang nay. Phan con lai sau chi tieu ke hoach se vao Quy heo dat.',
                          style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _initialBudgetController,
                          keyboardType: TextInputType.number,
                          style: AppTextStyles.headingMedium(color: AppColors.primaryDark).copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Vi du: 5000000',
                            hintStyle: AppTextStyles.bodyMedium(color: AppColors.textMuted),
                            suffixText: 'VND',
                            suffixStyle: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF86EFAC), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _initialBudget = double.tryParse(val.replaceAll(',', '').replaceAll('.', '')) ?? 0;
                            });
                          },
                        ),
                        // Show estimated piggy bank if budget entered
                        if (_initialBudget > 0 && _calculatedTotal > 0) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Du kien vao Quy heo dat:',
                                  style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(fontSize: 12),
                                ),
                                Text(
                                  CurrencyFormatter.formatVND(
                                    (_initialBudget - _calculatedTotal).clamp(0, double.infinity),
                                  ),
                                  style: AppTextStyles.bodyLarge(color: AppColors.primaryDark).copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info chip: tự động tính theo số ngày còn lại
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top_rounded, size: 16, color: AppColors.primaryDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tính theo $_activeDays ngày còn lại trong tháng (từ hôm nay ${DateTime.now().day}/${DateTime.now().month})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        if (_budgetPerDay > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${CurrencyFormatter.formatShort(_budgetPerDay)}/ngày',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section 1: Chi phi Hang ngay
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
                  color: Colors.black.withValues(alpha: 0.06),
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
                            'Dự kiến chi ($_activeDays ngày còn lại):',
                            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                          ),
                          Text(
                            'Tính từ hôm nay đến cuối tháng',
                            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                      Text(
                        '${CurrencyFormatter.formatVND(_calculatedTotal, showSymbol: true)} ($_activeDays ngày)',
                        style: AppTextStyles.headingMedium(color: AppColors.primaryDark).copyWith(
                          fontSize: 18,
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
                      'Lưu kế hoạch chi tiêu',
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

