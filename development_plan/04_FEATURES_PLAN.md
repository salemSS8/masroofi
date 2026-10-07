# ⚙️ خطة تطوير الميزات

> **المرحلة 3** — بناء كل الميزات وربطها بقاعدة البيانات  
> **الأولوية:** 🟠 عالية — تُنفذ بعد المرحلة 1

---

## 🎯 الأهداف

ربط كل شاشة بقاعدة البيانات عبر طبقة Repository + BLoC، وتحويل كل الشاشات الفارغة والبيانات الثابتة إلى ميزات كاملة العمل.

---

## 📋 المهام

### المهمة 3.1: نظام المعاملات (Transactions)

#### 3.1.1 — TransactionRepository
```dart
Future<List<TransactionModel>> getAll();
Future<List<TransactionModel>> getByDateRange(DateTime from, DateTime to);
Future<List<TransactionModel>> getByCategory(int categoryId);
Future<List<TransactionModel>> getByEnvelope(int envelopeId);
Future<int> insert(TransactionModel t);
Future<void> update(TransactionModel t);
Future<void> delete(int id);
Future<double> getTotalExpenses(DateTime from, DateTime to);
Future<double> getTotalIncome(DateTime from, DateTime to);
Future<Map<String, double>> getExpensesByCategory(DateTime from, DateTime to);
Future<double> getDailyTotal(DateTime date);
Future<double> getWeeklyTotal(DateTime weekStart);
```

#### 3.1.2 — TransactionsBloc
```
Events: LoadTransactions, AddTransaction, UpdateTransaction, DeleteTransaction, FilterByDate, FilterByCategory
States: TransactionsInitial, TransactionsLoading, TransactionsLoaded(list, totals), TransactionsError
```

#### 3.1.3 — AddTransactionScreen (إعادة بناء كاملة)
- ربط كل الحقول بـ Controllers
- حقل المبلغ مع validation (> 0)
- اختيار التصنيف من قائمة ديناميكية
- DatePicker عربي
- ربط بظرف (اختياري)
- حفظ فعلي في قاعدة البيانات
- رسالة نجاح + عودة للخلف

---

### المهمة 3.2: نظام التصنيفات (Categories)

#### 3.2.1 — CategoryRepository
```dart
Future<List<CategoryModel>> getAll();
Future<List<CategoryModel>> getExpenseCategories();
Future<List<CategoryModel>> getIncomeCategories();
Future<int> insert(CategoryModel c);
Future<void> update(CategoryModel c);
Future<void> delete(int id);
```

#### 3.2.2 — تصنيفات افتراضية (Seed Data)
عند أول تشغيل، يتم إنشاء تصنيفات افتراضية:

| التصنيف | النوع | الأيقونة |
|---------|-------|---------|
| طعام وشراب | مصروف | 🍕 restaurant |
| مواصلات | مصروف | 🚗 directions_car |
| فواتير | مصروف | 📄 receipt |
| تسوق | مصروف | 🛒 shopping_cart |
| صحة | مصروف | 🏥 medical_services |
| ترفيه | مصروف | 🎮 sports_esports |
| تعليم | مصروف | 📚 school |
| راتب | دخل | 💰 account_balance_wallet |
| عمل حر | دخل | 💼 work |
| هدايا | دخل | 🎁 card_giftcard |
| أخرى | مصروف+دخل | 📦 category |

---

### المهمة 3.3: نظام الأظرف (Envelopes)

#### 3.3.1 — EnvelopeModel
```dart
class EnvelopeModel {
  final int? id;
  final String name;
  final double budget;
  final String? icon;
  final String? color;
  
  // computed
  double get spent => ...; // يُحسب من المعاملات المرتبطة
  double get remaining => budget - spent;
  double get percentage => spent / budget;
}
```

#### 3.3.2 — EnvelopeRepository
```dart
Future<List<EnvelopeModel>> getAll();
Future<int> insert(EnvelopeModel e);
Future<void> update(EnvelopeModel e);
Future<void> delete(int id);
Future<double> getSpent(int envelopeId, DateTime from, DateTime to);
```

#### 3.3.3 — EnvelopesScreen (إعادة بناء)
- عرض الأظرف من قاعدة البيانات
- حساب المصروف الفعلي لكل ظرف
- إضافة ظرف جديد عبر BottomSheet
- تعديل/حذف ظرف
- ألوان وأيقونات مخصصة

---

### المهمة 3.4: نظام التقارير (Reports)

#### 3.4.1 — ReportsBloc
```
Events: LoadReport(period), ChangePeriod(daily/weekly/monthly/custom)
States: ReportLoading, ReportLoaded(expenses, income, categories, chartData)
```

#### 3.4.2 — ReportsScreen (بناء من الصفر)
- **الرسم الدائري (PieChart):** توزيع المصاريف حسب التصنيف
  - استخدام `fl_chart` PieChart
  - ألوان التصنيفات
  - نقر على القطاع لعرض التفاصيل
- **الرسم الشريطي (BarChart):** المصاريف اليومية
  - آخر 7 أيام / 4 أسابيع / 12 شهر
  - عمود الدخل بجانب المصروف
- **ملخص الأرقام:**
  - إجمالي الدخل
  - إجمالي المصروف
  - الفرق (وفّرت / أنفقت أكثر)
  - متوسط المصروف اليومي
- **فلتر الفترة:**
  - اليوم / هذا الأسبوع / هذا الشهر / مخصص

---

### المهمة 3.5: نظام المعاملات الثابتة (Recurring)

#### 3.5.1 — RecurringTransactionModel
```dart
class RecurringTransactionModel {
  final int? id;
  final String type;
  final double amount;
  final int? categoryId;
  final int dayOfMonth;
  final String? note;
  final bool isActive;
}
```

#### 3.5.2 — RecurringRepository
```dart
Future<List<RecurringTransactionModel>> getAll();
Future<List<RecurringTransactionModel>> getActive();
Future<int> insert(RecurringTransactionModel r);
Future<void> update(RecurringTransactionModel r);
Future<void> delete(int id);
Future<void> toggleActive(int id, bool active);
```

#### 3.5.3 — منطق التنفيذ التلقائي
- عند فتح التطبيق: فحص إذا كان اليوم هو يوم الاستقطاع
- إذا نعم: إنشاء معاملة تلقائياً وإشعار المستخدم
- تخزين آخر تاريخ تنفيذ لمنع التكرار

#### 3.5.4 — RecurringTransactionsScreen (بناء من الصفر)
- قائمة بالمعاملات الثابتة
- مبدّل تفعيل/إيقاف
- أيقونة التصنيف + يوم الاستقطاع
- BottomSheet للإضافة/التعديل

---

### المهمة 3.6: نظام أهداف الادخار (Savings)

#### 3.6.1 — SavingsGoalModel
```dart
class SavingsGoalModel {
  final int? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String? icon;
  final String? color;
  
  double get percentage => currentAmount / targetAmount;
  bool get isCompleted => currentAmount >= targetAmount;
}
```

#### 3.6.2 — SavingsRepository
```dart
Future<List<SavingsGoalModel>> getAll();
Future<int> insert(SavingsGoalModel s);
Future<void> update(SavingsGoalModel s);
Future<void> delete(int id);
Future<void> deposit(int id, double amount);
Future<void> withdraw(int id, double amount);
```

#### 3.6.3 — SavingsGoalsScreen (بناء من الصفر)
- بطاقات بشريط تقدم لكل هدف
- المبلغ الحالي / المستهدف
- الموعد النهائي (إن وُجد)
- زر "إيداع" سريع (مع مبلغ مخصص)
- زر "سحب" (عند الحاجة)
- تأثير احتفال عند الوصول 100%
- BottomSheet للإضافة/التعديل

---

### المهمة 3.7: لوحة التحكم الرئيسية (Dashboard)

#### 3.7.1 — DashboardBloc
```
Events: LoadDashboard, RefreshDashboard
States: DashboardLoading, DashboardLoaded(
  balance, todayExpenses, weekExpenses, monthExpenses,
  recentTransactions, envelopeSummaries
)
```

#### 3.7.2 — DashboardScreen (إعادة بناء كاملة)
- **بطاقة الرصيد:** إجمالي الدخل - إجمالي المصروف
- **ملخص سريع:** اليوم / الأسبوع / الشهر
- **أظرف مصغرة:** أعلى 3 أظرف بشريط تقدم
- **آخر المعاملات:** آخر 5 معاملات
- **إجراءات سريعة:** FAB أو أزرار سريعة

---

### المهمة 3.8: شاشة الإعدادات (Settings)

#### 3.8.1 — الإعدادات المطلوبة
- **تغيير يوم بداية الشهر** (يؤثر على حساب الأظرف والتقارير)
- **تغيير العملة** (عرض الرمز فقط، لا تحويل)
- **تبديل الوضع الداكن/الفاتح**
- **تغيير PIN**
- **إعادة ضبط فعلية** (حذف كل الجداول + SecureStorage)
- **النسخ الاحتياطي** (تصدير JSON)
- **حول التطبيق**

---

## ✅ معايير الاكتمال

- [ ] كل معاملة تُحفظ وتُقرأ من قاعدة البيانات
- [ ] الأظرف ديناميكية مع حساب المصروف الفعلي
- [ ] التقارير تعرض رسوم بيانية حقيقية
- [ ] المعاملات الثابتة تعمل مع التنفيذ التلقائي
- [ ] أهداف الادخار مع إيداع/سحب
- [ ] لوحة التحكم تعرض بيانات حقيقية
- [ ] الإعدادات كاملة وعاملة
- [ ] لا يوجد زر أو إجراء بدون وظيفة
