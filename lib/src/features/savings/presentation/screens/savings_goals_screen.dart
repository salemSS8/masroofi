import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:bashnddof/src/core/models/savings_goal_model.dart';
import 'package:bashnddof/src/core/models/transaction_model.dart';
import 'package:bashnddof/src/core/repositories/savings_goal_repository.dart';
import 'package:bashnddof/src/core/repositories/transaction_repository.dart';
import 'package:bashnddof/src/core/services/notification_service.dart';
import 'package:bashnddof/src/core/theme/app_colors.dart';
import 'package:bashnddof/src/core/widgets/app_button.dart';
import 'package:bashnddof/src/core/widgets/app_text_field.dart';
import 'package:bashnddof/src/core/widgets/artistic_illustrations.dart';
import 'package:bashnddof/src/core/currency/currency_service.dart';
import 'package:bashnddof/src/core/localization/app_localizations.dart';

/// شاشة إدارة أهداف الادخار المالي (Savings Goals Screen)
class SavingsGoalsScreen extends StatefulWidget {
  final bool showAppBar;
  const SavingsGoalsScreen({super.key, this.showAppBar = false});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _goalRepo = SavingsGoalRepository();

  List<SavingsGoalModel> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    final data = await _goalRepo.getAll();
    if (mounted) {
      setState(() {
        _goals = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddOrEditDialog([SavingsGoalModel? existing]) async {
    final isArabic = context.isArabic;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final targetController = TextEditingController(
      text: existing != null ? existing.targetAmount.toString() : '',
    );
    final currentController = TextEditingController(
      text: existing != null ? existing.currentAmount.toString() : '0.0',
    );
    DateTime? selectedDate = existing?.targetDate;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          final dateStr = selectedDate != null
              ? DateFormat('yyyy/MM/dd', isArabic ? 'ar' : 'en').format(selectedDate!)
              : (isArabic ? 'بدون تاريخ محدد' : 'No target date');

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing == null
                            ? (isArabic ? 'إضافة هدف ادخار جديد' : 'New Savings Goal')
                            : (isArabic ? 'تعديل هدف الادخار' : 'Edit Savings Goal'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: nameController,
                    labelText: isArabic ? 'اسم الهدف' : 'Goal Name',
                    hintText: isArabic
                        ? 'مثلاً: شراء لابتوب، دفعة سيارة، صندوق طوارئ'
                        : 'e.g. Laptop, Car down payment, Emergency fund',
                    validator: (val) =>
                        (val == null || val.trim().isEmpty)
                            ? (isArabic ? 'الرجاء إدخال اسم الهدف' : 'Please enter goal name')
                            : null,
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: targetController,
                    labelText: isArabic ? 'المبلغ المستهدف' : 'Target Amount',
                    hintText: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return isArabic ? 'الرجاء إدخال المبلغ المستهدف' : 'Please enter target amount';
                      }
                      final num = double.tryParse(val.trim());
                      if (num == null || num <= 0) {
                        return isArabic ? 'المبلغ يجب أن يكون أكبر من الصفر' : 'Amount must be greater than zero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  if (existing == null) ...[
                    AppTextField(
                      controller: currentController,
                      labelText: isArabic ? 'المبلغ المدخر حالياً (اختياري)' : 'Current Saved Amount (Optional)',
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // اختيار التاريخ المستهدف
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 90)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                        locale: Locale(isArabic ? 'ar' : 'en'),
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkSurface
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkBorder
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic ? 'تاريخ الإنجاز المستهدف (اختياري)' : 'Target Completion Date (Optional)',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              Text(dateStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const Spacer(),
                          if (selectedDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setModalState(() => selectedDate = null),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  AppButton(
                    text: existing == null
                        ? (isArabic ? 'إنشاء هدف الادخار' : 'Create Savings Goal')
                        : (isArabic ? 'حفظ التعديلات' : 'Save Changes'),
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final name = nameController.text.trim();
                      final target = double.parse(targetController.text.trim());
                      final current = double.tryParse(currentController.text.trim()) ?? 0.0;

                      if (existing == null) {
                        await _goalRepo.insert(
                          SavingsGoalModel(
                            name: name,
                            targetAmount: target,
                            currentAmount: current,
                            targetDate: selectedDate,
                          ),
                        );
                      } else {
                        await _goalRepo.update(
                          existing.copyWith(
                            name: name,
                            targetAmount: target,
                            targetDate: selectedDate,
                          ),
                        );
                      }

                      HapticFeedback.mediumImpact();
                      if (!modalContext.mounted) return;
                      Navigator.of(ctx).pop();
                      _loadGoals();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddContributionDialog(SavingsGoalModel goal) async {
    final isArabic = context.isArabic;
    final loc = context.loc;
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool deductFromWallet = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(isArabic ? 'إيداع في: ${goal.name}' : 'Deposit to: ${goal.name}'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${loc.translate('remainingToReach')}: ${CurrencyService.format(goal.remainingAmount, isArabic: isArabic)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: amountController,
                    labelText: isArabic ? 'مبلغ الإيداع' : 'Deposit Amount',
                    hintText: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return isArabic ? 'الرجاء إدخال المبلغ' : 'Please enter amount';
                      }
                      final num = double.tryParse(val.trim());
                      if (num == null || num <= 0) {
                        return isArabic ? 'المبلغ يجب أن يكون أكبر من الصفر' : 'Amount must be greater than zero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: deductFromWallet,
                    title: Text(
                      isArabic
                          ? 'خصم من رصيد المحفظة وتسجيل المعاملة'
                          : 'Deduct from wallet balance & record transaction',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        deductFromWallet = val ?? true;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final amount = double.parse(amountController.text.trim());
                await _goalRepo.addContribution(goal.id!, amount);

                if (deductFromWallet) {
                  final txRepo = TransactionRepository();
                  await txRepo.insert(
                    TransactionModel(
                      title: isArabic ? 'إيداع ادخار: ${goal.name}' : 'Savings Deposit: ${goal.name}',
                      amount: amount,
                      type: 'expense',
                      date: DateTime.now(),
                      notes: isArabic
                          ? 'تم تحويل وإيداع المبلغ في هدف الادخار "${goal.name}"'
                          : 'Deposited into savings goal "${goal.name}"',
                    ),
                  );
                }

                if (goal.currentAmount + amount >= goal.targetAmount) {
                  NotificationService().showInstantNotification(
                    id: (goal.id ?? 1) + 2000,
                    title: isArabic ? 'تهانينا، حققت هدف الادخار' : 'Congratulations! Goal Achieved',
                    body: isArabic
                        ? 'تهانينا، لقد جمعت كامل المبلغ المطلوب لهدف "${goal.name}".'
                        : 'Congratulations, you reached the target for "${goal.name}".',
                    type: 'system',
                  );
                }
                HapticFeedback.mediumImpact();
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                _loadGoals();
              },
              child: Text(isArabic ? 'إيداع' : 'Deposit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteGoal(SavingsGoalModel goal) async {
    final isArabic = context.isArabic;
    final loc = context.loc;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'حذف الهدف' : 'Delete Goal'),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من حذف هدف "${goal.name}"؟'
              : 'Are you sure you want to delete goal "${goal.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.translate('cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && goal.id != null) {
      await _goalRepo.delete(goal.id!);
      HapticFeedback.mediumImpact();
      _loadGoals();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = context.loc;
    final isArabic = context.isArabic;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ValueListenableBuilder<CurrencyModel>(
      valueListenable: CurrencyService.currencyNotifier,
      builder: (context, _, __) {
        return Scaffold(
          appBar: widget.showAppBar
              ? AppBar(
                  title: Text(loc.translate('savingsGoalsTitle')),
                )
              : null,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddOrEditDialog(),
            icon: const Icon(Icons.add_rounded),
            label: Text(loc.translate('newGoal')),
          ),
      body: RefreshIndicator(
        onRefresh: _loadGoals,
        child: _goals.isEmpty
            ? LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ArtisticSavingsVaultIllustration(size: 150),
                              const SizedBox(height: 20),
                              Text(
                                loc.translate('noGoals'),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                loc.translate('noGoalsSub'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              AppButton(
                                text: loc.translate('addGoal'),
                                icon: Icons.add_rounded,
                                onPressed: () => _showAddOrEditDialog(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _goals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final goal = _goals[index];
                  final percent = goal.progressPercentage;
                  final isDone = goal.isCompleted;

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDone
                            ? AppColors.income.withAlpha(128)
                            : (isDark ? AppColors.darkBorder : AppColors.border),
                        width: isDone ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isDone ? AppColors.income : const Color(0xFF8B5CF6)).withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isDone ? Icons.check_circle_rounded : Icons.savings_rounded,
                                color: isDone ? AppColors.income : const Color(0xFF8B5CF6),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                  if (goal.targetDate != null)
                                    Text(
                                      '${isArabic ? "المستهدف: " : "Target: "}${DateFormat('yyyy/MM/dd', isArabic ? 'ar' : 'en').format(goal.targetDate!)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                              tooltip: loc.translate('addContribution'),
                              onPressed: () => _showAddContributionDialog(goal),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, size: 20),
                              padding: EdgeInsets.zero,
                              tooltip: isArabic ? 'خيارات' : 'Options',
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showAddOrEditDialog(goal);
                                } else if (val == 'delete') {
                                  _deleteGoal(goal);
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit_outlined, size: 18),
                                      const SizedBox(width: 8),
                                      Text(loc.translate('editGoal')),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expense),
                                      const SizedBox(width: 8),
                                      Text(loc.translate('delete'), style: const TextStyle(color: AppColors.expense)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                '${loc.translate('totalSaved')}: ${CurrencyService.format(goal.currentAmount, isArabic: isArabic)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDone ? AppColors.income : AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${loc.translate('target')}: ${CurrencyService.format(goal.targetAmount, isArabic: isArabic)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        LinearPercentIndicator(
                          lineHeight: 10.0,
                          percent: percent,
                          progressColor: isDone ? AppColors.income : const Color(0xFF8B5CF6),
                          backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                          barRadius: const Radius.circular(8),
                          padding: EdgeInsets.zero,
                          animation: true,
                          animationDuration: 600,
                        ),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                isDone
                                    ? (isArabic ? '🎉 تهانينا! حققت الهدف بالكامل' : '🎉 Congratulations! Goal Achieved')
                                    : '${loc.translate('remaining')}: ${CurrencyService.format(goal.remainingAmount, isArabic: isArabic)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDone ? AppColors.income : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(percent * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDone ? AppColors.income : const Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        );
      },
    );
  }
}
