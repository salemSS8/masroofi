import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// نظام الترجمة والتعريب المتكامل لتطبيق BASHNDDOF (يدعم العربية والإنجليزية)
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('ar'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isArabic => locale.languageCode == 'ar';
  bool get isRtl => isArabic;
  TextDirection get direction => isRtl ? TextDirection.rtl : TextDirection.ltr;

  // --- أيقونات اتجاهية ذكية تراعي RTL / LTR ---
  IconData get forwardChevron =>
      isRtl ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded;
  IconData get backChevron =>
      isRtl ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded;
  IconData get forwardArrow =>
      isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded;
  IconData get backArrow =>
      isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded;

  // --- القاموس النصي الشامل ---
  static const Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      // العامة وأشرطة التنقل
      'appName': 'مصروفي',
      'appTitle': 'تطبيق مصروفي',
      'navHome': 'الرئيسية',
      'navEnvelopes': 'الأظرف',
      'navReports': 'التقارير',
      'navSavings': 'الادخار',
      'navSettings': 'الإعدادات',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'delete': 'حذف',
      'edit': 'تعديل',
      'confirm': 'تأكيد',
      'close': 'إغلاق',
      'back': 'رجوع',
      'done': 'تم',
      'error': 'خطأ',
      'warning': 'تنبيه',
      'success': 'نجاح',
      'active': 'نشط',
      'inactive': 'معطل',
      'completed': 'مكتمل',

      // الشاشة الرئيسية
      'totalBalance': 'الرصيد الإجمالي',
      'income': 'الدخل',
      'expenses': 'المصروفات',
      'recentTransactions': 'أحدث المعاملات',
      'viewAll': 'عرض الكل',
      'noTransactions': 'لا توجد معاملات مسجلة حتى الآن',
      'noTransactionsSub': 'اضغط على زر (+) في الأسفل لإضافة أول معاملة',
      'addTransaction': 'إضافة معاملة',
      'savingsGoals': 'أهداف الادخار',
      'recurringTransactions': 'المتكررة',
      'hideBalance': 'إخفاء الرصيد',
      'showBalance': 'إظهار الرصيد',

      // المعاملات
      'addNewTransaction': 'إضافة معاملة جديدة',
      'editTransaction': 'تعديل المعاملة',
      'transactionType': 'نوع المعاملة',
      'expense': 'مصروف',
      'amount': 'المبلغ',
      'transactionTitle': 'العنوان / الوصف',
      'category': 'التصنيف',
      'date': 'التاريخ',
      'notes': 'ملاحظات إضافية (اختياري)',
      'selectEnvelope': 'تحديد ظرف الميزانية (اختياري)',
      'noEnvelope': 'بدون ربط بظرف',
      'recurringBadge': 'دورية 🔁',
      'oneTimeBadge': 'لمرة واحدة ⚡',
      'recurringDescription': 'هذه معاملة دورية مجدولة تم توليدها تلقائياً',
      'oneTimeDescription': 'معاملة عادية لمرة واحدة',
      'confirmDeleteTransaction': 'هل أنت متأكد من حذف هذه المعاملة؟',
      'deleteThisTransaction': 'حذف هذه المعاملة',
      'transactionSaved': 'تم حفظ المعاملة بنجاح ✅',
      'transactionDeleted': 'تم حذف المعاملة بنجاح 🗑️',
      'enterValidAmount': 'يرجى إدخال مبلغ صحيح',
      'enterTitle': 'يرجى إدخال عنوان للمعاملة',

      // الأظرف
      'budgetEnvelopes': 'أظرف الميزانية',
      'newEnvelope': 'ظرف جديد',
      'addEnvelope': 'إضافة ظرف ميزانية',
      'editEnvelope': 'تعديل الظرف',
      'envelopeName': 'اسم الظرف',
      'allocatedBudget': 'الميزانية المخصصة',
      'spent': 'المصروف',
      'remaining': 'المتبقي',
      'overBudget': 'تجاوز الميزانية بمقدار',
      'noEnvelopes': 'لا توجد أظرف ميزانية حتى الآن',
      'noEnvelopesSub': 'قسّم دخلك الشهري إلى أظرف واضحة للتحكم بمصروفاتك',
      'confirmDeleteEnvelope': 'هل أنت متأكد من حذف هذا الظرف؟',

      // الادخار
      'savingsGoalsTitle': 'أهداف الادخار',
      'newGoal': 'هدف ادخار جديد',
      'addGoal': 'إضافة هدف',
      'editGoal': 'تعديل الهدف',
      'goalName': 'اسم الهدف (مثال: سيارة، حاسوب)',
      'targetAmount': 'المبلغ المستهدف',
      'currentAmount': 'المبلغ الحالي',
      'addContribution': 'إيداع مبلغ',
      'depositAmount': 'المبلغ المودع',
      'deductFromWallet': 'خصم المبلغ من رصيد المحفظة وتسجيله كمصروف ادخار',
      'remainingToReach': 'المتبقي لتحقيق الهدف',
      'noGoals': 'لا توجد أهداف ادخار حتى الآن',
      'noGoalsSub': 'حدد أهدافك المالية وابدأ في التوفير خطوة بخطوة',
      'goalProgress': 'نسبة الإنجاز',

      // المعاملات المتكررة
      'recurringTitle': 'المعاملات المتكررة والدورية',
      'newRecurring': 'معاملة دورية جديدة',
      'frequency': 'التكرار',
      'daily': 'يومياً',
      'weekly': 'أسبوعياً',
      'monthly': 'شهرياً',
      'yearly': 'سنوياً',
      'nextDue': 'الموعد القادم',
      'applyDueNow': 'تسجيل استحقاق الآن',
      'deactivate': 'تعطيل المعاملة',
      'activate': 'تفعيل المعاملة',
      'inactiveBadge': 'معطلة',
      'noRecurring': 'لا توجد معاملات دورية مجدولة بعد',
      'noRecurringSub': 'سجل فواتيرك واشتراكاتك ورواتبك لتذكيرك بها تلقائياً',

      // التقارير
      'financialReports': 'التقارير المالية',
      'thisMonth': 'هذا الشهر',
      'lastMonth': 'السابق',
      'thisYear': 'هذا العام',
      'allTime': 'الكل',
      'totalIncome': 'إجمالي الدخل',
      'totalExpenses': 'إجمالي المصروفات',
      'netSavings': 'صافي التوفير / الفائض',
      'savingsRate': 'معدل الادخار',
      'expenseBreakdown': 'توزيع المصروفات حسب التصنيف',
      'savingsReport': 'تقرير أهداف الادخار',
      'envelopesReport': 'تقرير ميزانيات الأظرف',
      'totalSaved': 'إجمالي المدخر',
      'target': 'المستهدف',
      'totalAllocated': 'الميزانية المخصصة',
      'noExpensesInPeriod': 'لا توجد مصروفات مسجلة في هذه الفترة',

      // الإعدادات
      'settingsTitle': 'الإعدادات والأمان',
      'appearanceSection': 'المظهر والسمة (Theme)',
      'lightMode': 'النهاري',
      'darkMode': 'الليلي',
      'systemMode': 'تلقائي',
      'systemSubtitle': 'النظام',
      'languageAndRegion': 'اللغة والعملة (Language & Currency)',
      'appLanguage': 'لغة التطبيق',
      'arabic': 'العربية',
      'english': 'English',
      'currency': 'العملة',
      'currentCurrency': 'عملة التطبيق الحالية',
      'selectCurrency': 'اختيار العملة',
      'searchCurrency': 'ابحث بالاسم أو الرمز (مثال: ر.س أو USD)...',
      'securitySection': 'الأمان والخصوصية',
      'biometrics': 'المصادقة الحيوية (البصمة / الوجه)',
      'biometricsSub': 'طلب البصمة عند فتح التطبيق لإجراءات سريعة وآمنة',
      'changePin': 'تغيير الرمز السري للمحفظة',
      'changePinSub': 'تعديل الرمز المكون من 4 أرقام',
      'backupSection': 'النسخ الاحتياطي المشفر',
      'exportBackup': 'تصدير نسخة احتياطية مشفرة',
      'exportBackupSub': 'حفظ جميع بياناتك بأمان مشفرة بكلمة سر خاصة',
      'restoreBackup': 'استعادة نسخة احتياطية',
      'restoreBackupSub': 'استرجاع معاملاتك وميزانياتك من ملف أو نص مشفر',
      'notificationsSection': 'الإشعارات والتذكيرات',
      'dailyNotifications': 'التذكيرات المحلية اليومية',
      'dailyNotificationsSub': 'تنبيهك لتسجيل المعاملات ومواعيد الاستحقاق',
      'reminderTime': 'موعد التذكير اليومي',
      'sendTestNotification': 'تجربة إرسال إشعار فوري',
      'dataManagement': 'إدارة البيانات وإعادة الضبط',
      'resetAllData': 'إعادة ضبط المحفظة بالكامل',
      'resetAllDataSub': 'حذف كافة المعاملات والبيانات والبدء من جديد',
      'aboutApp': 'عن تطبيق مصروفي',
      'aboutAppSub': 'الإصدار 1.0.0 • رفيقك المالي الذكي',
      'financialFeatures': 'الميزات المالية',

      // الأمان وتسجيل الدخول
      'welcomeBack': 'مرحبًا بك مجددًا',
      'enterPin': 'أدخل الرمز السري للوصول إلى محفظتك',
      'useBiometric': 'استخدام البصمة / الوجه',
      'pinSetup': 'إعداد الرمز السري',
      'choosePin': 'اختر رمزًا سريًا مكونًا من 4 أرقام',
      'confirmPin': 'أعد إدخال الرمز السري للتأكيد',
      'step1of2': 'الخطوة 1 من 2',
      'step2of2': 'الخطوة 2 من 2',
      'pinMismatch': 'الرمزان غير متطابقين، أعد المحاولة',
      'lockedOut': 'تم قفل المحفظة مؤقتًا بسبب تكرار المحاولات الخاطئة',

      // شاشة البدء
      'introWelcome': '👋 مرحبًا بك في تطبيق مصروفي',
      'introSubtitle': 'محفظتك المالية الشخصية الذكية لإدارة الميزانية والمصروفات بكل أمان وبدون إنترنت.',
      'offlineFeature': 'أوفلاين بالكامل (Offline-First)',
      'offlineFeatureSub': 'بياناتك محفوظة محلياً على جهازك ولا تغادره أبداً',
      'envelopesFeature': 'ميزانية الأظرف الذكية',
      'envelopesFeatureSub': 'قسّم دخلك لأظرف واضحة وتحكّم بمصروفاتك بدقة',
      'securityFeature': 'حماية وتشفير متكامل',
      'securityFeatureSub': 'محمي برمز سري وبصمة حيوية بدون أي تتبع',
      'start': 'ابدأ',
      'next': 'التالي',
      'skip': 'تخطي',
      'getStarted': 'ابدأ الآن',
      'madeWithLove': 'صُنع بكل حب وإتقان بواسطة المبرمج العم سالم ❤️',
    },
    'en': {
      // Common & Navigation
      'appName': 'Masroufi',
      'appTitle': 'Masroufi Wallet',
      'navHome': 'Home',
      'navEnvelopes': 'Envelopes',
      'navReports': 'Reports',
      'navSavings': 'Savings',
      'navSettings': 'Settings',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'confirm': 'Confirm',
      'close': 'Close',
      'back': 'Back',
      'done': 'Done',
      'error': 'Error',
      'warning': 'Warning',
      'success': 'Success',
      'active': 'Active',
      'inactive': 'Inactive',
      'completed': 'Completed',

      // Dashboard
      'totalBalance': 'Total Balance',
      'income': 'Income',
      'expenses': 'Expenses',
      'recentTransactions': 'Recent Transactions',
      'viewAll': 'View All',
      'noTransactions': 'No transactions recorded yet',
      'noTransactionsSub': 'Tap the (+) button below to add your first transaction',
      'addTransaction': 'Add Transaction',
      'savingsGoals': 'Savings Goals',
      'recurringTransactions': 'Recurring',
      'hideBalance': 'Hide Balance',
      'showBalance': 'Show Balance',

      // Transactions
      'addNewTransaction': 'Add New Transaction',
      'editTransaction': 'Edit Transaction',
      'transactionType': 'Transaction Type',
      'expense': 'Expense',
      'amount': 'Amount',
      'transactionTitle': 'Title / Description',
      'category': 'Category',
      'date': 'Date',
      'notes': 'Additional Notes (Optional)',
      'selectEnvelope': 'Select Budget Envelope (Optional)',
      'noEnvelope': 'Not linked to an envelope',
      'recurringBadge': 'Recurring 🔁',
      'oneTimeBadge': 'One-time ⚡',
      'recurringDescription': 'This is a scheduled recurring transaction',
      'oneTimeDescription': 'Standard one-time transaction',
      'confirmDeleteTransaction': 'Are you sure you want to delete this transaction?',
      'deleteThisTransaction': 'Delete This Transaction',
      'transactionSaved': 'Transaction saved successfully ✅',
      'transactionDeleted': 'Transaction deleted successfully 🗑️',
      'enterValidAmount': 'Please enter a valid amount',
      'enterTitle': 'Please enter a title for the transaction',

      // Envelopes
      'budgetEnvelopes': 'Budget Envelopes',
      'newEnvelope': 'New Envelope',
      'addEnvelope': 'Add Budget Envelope',
      'editEnvelope': 'Edit Envelope',
      'envelopeName': 'Envelope Name',
      'allocatedBudget': 'Allocated Budget',
      'spent': 'Spent',
      'remaining': 'Remaining',
      'overBudget': 'Over budget by',
      'noEnvelopes': 'No budget envelopes yet',
      'noEnvelopesSub': 'Divide your monthly income into clear envelopes to control spending',
      'confirmDeleteEnvelope': 'Are you sure you want to delete this envelope?',

      // Savings
      'savingsGoalsTitle': 'Savings Goals',
      'newGoal': 'New Savings Goal',
      'addGoal': 'Add Goal',
      'editGoal': 'Edit Goal',
      'goalName': 'Goal Name (e.g. Car, Laptop)',
      'targetAmount': 'Target Amount',
      'currentAmount': 'Current Amount',
      'addContribution': 'Add Contribution',
      'depositAmount': 'Deposit Amount',
      'deductFromWallet': 'Deduct amount from wallet balance & record as savings expense',
      'remainingToReach': 'Remaining to reach goal',
      'noGoals': 'No savings goals yet',
      'noGoalsSub': 'Set your financial goals and start saving step by step',
      'goalProgress': 'Progress',

      // Recurring
      'recurringTitle': 'Recurring & Scheduled',
      'newRecurring': 'New Recurring Transaction',
      'frequency': 'Frequency',
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
      'nextDue': 'Next Due',
      'applyDueNow': 'Apply Due Now',
      'deactivate': 'Deactivate Transaction',
      'activate': 'Activate Transaction',
      'inactiveBadge': 'Inactive',
      'noRecurring': 'No recurring transactions scheduled yet',
      'noRecurringSub': 'Log recurring bills, subscriptions, or salaries for reminders',

      // Reports
      'financialReports': 'Financial Reports',
      'thisMonth': 'This Month',
      'lastMonth': 'Last Month',
      'thisYear': 'This Year',
      'allTime': 'All Time',
      'totalIncome': 'Total Income',
      'totalExpenses': 'Total Expenses',
      'netSavings': 'Net Savings / Surplus',
      'savingsRate': 'Savings Rate',
      'expenseBreakdown': 'Expense Distribution by Category',
      'savingsReport': 'Savings Goals Report',
      'envelopesReport': 'Envelope Budgets Report',
      'totalSaved': 'Total Saved',
      'target': 'Target',
      'totalAllocated': 'Total Allocated',
      'noExpensesInPeriod': 'No expenses recorded in this period',

      // Settings
      'settingsTitle': 'Settings & Security',
      'appearanceSection': 'Appearance & Theme',
      'lightMode': 'Light',
      'darkMode': 'Dark',
      'systemMode': 'System',
      'systemSubtitle': 'Default',
      'languageAndRegion': 'Language & Currency',
      'appLanguage': 'App Language',
      'arabic': 'العربية (Arabic)',
      'english': 'English',
      'currency': 'Currency',
      'currentCurrency': 'Current App Currency',
      'selectCurrency': 'Select Currency',
      'searchCurrency': 'Search by name or code (e.g. USD, SAR)...',
      'securitySection': 'Security & Privacy',
      'biometrics': 'Biometric Authentication (Fingerprint / Face)',
      'biometricsSub': 'Prompt for biometrics on launch for quick & secure access',
      'changePin': 'Change Wallet PIN',
      'changePinSub': 'Update your 4-digit security PIN',
      'backupSection': 'Encrypted Backup',
      'exportBackup': 'Export Encrypted Backup',
      'exportBackupSub': 'Securely backup all your data encrypted with AES-256',
      'restoreBackup': 'Restore Backup',
      'restoreBackupSub': 'Restore transactions & budgets from encrypted data',
      'notificationsSection': 'Notifications & Reminders',
      'dailyNotifications': 'Daily Local Reminders',
      'dailyNotificationsSub': 'Reminders to log transactions and due dates',
      'reminderTime': 'Daily Reminder Time',
      'sendTestNotification': 'Send Test Notification',
      'dataManagement': 'Data Management & Reset',
      'resetAllData': 'Reset Entire Wallet',
      'resetAllDataSub': 'Permanently delete all transactions & start fresh',
      'aboutApp': 'About Masroufi',
      'aboutAppSub': 'Version 1.0.0 • Crafted with care',
      'financialFeatures': 'Financial Features',

      // Security & PIN
      'welcomeBack': 'Welcome Back',
      'enterPin': 'Enter PIN to unlock your wallet',
      'useBiometric': 'Use Fingerprint / Face ID',
      'pinSetup': 'Setup PIN',
      'choosePin': 'Choose a 4-digit security PIN',
      'confirmPin': 'Re-enter PIN to confirm',
      'step1of2': 'Step 1 of 2',
      'step2of2': 'Step 2 of 2',
      'pinMismatch': 'PINs do not match, please try again',
      'lockedOut': 'Wallet temporarily locked due to too many failed attempts',

      // Intro
      'introWelcome': '👋 Welcome to Masroufi',
      'introSubtitle': 'Your smart, private, offline personal finance and envelope budget tracker.',
      'offlineFeature': '100% Offline (Offline-First)',
      'offlineFeatureSub': 'Your financial data stays securely on your phone forever',
      'envelopesFeature': 'Smart Envelope Budgeting',
      'envelopesFeatureSub': 'Organize your income into clear envelopes and take control',
      'securityFeature': 'AES-256 Encryption & Privacy',
      'securityFeatureSub': 'Protected with PIN and biometrics with zero tracking',
      'start': 'Start',
      'next': 'Next',
      'skip': 'Skip',
      'getStarted': 'Get Started',
      'madeWithLove': 'Crafted with passion by Developer Uncle Salem ❤️',
    },
  };

  /// البحث عن النص بالقيمة المفتاحية
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['ar']?[key] ??
        key;
  }

  // --- Getters لسهولة وسرعة الوصول للنصوص الأكثر استخداماً ---
  String get appName => translate('appName');
  String get navHome => translate('navHome');
  String get navEnvelopes => translate('navEnvelopes');
  String get navReports => translate('navReports');
  String get navSavings => translate('navSavings');
  String get navSettings => translate('navSettings');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get confirm => translate('confirm');
  String get close => translate('close');
  String get back => translate('back');
  String get totalBalance => translate('totalBalance');
  String get income => translate('income');
  String get expenses => translate('expenses');
  String get recentTransactions => translate('recentTransactions');
  String get viewAll => translate('viewAll');
  String get noTransactions => translate('noTransactions');
  String get addTransaction => translate('addTransaction');
  String get savingsGoals => translate('savingsGoals');
  String get recurringTransactions => translate('recurringTransactions');
  String get settingsTitle => translate('settingsTitle');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// ملحق context للوصول السريع لخدمات التعريب
extension LocalizationExtension on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this);
  bool get isArabic => AppLocalizations.of(this).isArabic;
  bool get isRtl => AppLocalizations.of(this).isRtl;
  IconData get forwardChevron => AppLocalizations.of(this).forwardChevron;
  IconData get backChevron => AppLocalizations.of(this).backChevron;
  IconData get forwardArrow => AppLocalizations.of(this).forwardArrow;
  IconData get backArrow => AppLocalizations.of(this).backArrow;
}
