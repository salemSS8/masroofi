import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:bashnddof/src/core/models/category_model.dart';
import 'package:bashnddof/src/core/models/envelope_model.dart';
import 'package:bashnddof/src/core/models/transaction_model.dart';
import 'package:bashnddof/src/core/repositories/category_repository.dart';
import 'package:bashnddof/src/core/repositories/envelope_repository.dart';
import 'package:bashnddof/src/core/repositories/transaction_repository.dart';
import 'package:bashnddof/src/core/services/notification_service.dart';
import 'package:bashnddof/src/core/theme/app_colors.dart';
import 'package:bashnddof/src/core/widgets/app_button.dart';
import 'package:bashnddof/src/core/widgets/app_text_field.dart';
import 'package:bashnddof/src/core/currency/currency_service.dart';
import 'package:bashnddof/src/core/localization/app_localizations.dart';
import 'package:bashnddof/src/core/localization/language_service.dart';

/// شاشة إضافة معاملة مالية جديدة بتجربة مستخدم متكاملة ومحفوظة فعلياً
class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? editTransaction;

  const AddTransactionScreen({super.key, this.editTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  final _transactionRepo = TransactionRepository();
  final _categoryRepo = CategoryRepository();
  final _envelopeRepo = EnvelopeRepository();

  bool _isIncome = false;
  bool _isRecurring = false;
  DateTime _selectedDate = DateTime.now();
  CategoryModel? _selectedCategory;
  EnvelopeModel? _selectedEnvelope;

  List<CategoryModel> _availableCategories = [];
  List<EnvelopeModel> _availableEnvelopes = [];
  bool _isLoadingData = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editTransaction != null) {
      final tx = widget.editTransaction!;
      final isAr = LanguageService.isArabic;
      _isIncome = tx.isIncome;
      _isRecurring = tx.isRecurring;
      _amountController.text = tx.amount.toString();
      _titleController.text = CategoryModel.localizeName(tx.title, isArabic: isAr);
      String note = tx.notes ?? '';
      if (!isAr && note == 'تمت إضافتها آلياً من المعاملات المتكررة') {
        note = 'Automatically added from recurring transactions';
      } else if (isAr && note == 'Automatically added from recurring transactions') {
        note = 'تمت إضافتها آلياً من المعاملات المتكررة';
      }
      _notesController.text = note;
      _selectedDate = tx.date;
    }
    _loadInitialData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);
    final categories = await _categoryRepo.getAll(isIncome: _isIncome);
    final envelopes = await _envelopeRepo.getAll();

    if (mounted) {
      setState(() {
        _availableCategories = categories;
        _availableEnvelopes = envelopes;

        if (widget.editTransaction != null) {
          final catId = widget.editTransaction!.categoryId;
          if (catId != null) {
            final match = categories.where((c) => c.id == catId);
            if (match.isNotEmpty) _selectedCategory = match.first;
          }
          final envId = widget.editTransaction!.envelopeId;
          if (envId != null) {
            final match = envelopes.where((e) => e.id == envId);
            if (match.isNotEmpty) _selectedEnvelope = match.first;
          }
        } else if (_availableCategories.isNotEmpty) {
          _selectedCategory = _availableCategories.first;
        }

        _isLoadingData = false;
      });
    }
  }

  Future<void> _onTypeChanged(bool isIncome) async {
    if (_isIncome == isIncome) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isIncome = isIncome;
      _selectedCategory = null;
      _selectedEnvelope = null;
    });

    final categories = await _categoryRepo.getAll(isIncome: _isIncome);
    if (mounted) {
      setState(() {
        _availableCategories = categories;
        if (categories.isNotEmpty) {
          _selectedCategory = categories.first;
        }
      });
    }
  }

  Future<void> _selectDate() async {
    HapticFeedback.lightImpact();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('ar'),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    final isArabic = context.isArabic;
    final loc = context.loc;
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic
              ? 'الرجاء إدخال مبلغ صحيح أكبر من الصفر'
              : 'Please enter a valid amount greater than zero'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final title = _titleController.text.trim().isEmpty
        ? (_selectedCategory?.localizedName(isArabic: isArabic) ??
            (_isIncome ? loc.translate('income') : loc.translate('expense')))
        : _titleController.text.trim();

    final model = TransactionModel(
      id: widget.editTransaction?.id,
      title: title,
      amount: amount,
      type: _isIncome ? 'income' : 'expense',
      categoryId: _selectedCategory?.id,
      envelopeId: _isIncome ? null : _selectedEnvelope?.id,
      date: _selectedDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isRecurring: _isRecurring,
    );

    if (widget.editTransaction == null) {
      await _transactionRepo.insert(model);
    } else {
      await _transactionRepo.update(model);
    }

    // تنبيه محلي فوري عند اقتراب أو تجاوز سقف ميزانية الظرف
    if (!_isIncome && _selectedEnvelope?.id != null) {
      try {
        final envRepo = EnvelopeRepository();
        final updatedEnv = await envRepo.getById(_selectedEnvelope!.id!);
        if (updatedEnv != null) {
          NotificationService().notifyBudgetStatus(
            envelopeName: updatedEnv.name,
            percent: updatedEnv.spentPercentage,
          );
        }
      } catch (_) {}
    }

    HapticFeedback.mediumImpact();
    if (!mounted) return;

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.editTransaction == null
            ? (isArabic ? '✅ تم حفظ المعاملة بنجاح' : '✅ Transaction saved successfully')
            : (isArabic ? '✅ تم تعديل المعاملة بنجاح' : '✅ Transaction updated successfully')),
        backgroundColor: AppColors.income,
      ),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _deleteTransaction() async {
    if (widget.editTransaction?.id == null) return;
    final isArabic = context.isArabic;
    final loc = context.loc;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.translate('delete')),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من حذف معاملة "${widget.editTransaction!.title}"؟'
              : 'Are you sure you want to delete "${widget.editTransaction!.title}"?',
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

    if (confirmed == true) {
      await _transactionRepo.delete(widget.editTransaction!.id!);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('transactionDeleted')),
          backgroundColor: AppColors.expense,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'receipt_long':
        return Icons.receipt_long_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'movie':
        return Icons.movie_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'payments':
        return Icons.payments_rounded;
      case 'laptop_mac':
        return Icons.laptop_mac_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'savings':
        return Icons.savings_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.isArabic;
    final loc = context.loc;
    final dateStr = DateFormat('yyyy/MM/dd', isArabic ? 'ar' : 'en').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editTransaction == null
            ? loc.translate('addNewTransaction')
            : loc.translate('editTransaction')),
        actions: [
          if (widget.editTransaction != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
              tooltip: loc.translate('delete'),
              onPressed: _deleteTransaction,
            ),
        ],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // بطاقة تمييز المعاملة: لمرة واحدة أم دورية متكررة
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isRecurring
                            ? const Color(0xFFF59E0B).withAlpha(20)
                            : AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isRecurring
                              ? const Color(0xFFF59E0B).withAlpha(80)
                              : AppColors.primary.withAlpha(60),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (_isRecurring
                                      ? const Color(0xFFF59E0B)
                                      : AppColors.primary)
                                  .withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isRecurring
                                  ? Icons.repeat_rounded
                                  : Icons.flash_on_rounded,
                              size: 18,
                              color: _isRecurring
                                  ? const Color(0xFFF59E0B)
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isRecurring
                                      ? loc.translate('recurringBadge')
                                      : loc.translate('oneTimeBadge'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _isRecurring
                                        ? const Color(0xFFD97706)
                                        : (isDark
                                            ? Colors.white
                                            : AppColors.primaryDark),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isRecurring
                                      ? loc.translate('recurringDescription')
                                      : loc.translate('oneTimeDescription'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // محدد نوع المعاملة: مصروف مقابل دخل
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _onTypeChanged(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isIncome
                                      ? AppColors.expense
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '💸 ${loc.translate('expense')}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: !_isIncome ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _onTypeChanged(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isIncome
                                      ? AppColors.income
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '💰 ${loc.translate('income')}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _isIncome ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // إدخال المبلغ بخط عريض وبارز
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.translate('amount'),
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                CurrencyService.getSymbol(isArabic),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: _isIncome ? AppColors.income : AppColors.expense,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _amountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: _isIncome ? AppColors.income : AppColors.expense,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: '0.00',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return loc.translate('enterValidAmount');
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // عنوان المعاملة / الوصف
                    AppTextField(
                      controller: _titleController,
                      labelText: isArabic
                          ? 'عنوان المعاملة (اختياري)'
                          : 'Transaction Title (Optional)',
                      hintText: isArabic
                          ? 'مثلاً: غداء، مشتريات البقالة، فاتورة كهرباء'
                          : 'e.g. Lunch, Groceries, Electricity bill',
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                    ),
                    const SizedBox(height: 20),

                    // اختيار التصنيف
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.translate('category'),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 50,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _availableCategories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final cat = _availableCategories[index];
                              final isSelected = _selectedCategory?.id == cat.id;

                              return ChoiceChip(
                                label: Text(cat.localizedName(isArabic: isArabic)),
                                avatar: Icon(
                                  _getCategoryIcon(cat.icon),
                                  size: 18,
                                  color: isSelected ? Colors.white : Color(cat.color),
                                ),
                                selected: isSelected,
                                selectedColor: Color(cat.color),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : null,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedCategory = cat);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // اختيار الظرف المالي (في حال كان مصروف)
                    if (!_isIncome && _availableEnvelopes.isNotEmpty) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic
                                ? 'الخصم من ظرف الميزانية (اختياري)'
                                : 'Deduct from Budget Envelope (Optional)',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<EnvelopeModel?>(
                            initialValue: _selectedEnvelope,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.mail_outline_rounded),
                              hintText: loc.translate('noEnvelope'),
                            ),
                            items: [
                              DropdownMenuItem<EnvelopeModel?>(
                                value: null,
                                child: Text(loc.translate('noEnvelope')),
                              ),
                              ..._availableEnvelopes.map(
                                (env) => DropdownMenuItem<EnvelopeModel?>(
                                  value: env,
                                  child: Text('${env.name} (${isArabic ? "المتبقي" : "Remaining"}: ${CurrencyService.format(env.remainingAmount, isArabic: isArabic, decimalDigits: 1)})'),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedEnvelope = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // اختيار التاريخ
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic ? 'تاريخ المعاملة' : 'Transaction Date',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                Text(
                                  dateStr,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ملاحظات إضافية
                    AppTextField(
                      controller: _notesController,
                      labelText: isArabic
                          ? 'ملاحظة إضافية (اختياري)'
                          : 'Additional Notes (Optional)',
                      hintText: isArabic
                          ? 'تفاصيل إضافية عن المعاملة...'
                          : 'Additional transaction details...',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),

                    // زر الحفظ الفعلي
                    AppButton(
                      text: widget.editTransaction == null
                          ? loc.translate('save')
                          : loc.translate('save'),
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _isSaving,
                      onPressed: _saveTransaction,
                    ),

                    if (widget.editTransaction != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.expense,
                          side: const BorderSide(color: AppColors.expense),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        label: Text(
                          loc.translate('deleteThisTransaction'),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        onPressed: _deleteTransaction,
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
