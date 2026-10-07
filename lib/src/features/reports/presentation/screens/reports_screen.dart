import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:bashnddof/src/core/models/category_model.dart';
import 'package:bashnddof/src/core/models/envelope_model.dart';
import 'package:bashnddof/src/core/models/savings_goal_model.dart';
import 'package:bashnddof/src/core/repositories/envelope_repository.dart';
import 'package:bashnddof/src/core/repositories/savings_goal_repository.dart';
import 'package:bashnddof/src/core/repositories/transaction_repository.dart';
import 'package:bashnddof/src/core/theme/app_colors.dart';
import 'package:bashnddof/src/core/widgets/artistic_illustrations.dart';
import 'package:bashnddof/src/core/currency/currency_service.dart';
import 'package:bashnddof/src/core/localization/app_localizations.dart';

/// شاشة التقارير والإحصائيات المالية المتقدمة مع تضمين أهداف الادخار وميزانيات الأظرف
class ReportsScreen extends StatefulWidget {
  final bool showAppBar;
  const ReportsScreen({super.key, this.showAppBar = false});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _transactionRepo = TransactionRepository();
  final _goalRepo = SavingsGoalRepository();
  final _envelopeRepo = EnvelopeRepository();

  int _selectedPeriod = 0; // 0: هذا الشهر, 1: الشهر السابق, 2: السنة الحالية, 3: الكل
  int? _touchedIndex;

  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  List<Map<String, dynamic>> _categoryExpenses = [];

  List<SavingsGoalModel> _goals = [];
  double _totalSavedGoals = 0.0;
  double _totalTargetGoals = 0.0;

  List<EnvelopeModel> _envelopes = [];
  double _totalAllocatedEnvelopes = 0.0;
  double _totalSpentEnvelopes = 0.0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  (DateTime?, DateTime?) _getDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 0: // هذا الشهر
        final from = DateTime(now.year, now.month, 1);
        final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return (from, to);
      case 1: // الشهر السابق
        final from = DateTime(now.year, now.month - 1, 1);
        final to = DateTime(now.year, now.month, 0, 23, 59, 59);
        return (from, to);
      case 2: // هذا العام
        final from = DateTime(now.year, 1, 1);
        final to = DateTime(now.year, 12, 31, 23, 59, 59);
        return (from, to);
      default: // الكل
        return (null, null);
    }
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    final (from, to) = _getDateRange();
    final income = await _transactionRepo.getTotalIncome(from: from, to: to);
    final expenses = await _transactionRepo.getTotalExpenses(from: from, to: to);
    final catExpenses = await _transactionRepo.getExpensesByCategory(from: from, to: to);

    final goals = await _goalRepo.getAll();
    final envelopes = await _envelopeRepo.getAll();

    final savedGoals = goals.fold<double>(0.0, (sum, g) => sum + g.currentAmount);
    final targetGoals = goals.fold<double>(0.0, (sum, g) => sum + g.targetAmount);

    final allocatedEnv = envelopes.fold<double>(0.0, (sum, e) => sum + e.allocatedAmount);
    final spentEnv = envelopes.fold<double>(0.0, (sum, e) => sum + e.spentAmount);

    if (mounted) {
      setState(() {
        _totalIncome = income;
        _totalExpenses = expenses;
        _categoryExpenses = catExpenses;
        _goals = goals;
        _totalSavedGoals = savedGoals;
        _totalTargetGoals = targetGoals;
        _envelopes = envelopes;
        _totalAllocatedEnvelopes = allocatedEnv;
        _totalSpentEnvelopes = spentEnv;
        _isLoading = false;
      });
    }
  }

  void _onPeriodChanged(int index) {
    if (_selectedPeriod == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPeriod = index;
    });
    _loadReportData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.isArabic;
    final loc = context.loc;
    final netSavings = _totalIncome - _totalExpenses;
    final savingsRate = _totalIncome > 0
        ? ((netSavings + _totalSavedGoals) / (_totalIncome + _totalSavedGoals) * 100).clamp(0.0, 100.0)
        : (_totalSavedGoals > 0 ? 100.0 : 0.0);

    return ValueListenableBuilder<CurrencyModel>(
      valueListenable: CurrencyService.currencyNotifier,
      builder: (context, _, __) {
        return Scaffold(
          appBar: widget.showAppBar
              ? AppBar(
                  title: Text(loc.translate('financialReports')),
                )
              : null,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadReportData,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    children: [
                      // شريط اختيار الفترة الزمنية
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildPeriodTab(0, loc.translate('thisMonth')),
                            _buildPeriodTab(1, loc.translate('lastMonth')),
                            _buildPeriodTab(2, loc.translate('thisYear')),
                            _buildPeriodTab(3, loc.translate('allTime')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                  // ملخص الدخل، المصروفات، المدخرات، والأظرف
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        // صف الدخل والمصروفات
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryMetric(
                                label: loc.translate('totalIncome'),
                                amount: _totalIncome,
                                color: AppColors.income,
                                icon: Icons.arrow_downward_rounded,
                              ),
                            ),
                            Container(width: 1, height: 40, color: isDark ? AppColors.darkBorder : AppColors.border),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSummaryMetric(
                                label: loc.translate('totalExpenses'),
                                amount: _totalExpenses,
                                color: AppColors.expense,
                                icon: Icons.arrow_upward_rounded,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // صف أموال المدخرات وأموال الأظرف
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryMetric(
                                label: isArabic ? 'أموال الادخار المجمعة' : 'Accumulated Savings',
                                amount: _totalSavedGoals,
                                color: const Color(0xFF8B5CF6),
                                icon: Icons.savings_rounded,
                              ),
                            ),
                            Container(width: 1, height: 40, color: isDark ? AppColors.darkBorder : AppColors.border),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSummaryMetric(
                                label: isArabic ? 'ميزانية الأظرف الكلية' : 'Total Envelope Budget',
                                amount: _totalAllocatedEnvelopes,
                                color: const Color(0xFF3B82F6),
                                icon: Icons.mail_outline_rounded,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // صف صافي التوفير / الفائض ومعدل الادخار (محمي من الـ Overflow)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.translate('netSavings'),
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      CurrencyService.format(netSavings, isArabic: isArabic),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: netSavings >= 0 ? AppColors.income : AppColors.expense,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: (savingsRate > 20 ? AppColors.income : AppColors.warning).withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${loc.translate("savingsRate")}: ${savingsRate.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: savingsRate > 20 ? AppColors.income : AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1. قسم توزيع المصروفات حسب التصنيف
                  Text(
                    loc.translate('expenseBreakdown'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),

                  if (_categoryExpenses.isEmpty || _totalExpenses <= 0)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          const ArtisticAnalyticsIllustration(size: 120),
                          const SizedBox(height: 14),
                          Text(
                            isArabic
                                ? 'لا توجد مصروفات مسجلة لهذه الفترة'
                                : 'No expenses recorded for this period',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isArabic
                                ? 'عند تسجيل مصروفاتك، ستظهر هنا رسوم بيانية توضح أين تذهب أموالك.'
                                : 'When you record your expenses, visual charts will show where your money goes.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // الرسم البياني الدائري (PieChart)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                      child: SizedBox(
                        height: 220,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = pieTouchResponse
                                      .touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 3,
                            centerSpaceRadius: 40,
                            sections: List.generate(_categoryExpenses.length, (i) {
                              final item = _categoryExpenses[i];
                              final isTouched = i == _touchedIndex;
                              final fontSize = isTouched ? 16.0 : 12.0;
                              final radius = isTouched ? 65.0 : 55.0;
                              final amount = (item['total_amount'] as num).toDouble();
                              final percentage = (amount / _totalExpenses) * 100;
                              final color = Color((item['category_color'] as num).toInt());

                              return PieChartSectionData(
                                color: color,
                                value: amount,
                                title: '${percentage.toStringAsFixed(0)}%',
                                radius: radius,
                                titleStyle: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // تفاصيل التصنيفات وقيمها (محمية من الـ Overflow)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _categoryExpenses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _categoryExpenses[index];
                        final rawName = item['category_name'] as String;
                        final name = CategoryModel.localizeName(rawName, isArabic: isArabic);
                        final amount = (item['total_amount'] as num).toDouble();
                        final percentage = (amount / _totalExpenses) * 100;
                        final color = Color((item['category_color'] as num).toInt());

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                CurrencyService.format(amount, isArabic: isArabic),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 32),

                  // 2. قسم تقرير أهداف الادخار والوفر المالي
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.savings_rounded, color: Color(0xFF8B5CF6), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            loc.translate('savingsReport'),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      if (_goals.isNotEmpty)
                        Text(
                          isArabic ? '${_goals.length} أهداف' : '${_goals.length} goals',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_goals.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF8B5CF6), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? 'لم تقم بإنشاء أهداف ادخار بعد. أضف أهدافك لتتبع مبالغك المدخرة ونسب إنجازها في هذا التقرير.'
                                  : 'No savings goals created yet. Add goals to track your saved amounts and progress here.',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // بطاقة ملخص الادخار العام
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '${loc.translate('totalSaved')}: ${CurrencyService.format(_totalSavedGoals, isArabic: isArabic)}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF8B5CF6)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${loc.translate('target')}: ${CurrencyService.format(_totalTargetGoals, isArabic: isArabic)}',
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
                            lineHeight: 8.0,
                            percent: _totalTargetGoals > 0 ? (_totalSavedGoals / _totalTargetGoals).clamp(0.0, 1.0) : 0.0,
                            progressColor: const Color(0xFF8B5CF6),
                            backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                            barRadius: const Radius.circular(8),
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isArabic ? 'نسبة الإنجاز الإجمالية للأهداف' : 'Total Goals Progress Rate',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              Text(
                                '${_totalTargetGoals > 0 ? (_totalSavedGoals / _totalTargetGoals * 100).toStringAsFixed(1) : 0}%',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // قائمة أهداف الادخار
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _goals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final g = _goals[index];
                        final p = g.targetAmount > 0 ? (g.currentAmount / g.targetAmount).clamp(0.0, 1.0) : 0.0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      g.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${CurrencyService.format(g.currentAmount, isArabic: isArabic)} / ${CurrencyService.format(g.targetAmount, isArabic: isArabic)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearPercentIndicator(
                                lineHeight: 6.0,
                                percent: p,
                                progressColor: p >= 1.0 ? AppColors.income : const Color(0xFF8B5CF6),
                                backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                                barRadius: const Radius.circular(6),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 32),

                  // 3. قسم تقرير ميزانيات الأظرف المالية
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mail_rounded, color: Color(0xFF3B82F6), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            loc.translate('envelopesReport'),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      if (_envelopes.isNotEmpty)
                        Text(
                          isArabic ? '${_envelopes.length} أظرف' : '${_envelopes.length} envelopes',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_envelopes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? 'لا توجد أظرف ميزانية حتى الآن. أنشئ أظرفك المالية لتتبع المبالغ المخصصة لكل وجه صرف والمتبقي منها.'
                                  : 'No budget envelopes yet. Create envelopes to track allocated and remaining budgets.',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // ملخص الأظرف الكلي
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '${loc.translate('totalAllocated')}: ${CurrencyService.format(_totalAllocatedEnvelopes, isArabic: isArabic)}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF3B82F6)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${loc.translate('spent')}: ${CurrencyService.format(_totalSpentEnvelopes, isArabic: isArabic)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _totalSpentEnvelopes > _totalAllocatedEnvelopes ? AppColors.expense : AppColors.income,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearPercentIndicator(
                            lineHeight: 8.0,
                            percent: _totalAllocatedEnvelopes > 0
                                ? (_totalSpentEnvelopes / _totalAllocatedEnvelopes).clamp(0.0, 1.0)
                                : 0.0,
                            progressColor: _totalSpentEnvelopes > _totalAllocatedEnvelopes
                                ? AppColors.expense
                                : const Color(0xFF3B82F6),
                            backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                            barRadius: const Radius.circular(8),
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${loc.translate('remaining')}: ${CurrencyService.format((_totalAllocatedEnvelopes - _totalSpentEnvelopes).clamp(0.0, double.infinity), isArabic: isArabic)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              Text(
                                '${_totalAllocatedEnvelopes > 0 ? (_totalSpentEnvelopes / _totalAllocatedEnvelopes * 100).toStringAsFixed(0) : 0}%',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // قائمة أداء كل ظرف
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _envelopes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final env = _envelopes[index];
                        final envColor = Color(env.color);
                        final p = env.spentPercentage.clamp(0.0, 1.0);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: env.isOverBudget
                                  ? AppColors.expense.withAlpha(120)
                                  : (isDark ? AppColors.darkBorder : AppColors.border),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: envColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      env.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${CurrencyService.format(env.spentAmount, isArabic: isArabic)} ${isArabic ? 'من' : 'of'} ${CurrencyService.format(env.allocatedAmount, isArabic: isArabic)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: env.isOverBudget ? AppColors.expense : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearPercentIndicator(
                                lineHeight: 6.0,
                                percent: p,
                                progressColor: env.isOverBudget ? AppColors.expense : envColor,
                                backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                                barRadius: const Radius.circular(6),
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      env.isOverBudget
                                          ? '⚠️ ${loc.translate('overBudget')} ${CurrencyService.format(env.spentAmount - env.allocatedAmount, isArabic: isArabic)}'
                                          : '${loc.translate('remaining')}: ${CurrencyService.format(env.remainingAmount, isArabic: isArabic)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: env.isOverBudget ? AppColors.expense : AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(env.spentPercentage * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: env.isOverBudget ? AppColors.expense : envColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 48),
                ],
              ),
            ),
        );
      },
    );
  }

  Widget _buildPeriodTab(int index, String label) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onPeriodChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  CurrencyService.format(amount, isArabic: context.isArabic),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
