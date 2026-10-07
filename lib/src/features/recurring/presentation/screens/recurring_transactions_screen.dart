import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:bashnddof/src/core/models/category_model.dart';
import 'package:bashnddof/src/core/models/recurring_transaction_model.dart';
import 'package:bashnddof/src/core/models/transaction_model.dart';
import 'package:bashnddof/src/core/repositories/category_repository.dart';
import 'package:bashnddof/src/core/repositories/recurring_transaction_repository.dart';
import 'package:bashnddof/src/core/repositories/transaction_repository.dart';
import 'package:bashnddof/src/core/theme/app_colors.dart';
import 'package:bashnddof/src/core/widgets/app_button.dart';
import 'package:bashnddof/src/core/widgets/app_text_field.dart';
import 'package:bashnddof/src/core/currency/currency_service.dart';
import 'package:bashnddof/src/core/localization/app_localizations.dart';

/// شاشة إدارة المعاملات المالية المتكررة والدورية (Recurring Transactions Screen)
class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  final _recurringRepo = RecurringTransactionRepository();
  final _transactionRepo = TransactionRepository();
  final _categoryRepo = CategoryRepository();

  List<RecurringTransactionModel> _items = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final items = await _recurringRepo.getAll();
    final categories = await _categoryRepo.getAll();
    if (mounted) {
      setState(() {
        _items = items;
        _categories = categories;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleActive(RecurringTransactionModel item) async {
    final updated = item.copyWith(isActive: !item.isActive);
    await _recurringRepo.update(updated);
    HapticFeedback.lightImpact();
    _loadData();
  }

  Future<void> _applyDueTransaction(RecurringTransactionModel item) async {
    final isArabic = context.isArabic;
    // تطبيق المعاملة الآن في جدول المعاملات
    final tx = TransactionModel(
      title: item.title,
      amount: item.amount,
      type: item.type,
      categoryId: item.categoryId,
      date: DateTime.now(),
      notes: isArabic
          ? 'تمت إضافتها آلياً من المعاملات المتكررة'
          : 'Automatically added from recurring transactions',
      isRecurring: true,
    );
    await _transactionRepo.insert(tx);

    // ترحيل تاريخ التشغيل القادم
    DateTime nextDate;
    final currentNext = item.nextRunDate;
    switch (item.frequency) {
      case 'daily':
        nextDate = currentNext.add(const Duration(days: 1));
        break;
      case 'weekly':
        nextDate = currentNext.add(const Duration(days: 7));
        break;
      case 'yearly':
        nextDate = DateTime(currentNext.year + 1, currentNext.month, currentNext.day);
        break;
      case 'monthly':
      default:
        nextDate = DateTime(currentNext.year, currentNext.month + 1, currentNext.day);
        break;
    }

    if (item.id != null) {
      await _recurringRepo.advanceNextRunDate(item.id!, nextDate);
    }

    HapticFeedback.mediumImpact();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isArabic
            ? '✅ تم تسجيل معاملة "${item.title}" في المحفظة'
            : '✅ Transaction "${item.title}" recorded to wallet'),
        backgroundColor: AppColors.income,
      ),
    );
    _loadData();
  }

  Future<void> _showAddOrEditDialog([RecurringTransactionModel? existing]) async {
    final isArabic = context.isArabic;
    final loc = context.loc;
    final titleController = TextEditingController(text: existing?.title ?? '');
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toString() : '',
    );
    bool isIncome = existing?.isIncome ?? false;
    String frequency = existing?.frequency ?? 'monthly';
    CategoryModel? selectedCategory;
    DateTime nextRunDate = existing?.nextRunDate ?? DateTime.now();
    final formKey = GlobalKey<FormState>();

    if (existing?.categoryId != null) {
      final match = _categories.where((c) => c.id == existing!.categoryId);
      if (match.isNotEmpty) selectedCategory = match.first;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          final filteredCategories = _categories.where((c) => c.isIncome == isIncome).toList();

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existing == null
                              ? (isArabic ? 'إضافة معاملة دورية جديدة' : 'New Recurring Transaction')
                              : (isArabic ? 'تعديل المعاملة الدورية' : 'Edit Recurring Transaction'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // محدد نوع المعاملة (دخل/مصروف)
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Center(child: Text(isArabic ? 'مصروف دوري' : 'Recurring Expense')),
                            selected: !isIncome,
                            selectedColor: AppColors.expense,
                            labelStyle: TextStyle(
                              color: !isIncome ? Colors.white : null,
                              fontWeight: FontWeight.w700,
                            ),
                            onSelected: (val) {
                              setModalState(() {
                                isIncome = false;
                                selectedCategory = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: Center(child: Text(isArabic ? 'دخل دوري' : 'Recurring Income')),
                            selected: isIncome,
                            selectedColor: AppColors.income,
                            labelStyle: TextStyle(
                              color: isIncome ? Colors.white : null,
                              fontWeight: FontWeight.w700,
                            ),
                            onSelected: (val) {
                              setModalState(() {
                                isIncome = true;
                                selectedCategory = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: titleController,
                      labelText: isArabic ? 'عنوان المعاملة' : 'Transaction Title',
                      hintText: isArabic
                          ? 'مثلاً: إيجار الشقة، اشتراك إنترنت، راتب شهري'
                          : 'e.g. Rent, Internet bill, Monthly salary',
                      validator: (val) =>
                          (val == null || val.trim().isEmpty)
                              ? (isArabic ? 'الرجاء إدخال العنوان' : 'Please enter title')
                              : null,
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: amountController,
                      labelText: loc.translate('amount'),
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
                    const SizedBox(height: 16),

                    // التكرار الدوري
                    DropdownButtonFormField<String>(
                      initialValue: frequency,
                      decoration: InputDecoration(labelText: loc.translate('frequency')),
                      items: [
                        DropdownMenuItem(value: 'daily', child: Text(loc.translate('daily'))),
                        DropdownMenuItem(value: 'weekly', child: Text(loc.translate('weekly'))),
                        DropdownMenuItem(value: 'monthly', child: Text(loc.translate('monthly'))),
                        DropdownMenuItem(value: 'yearly', child: Text(loc.translate('yearly'))),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => frequency = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // اختيار التصنيف
                    if (filteredCategories.isNotEmpty)
                      DropdownButtonFormField<CategoryModel?>(
                        initialValue: selectedCategory,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'التصنيف (اختياري)' : 'Category (Optional)',
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(isArabic ? 'بدون تصنيف' : 'Uncategorized'),
                          ),
                          ...filteredCategories.map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.localizedName(isArabic: isArabic)),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setModalState(() => selectedCategory = val);
                        },
                      ),
                    const SizedBox(height: 24),

                    AppButton(
                      text: existing == null
                          ? (isArabic ? 'إضافة المعاملة الدورية' : 'Add Recurring Transaction')
                          : loc.translate('save'),
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final title = titleController.text.trim();
                        final amount = double.parse(amountController.text.trim());

                        final model = RecurringTransactionModel(
                          id: existing?.id,
                          title: title,
                          amount: amount,
                          type: isIncome ? 'income' : 'expense',
                          frequency: frequency,
                          categoryId: selectedCategory?.id,
                          nextRunDate: nextRunDate,
                          isActive: existing?.isActive ?? true,
                        );

                        if (existing == null) {
                          await _recurringRepo.insert(model);
                        } else {
                          await _recurringRepo.update(model);
                        }

                        HapticFeedback.mediumImpact();
                        if (!modalContext.mounted) return;
                        Navigator.of(ctx).pop();
                        _loadData();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteItem(RecurringTransactionModel item) async {
    final isArabic = context.isArabic;
    final loc = context.loc;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'حذف المعاملة الدورية' : 'Delete Recurring Transaction'),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من حذف "${item.title}"؟'
              : 'Are you sure you want to delete "${item.title}"?',
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

    if (confirmed == true && item.id != null) {
      await _recurringRepo.delete(item.id!);
      HapticFeedback.mediumImpact();
      _loadData();
    }
  }

  String _getFrequencyLabel(String freq, AppLocalizations loc) {
    switch (freq) {
      case 'daily':
        return loc.translate('daily');
      case 'weekly':
        return loc.translate('weekly');
      case 'yearly':
        return loc.translate('yearly');
      case 'monthly':
      default:
        return loc.translate('monthly');
    }
  }

  @override
  Widget build(BuildContext context) {
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
          appBar: AppBar(
            title: Text(loc.translate('recurringTitle')),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddOrEditDialog(),
            icon: const Icon(Icons.add_rounded),
            label: Text(loc.translate('newRecurring')),
          ),
      body: _items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.repeat_rounded,
                        size: 48,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      loc.translate('noRecurring'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.translate('noRecurringSub'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      text: loc.translate('newRecurring'),
                      icon: Icons.add_rounded,
                      onPressed: () => _showAddOrEditDialog(),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final isIncome = item.isIncome;
                  final nextDateStr = DateFormat('yyyy/MM/dd', 'ar').format(item.nextRunDate);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: item.isDue
                            ? AppColors.warning.withAlpha(128)
                            : (isDark ? AppColors.darkBorder : AppColors.border),
                        width: item.isDue ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isIncome ? AppColors.income : AppColors.expense).withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                color: isIncome ? AppColors.income : AppColors.expense,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: item.isActive
                                                ? null
                                                : (isDark
                                                    ? AppColors.darkTextSecondary
                                                    : AppColors.textSecondary),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!item.isActive) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withAlpha(35),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            loc.translate('inactiveBadge'),
                                            style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${_getFrequencyLabel(item.frequency, loc)} • ${loc.translate('nextDue')}: $nextDateStr',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyService.format(
                                item.amount,
                                isArabic: isArabic,
                                showSign: true,
                                isIncome: isIncome,
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: item.isActive
                                    ? (isIncome ? AppColors.income : AppColors.expense)
                                    : Colors.grey,
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, size: 20),
                              padding: EdgeInsets.zero,
                              tooltip: isArabic ? 'خيارات إضافية' : 'More Options',
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              onSelected: (val) {
                                switch (val) {
                                  case 'edit':
                                    _showAddOrEditDialog(item);
                                    break;
                                  case 'toggle':
                                    _toggleActive(item);
                                    break;
                                  case 'apply':
                                    _applyDueTransaction(item);
                                    break;
                                  case 'delete':
                                    _deleteItem(item);
                                    break;
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit_outlined, size: 18),
                                      const SizedBox(width: 10),
                                      Text(loc.translate('editTransaction')),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.isActive
                                            ? Icons.pause_circle_outline_rounded
                                            : Icons.play_circle_outline_rounded,
                                        size: 18,
                                        color: item.isActive ? AppColors.warning : AppColors.income,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(item.isActive ? loc.translate('deactivate') : loc.translate('activate')),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'apply',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.playlist_add_check_rounded, size: 18, color: AppColors.primary),
                                      const SizedBox(width: 10),
                                      Text(loc.translate('applyDueNow')),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expense),
                                      const SizedBox(width: 10),
                                      Text(loc.translate('delete'), style: const TextStyle(color: AppColors.expense)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // في حال كانت مستحقة التطبيق الآن
                        if (item.isDue && item.isActive) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.alarm_on_rounded, color: AppColors.warning, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isArabic ? 'مستحقة التنفيذ الآن!' : 'Due for execution now!',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.warning,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                  onPressed: () => _applyDueTransaction(item),
                                  child: Text(isArabic ? 'تسجيل بالمحفظة' : 'Record Now'),
                                ),
                              ],
                            ),
                          ),
                        ],
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
