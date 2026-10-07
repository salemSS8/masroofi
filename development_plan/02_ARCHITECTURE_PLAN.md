# 🏛️ خطة إعادة الهيكلة المعمارية

> **المرحلة 1** — الأساس الذي يُبنى عليه كل شيء  
> **الأولوية:** 🔴 حرجة — يجب إنجازها أولاً قبل أي تطوير

---

## 🎯 الأهداف

1. حذف جميع الملفات المكررة وتوحيد مصدر الحقيقة
2. توحيد قاعدة البيانات في ملف واحد شامل
3. إنشاء طبقة Repository/DAO للوصول للبيانات
4. تفعيل BLoC لإدارة الحالة
5. تنظيم المجلدات بنمط Clean Architecture

---

## 📋 المهام

### المهمة 1.1: حذف الملفات المكررة

#### 1.1.1 — توحيد PinSetupScreen
- **حذف:** `lib/src/features/auth/presentation/screens/pin_setup_screen.dart`
- **الإبقاء على:** `lib/src/features/auth/presentation/pin_setup_screen.dart` (يحتوي تشفير SHA-256)
- **التعديل:** دمج ميزة `_showWarningDialog` من النسخة المحذوفة + إضافة خطوة تأكيد PIN + حفظ PIN فعلياً عبر `SecureStorageService`
- **تحديث الاستيرادات في:** `main.dart` (سيظل كما هو)

#### 1.1.2 — توحيد DashboardScreen  
- **حذف:** `lib/src/features/transactions/presentation/screens/dashboard_screen.dart`
- **الإبقاء على:** `lib/src/features/dashboard/presentation/screens/dashboard_screen.dart`
- **التعديل:** دمج تصميم البطاقات والأظرف من النسخة المحذوفة كمرجع للتصميم

#### 1.1.3 — توحيد قاعدة البيانات
- **حذف:** `lib/src/core/data/local/database.dart` (AppDatabase)
- **الإبقاء على:** `lib/src/core/database/database_helper.dart` (DatabaseHelper — يحتوي كل الجداول)
- **التعديل:** إضافة جدول `budget_settings` لحفظ إعدادات الميزانية

---

### المهمة 1.2: إعادة هيكلة المجلدات

**البنية المستهدفة:**
```
lib/
├── main.dart
├── app.dart                              ← MaterialApp + التوجيه + الثيم
└── src/
    ├── core/
    │   ├── theme/
    │   │   ├── app_theme.dart            ← الثيم الكامل (فاتح + داكن)
    │   │   ├── app_colors.dart           ← لوحة الألوان المخصصة
    │   │   └── app_text_styles.dart      ← أنماط النصوص
    │   ├── database/
    │   │   └── database_helper.dart      ← قاعدة البيانات الموحدة
    │   ├── models/
    │   │   ├── transaction_model.dart
    │   │   ├── category_model.dart
    │   │   ├── envelope_model.dart       ← جديد
    │   │   ├── recurring_transaction_model.dart  ← جديد
    │   │   └── savings_goal_model.dart   ← جديد
    │   ├── repositories/                 ← جديد — طبقة الوصول للبيانات
    │   │   ├── transaction_repository.dart
    │   │   ├── category_repository.dart
    │   │   ├── envelope_repository.dart
    │   │   ├── recurring_repository.dart
    │   │   └── savings_repository.dart
    │   ├── security/
    │   │   └── encryption_service.dart
    │   ├── services/
    │   │   └── secure_storage_service.dart
    │   └── widgets/                      ← جديد — مكونات مشتركة
    │       ├── app_card.dart
    │       ├── empty_state_widget.dart
    │       └── loading_widget.dart
    └── features/
        ├── auth/
        │   ├── presentation/
        │   │   ├── login_screen.dart
        │   │   └── pin_setup_screen.dart  ← نسخة واحدة فقط
        │   └── bloc/                     ← جديد
        │       ├── auth_bloc.dart
        │       ├── auth_event.dart
        │       └── auth_state.dart
        ├── onboarding/                   ← مجلد جديد (بدل core)
        │   └── presentation/
        │       ├── intro_screen.dart
        │       └── initial_budget_setup_screen.dart
        ├── dashboard/
        │   ├── presentation/screens/
        │   │   └── dashboard_screen.dart  ← نسخة واحدة فقط
        │   └── bloc/                     ← جديد
        │       └── dashboard_bloc.dart
        ├── transactions/
        │   ├── presentation/screens/
        │   │   └── add_transaction_screen.dart
        │   └── bloc/                     ← جديد
        │       └── transactions_bloc.dart
        ├── envelopes/
        │   ├── presentation/screens/
        │   │   └── envelopes_screen.dart
        │   └── bloc/
        │       └── envelopes_bloc.dart
        ├── recurring/
        │   ├── presentation/screens/
        │   │   └── recurring_transactions_screen.dart
        │   └── bloc/
        │       └── recurring_bloc.dart
        ├── reports/
        │   ├── presentation/screens/
        │   │   └── reports_screen.dart
        │   └── bloc/
        │       └── reports_bloc.dart
        ├── savings/
        │   ├── presentation/screens/
        │   │   └── savings_goals_screen.dart
        │   └── bloc/
        │       └── savings_bloc.dart
        └── settings/
            └── presentation/screens/
                └── settings_screen.dart
```

---

### المهمة 1.3: إنشاء طبقة Repository

كل Repository يتعامل مع `DatabaseHelper` ويوفر واجهة نظيفة:

```dart
// مثال: TransactionRepository
class TransactionRepository {
  final DatabaseHelper _db;
  
  TransactionRepository(this._db);
  
  Future<List<TransactionModel>> getAll() async { ... }
  Future<List<TransactionModel>> getByDateRange(DateTime from, DateTime to) async { ... }
  Future<int> insert(TransactionModel t) async { ... }
  Future<void> update(TransactionModel t) async { ... }
  Future<void> delete(int id) async { ... }
  Future<double> getTotalExpenses(DateTime from, DateTime to) async { ... }
  Future<double> getTotalIncome(DateTime from, DateTime to) async { ... }
}
```

---

### المهمة 1.4: تفعيل BLoC Pattern

```dart
// مثال: TransactionsBloc
class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final TransactionRepository repository;
  
  TransactionsBloc(this.repository) : super(TransactionsInitial()) {
    on<LoadTransactions>(_onLoad);
    on<AddTransaction>(_onAdd);
    on<DeleteTransaction>(_onDelete);
  }
}
```

---

### المهمة 1.5: توحيد قاعدة البيانات النهائية

```sql
-- الجداول النهائية المطلوبة:
CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,          -- 'expense' | 'income'
  amount REAL NOT NULL,
  category_id INTEGER,
  note TEXT,
  datetime TEXT NOT NULL,
  envelope_id INTEGER,         -- ربط بظرف (اختياري)
  FOREIGN KEY (category_id) REFERENCES categories(id),
  FOREIGN KEY (envelope_id) REFERENCES envelopes(id)
);

CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  icon TEXT,                   -- اسم الأيقونة
  color TEXT,                  -- لون التصنيف (hex)
  is_income INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE envelopes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  budget REAL NOT NULL,
  color TEXT,                  -- لون الظرف
  icon TEXT
);

CREATE TABLE recurring_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  amount REAL NOT NULL,
  category_id INTEGER,
  day_of_month INTEGER NOT NULL,
  note TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE TABLE savings_goals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  target_amount REAL NOT NULL,
  current_amount REAL NOT NULL DEFAULT 0,
  deadline TEXT,               -- تاريخ الهدف (اختياري)
  icon TEXT,
  color TEXT
);

CREATE TABLE budget_settings (
  id INTEGER PRIMARY KEY,
  day_of_month INTEGER NOT NULL DEFAULT 1,
  opening_balance REAL NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'SAR'
);
```

---

## ✅ معايير الاكتمال

- [ ] لا يوجد أي ملف مكرر في المشروع
- [ ] قاعدة بيانات واحدة موحدة بكل الجداول
- [ ] كل feature لديها Repository خاص بها
- [ ] BLoC مُفعّل في كل feature
- [ ] كل الشاشات تعمل بدون أخطاء
- [ ] لا يوجد كود ميت أو مُعلّق
