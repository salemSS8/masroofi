import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bashnddof/src/core/localization/app_localizations.dart';
import 'package:bashnddof/src/core/models/transaction_model.dart';
import 'package:bashnddof/src/core/repositories/transaction_repository.dart';
import 'package:bashnddof/src/core/theme/app_colors.dart';
import 'package:bashnddof/src/core/widgets/app_button.dart';
import 'package:bashnddof/src/core/widgets/app_text_field.dart';

/// شاشة إعداد الميزانية لأول مرة (Initial Budget & Opening Balance Setup)
class InitialBudgetSetupScreen extends StatefulWidget {
  const InitialBudgetSetupScreen({super.key});

  @override
  State<InitialBudgetSetupScreen> createState() =>
      _InitialBudgetSetupScreenState();
}

class _InitialBudgetSetupScreenState extends State<InitialBudgetSetupScreen> {
  final _dayOfMonthController = TextEditingController(text: '1');
  final _openingBalanceController = TextEditingController();
  final _transactionRepo = TransactionRepository();
  bool _isSaving = false;

  @override
  void dispose() {
    _dayOfMonthController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _saveInitialBudget() async {
    final balanceText = _openingBalanceController.text.trim();
    final dayText = _dayOfMonthController.text.trim();

    final openingBalance = double.tryParse(balanceText) ?? 0.0;
    final budgetDay = int.tryParse(dayText) ?? 1;

    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    await prefs.setInt('budgetStartDay', budgetDay);

    final isArabic = mounted ? context.isArabic : true;

    // إذا أدخل المستخدم رصيداً افتتاحياً، يتم تسجيله كمعاملة دخل أولية في قاعدة البيانات
    if (openingBalance > 0) {
      final initialTx = TransactionModel(
        title: isArabic ? 'الرصيد الافتتاحي' : 'Opening Balance',
        amount: openingBalance,
        type: 'income',
        date: DateTime.now(),
        notes: isArabic
            ? 'الرصيد المالي المبدئي المسجل عند إعداد المحفظة'
            : 'Initial opening balance recorded during wallet setup',
      );
      await _transactionRepo.insert(initialTx);
    }

    HapticFeedback.mediumImpact();
    if (!mounted) return;

    setState(() => _isSaving = false);
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'إعداد المحفظة المبدئي' : 'Initial Wallet Setup'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // شعار التطبيق
              Center(
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceAlt : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(45),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo_transparent.png',
                      width: 66,
                      height: 66,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                isArabic ? 'خطوة أخيرة لإعداد محفظتك 🎯' : 'One Final Step 🎯',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),

              Text(
                isArabic
                    ? 'أدخل رصيدك الحالي لتتبع أموالك بدقة من أول لحظة'
                    : 'Enter your current balance to track your finances accurately from day one',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // بطاقة إدخال الرصيد الافتتاحي
              Container(
                padding: const EdgeInsets.all(20),
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
                      isArabic
                          ? 'الرصيد الافتتاحي (كم تملك حاليًا في جيبك/حسابك؟)'
                          : 'Opening Balance (How much do you currently have?)',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isArabic
                          ? 'يمكنك تركه 0 والبدء بتسجيل المعاملات لاحقاً'
                          : 'You can leave it 0 and start adding transactions later',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _openingBalanceController,
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // بطاقة تحديد موعد بداية الميزانية
              Container(
                padding: const EdgeInsets.all(20),
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
                      isArabic
                          ? 'يوم بداية دورتك المالية الشهرية'
                          : 'Monthly Financial Cycle Start Day',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isArabic
                          ? 'اليوم الذي تستلم فيه راتبك أو تبدأ فيه ميزانيتك (مثلاً 1 أو 25 من كل شهر)'
                          : 'The day you receive your salary or start your budget (e.g. 1st or 25th of each month)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _dayOfMonthController,
                      hintText: '1',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              AppButton(
                text: isArabic ? 'إتمام الإعداد والدخول للمحفظة' : 'Complete Setup & Open Wallet',
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isSaving,
                onPressed: _saveInitialBudget,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
