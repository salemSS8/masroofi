# 📊 الوضع الحالي للمشروع — تحليل شامل

> تم إنشاء هذا التحليل بناءً على فحص Graphify للرسم البياني المعرفي (364 عقدة، 469 رابط، 22 مجتمع)  
> وفحص يدوي لكل ملف من ملفات المشروع

---

## 🏗️ البنية الحالية

```
lib/
├── main.dart                                    ← نقطة الدخول والتوجيه
└── src/
    ├── core/
    │   ├── data/local/database.dart             ← AppDatabase (مكرر!)
    │   ├── database/database_helper.dart        ← DatabaseHelper (مكرر!)
    │   ├── models/
    │   │   ├── transaction_model.dart           ← نموذج المعاملة
    │   │   └── category_model.dart              ← نموذج التصنيف
    │   ├── security/encryption_service.dart     ← خدمة التشفير
    │   └── services/secure_storage_service.dart ← خدمة التخزين الآمن
    └── features/
        ├── auth/presentation/
        │   ├── login_screen.dart                ← شاشة تسجيل الدخول
        │   ├── pin_setup_screen.dart            ← إعداد PIN (مكرر!)
        │   └── screens/pin_setup_screen.dart    ← إعداد PIN (مكرر!)
        ├── budget/presentation/screens/
        │   └── initial_budget_setup_screen.dart ← إعداد الميزانية الأولي
        ├── core/presentation/screens/
        │   └── intro_screen.dart                ← شاشة الترحيب
        ├── dashboard/presentation/screens/
        │   └── dashboard_screen.dart            ← لوحة التحكم الرئيسية
        ├── envelopes/presentation/screens/
        │   └── envelopes_screen.dart            ← شاشة الأظرف
        ├── recurring/presentation/screens/
        │   └── recurring_transactions_screen.dart ← المعاملات الثابتة (فارغة!)
        ├── reports/presentation/screens/
        │   └── reports_screen.dart              ← التقارير (فارغة!)
        ├── savings/presentation/screens/
        │   └── savings_goals_screen.dart        ← أهداف الادخار (فارغة!)
        ├── settings/presentation/screens/
        │   └── settings_screen.dart             ← الإعدادات
        └── transactions/presentation/screens/
            ├── add_transaction_screen.dart       ← إضافة معاملة (لا تحفظ!)
            └── dashboard_screen.dart            ← لوحة تحكم مكررة (بيانات ثابتة!)
```

---

## 🐛 المشاكل المكتشفة

### 🔴 مشاكل حرجة (Critical)

| # | المشكلة | الموقع | الوصف |
|---|---------|--------|-------|
| C1 | **ملفات مكررة — PinSetupScreen** | `auth/presentation/pin_setup_screen.dart` + `auth/presentation/screens/pin_setup_screen.dart` | نسختان مختلفتان من نفس الشاشة. الأولى تستخدم SHA-256 مع SecureStorage، الثانية لا تحفظ PIN فعلياً. main.dart يستورد النسخة الأولى. |
| C2 | **ملفات مكررة — DashboardScreen** | `dashboard/.../dashboard_screen.dart` + `transactions/.../dashboard_screen.dart` | نسختان من لوحة التحكم. الأولى (المستخدمة) بها BottomNav لكن المحتوى مجرد نص. الثانية فيها بيانات ثابتة hardcoded. |
| C3 | **ملفات مكررة — Database** | `core/data/local/database.dart` + `core/database/database_helper.dart` | قاعدتا بيانات مختلفتان بنفس اسم الملف `bashnddof.db` لكن بجداول مختلفة. لا يستخدم أيٌّ منهما في أي شاشة! |
| C4 | **AddTransactionScreen لا تحفظ** | `transactions/.../add_transaction_screen.dart` | زر "حفظ" فارغ `onPressed: () {}`. الحقول `const TextField` بدون controllers. لا ترتبط بقاعدة البيانات. |
| C5 | **إعادة الضبط في Settings لا تعمل** | `settings_screen.dart:L57-L60` | `// Perform reset logic here` — التعليق فقط بدون كود فعلي. |
| C6 | **PinSetupScreen (screens/) لا تحفظ PIN** | `screens/pin_setup_screen.dart:L87-L88` | `// Here you would save the PIN securely` — لا يتم حفظ PIN فعلياً ثم ينتقل إلى صفحة الميزانية. |

### 🟠 مشاكل وسيطة (Medium)

| # | المشكلة | الموقع | الوصف |
|---|---------|--------|-------|
| M1 | **بيانات ثابتة (Hardcoded)** | `envelopes_screen.dart:L21-23` | الأظرف ثابتة: "طعام 500/1000"، "بنزين 400/500"، "ترفيه 350/400". غير مربوطة بقاعدة بيانات. |
| M2 | **شاشات فارغة** | `reports_screen.dart`، `recurring_transactions_screen.dart`، `savings_goals_screen.dart` | كل منها يعرض نص "شاشة X" فقط بدون أي وظائف. |
| M3 | **Dashboard الرئيسي محتواه نص فقط** | `dashboard/.../dashboard_screen.dart:L18` | `Center(child: Text('لوحة التحكم الرئيسية'))` — لا يعرض أي بيانات فعلية. |
| M4 | **لا يوجد state management** | كل المشروع | لا BLoC، لا Provider رغم أن `flutter_bloc` موجود في `pubspec.yaml`. |
| M5 | **لا يوجد DAO/Repository layer** | كل المشروع | لا توجد طبقة وسيطة بين الشاشات وقاعدة البيانات. |
| M6 | **InitialBudgetSetupScreen لا تحفظ البيانات** | `initial_budget_setup_screen.dart:L79-88` | تحفظ فقط `isFirstTime=false` لكن لا تحفظ يوم الشهر ولا الرصيد الافتتاحي. |

### 🟡 مشاكل UI/UX

| # | المشكلة | الموقع | الوصف |
|---|---------|--------|-------|
| U1 | **لا يوجد نظام ألوان مخصص** | `main.dart:L65-69` | يستخدم `primarySwatch: Colors.teal` الافتراضي. لا ThemeData مخصص. |
| U2 | **لا يوجد خط Tajawal مطبق** | `main.dart` | الخط معرّف في pubspec لكن غير مستخدم في ThemeData. |
| U3 | **شاشة الترحيب بسيطة جداً** | `intro_screen.dart` | لا صور، لا رسوم متحركة، لا تدرجات لونية. |
| U4 | **شاشة تسجيل الدخول بسيطة** | `login_screen.dart` | حقل نص عادي وزر. لا لوحة PIN مخصصة. لا بصمة إصبع. |
| U5 | **لا تأثيرات حركية** | كل التطبيق | لا animations، لا transitions مخصصة، لا micro-interactions. |
| U6 | **لا تدرجات لونية** | كل التطبيق | ألوان مسطحة بدون gradients. |
| U7 | **AppBar عادي في كل مكان** | كل الشاشات | لا SliverAppBar، لا تخصيص، تصميم افتراضي. |
| U8 | **FAB متكرر بدون وظيفة** | عدة شاشات | أزرار `+` في شاشات الأظرف والمعاملات الثابتة والادخار بدون وظائف. |
| U9 | **لا تغذية راجعة للمستخدم** | كل التطبيق | لا loading states، لا success messages، لا empty states مصممة. |
| U10 | **لا وضع داكن مخصص** | `main.dart:L69` | `darkTheme: ThemeData(brightness: Brightness.dark)` — بدون ألوان مخصصة. |

---

## 📊 ملخص الحالة

| المؤشر | القيمة |
|--------|--------|
| ملفات Dart في lib/ | ~20 ملف |
| الشاشات العاملة فعلياً | 3 من 10 (intro, pin_setup, login) |
| الميزات المتصلة بقاعدة البيانات | 0 من 5 |
| نسبة الكود الميت/المكرر | ~30% |
| نسبة اكتمال UI/UX | ~15% |
| نسبة اكتمال المنطق | ~20% |
| الاختبارات الموجودة | 0 (widget_test.dart افتراضي فقط) |

---

## 🔗 العلاقات من Graphify

```
main.dart (21 اتصال) ← God Node — يوجّه إلى:
  ├── intro_screen.dart → pin_setup_screen.dart → login_screen.dart → dashboard_screen.dart
  ├── secure_storage_service.dart (التخزين الآمن)
  └── add_transaction_screen.dart

login_screen.dart (13 اتصال):
  ├── يستورد: crypto, dart:convert, secure_storage_service.dart
  ├── يعرّف: LoginScreen, _LoginScreenState, _checkPin, _resetApp
  └── يتصل بـ: SecureStorageService.getPin()

secure_storage_service.dart (10 اتصال):
  └── يعرّف: SecureStorageService, getPin, savePin, deletePin, resetAll
  └── يستخدم: FlutterSecureStorage (flutter_secure_storage)

database_helper.dart (جداول: transactions, categories, envelopes, recurring_transactions, savings_goals)
database.dart     (جداول: transactions, categories, envelopes) ← مكرر ومختلف!
```
