import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:bashnddof/src/core/models/envelope_model.dart';
import 'package:bashnddof/src/core/repositories/envelope_repository.dart';
import 'package:bashnddof/src/core/theme/app_colors.dart';
import 'package:bashnddof/src/core/widgets/app_button.dart';
import 'package:bashnddof/src/core/widgets/app_text_field.dart';
import 'package:bashnddof/src/core/widgets/artistic_illustrations.dart';
import 'package:bashnddof/src/core/currency/currency_service.dart';
import 'package:bashnddof/src/core/localization/app_localizations.dart';

/// شاشة إدارة ميزانية الأظرف المالية (Envelope Budgeting Screen)
class EnvelopesScreen extends StatefulWidget {
  final bool showAppBar;
  const EnvelopesScreen({super.key, this.showAppBar = false});

  @override
  State<EnvelopesScreen> createState() => _EnvelopesScreenState();
}

class _EnvelopesScreenState extends State<EnvelopesScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _envelopeRepo = EnvelopeRepository();

  List<EnvelopeModel> _envelopes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnvelopes();
  }

  Future<void> _loadEnvelopes() async {
    setState(() => _isLoading = true);
    final data = await _envelopeRepo.getAll();
    if (mounted) {
      setState(() {
        _envelopes = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddOrEditDialog([EnvelopeModel? existing]) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final amountController = TextEditingController(
      text: existing != null ? existing.allocatedAmount.toString() : '',
    );
    int selectedColor = existing?.color ?? AppColors.envelopeColors.first.toARGB32();
    final formKey = GlobalKey<FormState>();
    final isArabic = context.isArabic;
    final loc = context.loc;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
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
                            ? (isArabic ? 'إضافة ظرف ميزانية جديد' : 'New Budget Envelope')
                            : (isArabic ? 'تعديل ظرف الميزانية' : 'Edit Budget Envelope'),
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
                    labelText: isArabic ? 'اسم الظرف' : 'Envelope Name',
                    hintText: isArabic ? 'مثلاً: بقالة، ترفيه، وقود السيارة' : 'e.g., Groceries, Dining, Fuel',
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? (isArabic ? 'الرجاء إدخال اسم الظرف' : 'Please enter envelope name') : null,
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: amountController,
                    labelText: '${loc.translate('allocatedBudget')} (${CurrencyService.getSymbol(isArabic)})',
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

                  // اختيار لون الظرف
                  Text(
                    isArabic ? 'لون الظرف' : 'Envelope Color',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: AppColors.envelopeColors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final color = AppColors.envelopeColors[i];
                        final isSelected = selectedColor == color.toARGB32();

                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedColor = color.toARGB32();
                            });
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withAlpha(128),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  AppButton(
                    text: existing == null
                        ? (isArabic ? 'إنشاء الظرف' : 'Create Envelope')
                        : (isArabic ? 'حفظ التعديلات' : 'Save Changes'),
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final name = nameController.text.trim();
                      final amount = double.parse(amountController.text.trim());

                      if (existing == null) {
                        await _envelopeRepo.insert(
                          EnvelopeModel(
                            name: name,
                            allocatedAmount: amount,
                            color: selectedColor,
                          ),
                        );
                      } else {
                        await _envelopeRepo.update(
                          existing.copyWith(
                            name: name,
                            allocatedAmount: amount,
                            color: selectedColor,
                          ),
                        );
                      }

                      HapticFeedback.mediumImpact();
                      if (!modalContext.mounted) return;
                      Navigator.of(ctx).pop();
                      _loadEnvelopes();
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

  Future<void> _deleteEnvelope(EnvelopeModel env) async {
    final isArabic = context.isArabic;
    final loc = context.loc;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'حذف الظرف' : 'Delete Envelope'),
        content: Text(isArabic
            ? 'هل أنت متأكد من حذف ظرف "${env.name}"؟'
            : 'Are you sure you want to delete envelope "${env.name}"?'),
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

    if (confirmed == true && env.id != null) {
      await _envelopeRepo.delete(env.id!);
      HapticFeedback.mediumImpact();
      _loadEnvelopes();
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
                  title: Text(loc.translate('budgetEnvelopes')),
                )
              : null,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddOrEditDialog(),
            icon: const Icon(Icons.add_rounded),
            label: Text(loc.translate('newEnvelope')),
          ),
      body: RefreshIndicator(
        onRefresh: _loadEnvelopes,
        child: _envelopes.isEmpty
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
                              ArtisticEnvelopeIllustration(size: 150),
                              const SizedBox(height: 20),
                              Text(
                                loc.translate('noEnvelopes'),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                loc.translate('noEnvelopesSub'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              AppButton(
                                text: loc.translate('addEnvelope'),
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
                itemCount: _envelopes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final env = _envelopes[index];
                  final percent = env.spentPercentage.clamp(0.0, 1.0);
                  final isOver = env.isOverBudget;
                  final envelopeColor = Color(env.color);

                  Color statusColor;
                  if (isOver) {
                    statusColor = AppColors.expense;
                  } else if (percent >= 0.8) {
                    statusColor = AppColors.warning;
                  } else {
                    statusColor = AppColors.income;
                  }

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOver
                            ? AppColors.expense.withAlpha(128)
                            : (isDark ? AppColors.darkBorder : AppColors.border),
                        width: isOver ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // رأس بطاقة الظرف
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: envelopeColor.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.mail_rounded, color: envelopeColor, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                env.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
                                  _showAddOrEditDialog(env);
                                } else if (val == 'delete') {
                                  _deleteEnvelope(env);
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit_outlined, size: 18),
                                      const SizedBox(width: 8),
                                      Text(loc.translate('editEnvelope')),
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

                        // إحصائيات الصرف والميزانية
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                '${loc.translate('spent')}: ${CurrencyService.format(env.spentAmount, isArabic: isArabic)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${loc.translate('allocatedBudget')}: ${CurrencyService.format(env.allocatedAmount, isArabic: isArabic)}',
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

                        // شريط التقدم اللوني
                        LinearPercentIndicator(
                          lineHeight: 10.0,
                          percent: percent,
                          progressColor: statusColor,
                          backgroundColor: isDark
                              ? AppColors.darkSurfaceAlt
                              : AppColors.surfaceAlt,
                          barRadius: const Radius.circular(8),
                          padding: EdgeInsets.zero,
                          animation: true,
                          animationDuration: 600,
                        ),
                        const SizedBox(height: 10),

                        // حالة المتبقي أو الفائض
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                isOver
                                    ? '⚠️ ${loc.translate('overBudget')} ${CurrencyService.format(env.spentAmount - env.allocatedAmount, isArabic: isArabic)}'
                                    : '${loc.translate('remaining')}: ${CurrencyService.format(env.remainingAmount, isArabic: isArabic)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(env.spentPercentage * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
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
