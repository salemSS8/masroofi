import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../currency/currency_service.dart';
import '../localization/app_localizations.dart';

/// بطاقة الرصيد المالي الرئيسية الفاخرة (Hero Financial Balance Card)
class FinancialCard extends StatefulWidget {
  final double balance;
  final double income;
  final double expenses;
  final String? currency;
  final VoidCallback? onAddTap;

  const FinancialCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expenses,
    this.currency,
    this.onAddTap,
  });

  @override
  State<FinancialCard> createState() => _FinancialCardState();
}

class _FinancialCardState extends State<FinancialCard> {
  bool _isBalanceVisible = true;

  void _toggleVisibility() {
    HapticFeedback.selectionClick();
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final loc = context.loc;
    final effectiveCurrency = widget.currency ?? CurrencyService.getSymbol(isArabic);

    final formatter = NumberFormat("#,##0.00", isArabic ? "ar" : "en");

    final balanceFormatted = formatter.format(widget.balance);
    final incomeFormatted = formatter.format(widget.income);
    final expenseFormatted = formatter.format(widget.expenses);

    // مراعاة موضع رمز العملة ($ و € يسبقان الرقم بالإنجليزية)
    String formatWithCurrency(String numStr, double val) {
      if (!isArabic && (effectiveCurrency == '\$' || effectiveCurrency == '€')) {
        return '$effectiveCurrency$numStr';
      }
      return '$numStr $effectiveCurrency';
    }

    final balanceText = _isBalanceVisible
        ? formatWithCurrency(balanceFormatted, widget.balance)
        : '••••••••';

    final incomeText = _isBalanceVisible
        ? formatWithCurrency(incomeFormatted, widget.income)
        : '••••';

    final expenseText = _isBalanceVisible
        ? formatWithCurrency(expenseFormatted, widget.expenses)
        : '••••';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // هالات ضوئية هندسية خلفية تضفي لمسة فنية فريدة
            Positioned(
              top: -30,
              left: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(16),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -20,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // رأس البطاقة: التسمية وزر إخفاء/إظهار الرصيد
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(38),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            loc.totalBalance,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          _isBalanceVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: _toggleVisibility,
                        tooltip: _isBalanceVisible
                            ? loc.translate('hideBalance')
                            : loc.translate('showBalance'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // قيمة الرصيد الإجمالي
                  // استخدام AlignmentDirectional.centerStart لضمان الاتجاه الصحيح RTL / LTR
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      balanceText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // فاصل شفاف ناعم
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.white.withAlpha(38),
                  ),
                  const SizedBox(height: 16),

                  // ملخص الدخل والمصروفات
                  Row(
                    children: [
                      // الدخل
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(38),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                color: Color(0xFF6EE7B7),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.income,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    incomeText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.white.withAlpha(38),
                      ),
                      const SizedBox(width: 16),

                      // المصروف
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(38),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                color: Color(0xFFFCA5A5),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.expenses,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    expenseText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
