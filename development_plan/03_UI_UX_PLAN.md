# 🎨 خطة تحسين واجهة المستخدم وتجربة الاستخدام (UI/UX)

> **المرحلة 2** — التحول من واجهة أولية إلى تصميم احترافي  
> **الأولوية:** 🟠 عالية — تُنفذ بالتوازي مع المرحلة 1

---

## 🎯 الرؤية التصميمية

**النمط المستهدف:** تصميم عصري نظيف (Modern Clean) مع لمسات **Glassmorphism** خفيفة  
**الاتجاه:** RTL (عربي بالكامل)  
**الخط:** Tajawal (موجود في assets لكن غير مُفعّل)  
**الفلسفة:** بسيط لكن أنيق — الأولوية للوضوح والراحة

---

## 🎨 المهمة 2.1: نظام الألوان المخصص

### لوحة الألوان المقترحة

#### الوضع الفاتح (Light Mode)
```dart
// الألوان الأساسية
static const Color primary       = Color(0xFF1B8A6B);  // أخضر زمردي عميق
static const Color primaryLight  = Color(0xFF4ECDC4);  // أخضر فيروزي فاتح
static const Color primaryDark   = Color(0xFF0D5C46);  // أخضر داكن

// ألوان الخلفية
static const Color background    = Color(0xFFF7F9FC);  // رمادي فاتح جداً
static const Color surface       = Color(0xFFFFFFFF);  // أبيض
static const Color surfaceAlt    = Color(0xFFF0F4F8);  // سطح بديل

// ألوان النصوص
static const Color textPrimary   = Color(0xFF1A2332);  // أسود-أزرق عميق
static const Color textSecondary = Color(0xFF6B7B8D);  // رمادي متوسط
static const Color textHint      = Color(0xFFA0AEC0);  // رمادي فاتح

// ألوان الحالة
static const Color income        = Color(0xFF27AE60);  // أخضر — دخل
static const Color expense       = Color(0xFFE74C3C);  // أحمر — مصروف
static const Color warning       = Color(0xFFF39C12);  // برتقالي — تحذير
static const Color info          = Color(0xFF3498DB);  // أزرق — معلومات

// ألوان الأظرف (Envelopes)
static const List<Color> envelopeColors = [
  Color(0xFF6C5CE7),  // بنفسجي
  Color(0xFF00B894),  // أخضر نعناعي
  Color(0xFFFD79A8),  // وردي
  Color(0xFFE17055),  // مرجاني
  Color(0xFF0984E3),  // أزرق
  Color(0xFFFFC312),  // ذهبي
];
```

#### الوضع الداكن (Dark Mode)
```dart
static const Color darkBackground   = Color(0xFF0F1923);  // أزرق-أسود عميق
static const Color darkSurface      = Color(0xFF1A2736);  // سطح داكن
static const Color darkSurfaceAlt   = Color(0xFF243447);  // سطح بديل
static const Color darkTextPrimary  = Color(0xFFE8ECF1);  // أبيض مائل للرمادي
static const Color darkTextSecondary = Color(0xFF8899A6); // رمادي فاتح
```

---

## 🖋️ المهمة 2.2: تفعيل خط Tajawal

```dart
// في app_theme.dart
textTheme: TextTheme(
  displayLarge:  TextStyle(fontFamily: 'Tajawal', fontSize: 32, fontWeight: FontWeight.w700),
  headlineLarge: TextStyle(fontFamily: 'Tajawal', fontSize: 24, fontWeight: FontWeight.w700),
  headlineMedium: TextStyle(fontFamily: 'Tajawal', fontSize: 20, fontWeight: FontWeight.w600),
  titleLarge:    TextStyle(fontFamily: 'Tajawal', fontSize: 18, fontWeight: FontWeight.w600),
  titleMedium:   TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.w500),
  bodyLarge:     TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.w400),
  bodyMedium:    TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.w400),
  labelLarge:    TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.w500),
),
```

---

## 🖼️ المهمة 2.3: إعادة تصميم كل شاشة

### 2.3.1 — شاشة الترحيب (IntroScreen)
**المشاكل الحالية:** نص عادي + زر بسيط، لا صور ولا تأثيرات  
**التصميم المستهدف:**
- خلفية تدرج لوني (Gradient) من `primary` إلى `primaryLight`
- أيقونة محفظة كبيرة مع تأثير ظل (Shadow)
- عنوان بخط كبير مع تأثير FadeIn
- وصف التطبيق بخط متوسط
- زر "ابدأ" بتصميم Rounded مع تأثير Scale عند الضغط
- مؤشر نقاط (PageIndicator) إذا أضفنا عدة صفحات ترحيب
- **تأثيرات:** `FadeInUp` + `SlideTransition` للعناصر

### 2.3.2 — شاشة إعداد PIN (PinSetupScreen)
**المشاكل الحالية:** حقول نص عادية، لا لوحة PIN مخصصة  
**التصميم المستهدف:**
- **لوحة PIN مخصصة** (4-6 نقاط مع تأثير ملء)
- لوحة أرقام مخصصة (Custom Numeric Keypad) بتأثير Ripple
- شريط تقدم يوضح "أدخل الرمز" → "أكد الرمز"
- أيقونة قفل متحركة في الأعلى
- **تأثيرات:** اهتزاز عند الخطأ (Shake Animation)، ملء النقاط بـ ScaleTransition

### 2.3.3 — شاشة تسجيل الدخول (LoginScreen)
**المشاكل الحالية:** حقل نص + زر بسيط  
**التصميم المستهدف:**
- نفس لوحة PIN المخصصة من شاشة الإعداد
- زر البصمة/Face ID (اختياري مستقبلاً عبر `local_auth`)
- أيقونة قفل مع تأثير فتح عند النجاح
- عداد محاولات خاطئة
- **تأثيرات:** اهتزاز عند الخطأ، انتقال Unlock عند النجاح

### 2.3.4 — لوحة التحكم (DashboardScreen)
**المشاكل الحالية:** نص فقط / بيانات ثابتة  
**التصميم المستهدف:**
- **بطاقة الرصيد العلوية:**
  - خلفية Gradient مع Glassmorphism
  - الرصيد المتاح بخط كبير
  - إجمالي الدخل والمصروف بأيقونات ▲ ▼
- **شريط الإجراءات السريعة:**
  - 4 أزرار دائرية: إضافة مصروف، إضافة دخل، تحويل، أظرف
- **قسم الأظرف:**
  - بطاقات أفقية قابلة للتمرير (Horizontal ScrollView)
  - شريط تقدم دائري (CircularPercentIndicator)
- **سجل العمليات الأخيرة:**
  - قائمة مع أيقونات التصنيف وألوان الحالة
  - Swipe-to-delete
- **BottomNavigationBar محسّن:**
  - 4 عناصر: الرئيسية، الأظرف، التقارير، الإعدادات
  - تأثير Active مع لون primary

### 2.3.5 — شاشة إضافة معاملة (AddTransactionScreen)
**المشاكل الحالية:** حقول لا تعمل، لا تحفظ  
**التصميم المستهدف:**
- Tab لتبديل بين مصروف/دخل مع تأثير لوني
- حقل المبلغ بخط كبير مع عملة
- اختيار التصنيف من شبكة أيقونات (Grid)
- اختيار التاريخ عبر DatePicker مع تقويم عربي
- اختيار الظرف (اختياري)
- حقل الملاحظة
- زر حفظ بعرض كامل مع تأثير نجاح

### 2.3.6 — شاشة الأظرف (EnvelopesScreen)
**المشاكل الحالية:** بيانات ثابتة  
**التصميم المستهدف:**
- بطاقات بارتفاع مناسب مع لون مخصص لكل ظرف
- شريط تقدم دائري مع نسبة مئوية
- أيقونة مخصصة لكل ظرف
- إمكانية إضافة/تعديل/حذف
- **BottomSheet** لإضافة ظرف جديد

### 2.3.7 — شاشة التقارير (ReportsScreen)
**المشاكل الحالية:** فارغة تماماً  
**التصميم المستهدف:**
- **رسم بياني دائري (PieChart)** — توزيع المصاريف حسب التصنيف
- **رسم بياني شريطي (BarChart)** — مقارنة يومية/أسبوعية/شهرية
- فلتر زمني (اليوم، الأسبوع، الشهر، مخصص)
- إجمالي الدخل vs المصروف
- **مكتبة:** `fl_chart` (موجودة بالفعل في pubspec)

### 2.3.8 — شاشة المعاملات الثابتة (RecurringTransactionsScreen)
**المشاكل الحالية:** فارغة تماماً  
**التصميم المستهدف:**
- قائمة بالمعاملات المتكررة مع يوم الاستقطاع
- تبديل تفعيل/تعطيل (Switch)
- BottomSheet للإضافة/التعديل
- أيقونة ساعة تشير لآخر تنفيذ

### 2.3.9 — شاشة أهداف الادخار (SavingsGoalsScreen)
**المشاكل الحالية:** فارغة تماماً  
**التصميم المستهدف:**
- بطاقة كبيرة لكل هدف مع شريط تقدم
- المبلغ الحالي / المبلغ المستهدف
- تاريخ الموعد النهائي
- زر "إيداع" سريع
- **تأثير:** Celebration Animation عند الوصول 100%

### 2.3.10 — شاشة الإعدادات (SettingsScreen)
**المشاكل الحالية:** إعادة الضبط لا تعمل  
**التصميم المستهدف:**
- بطاقة الملف الشخصي (اختياري)
- إعدادات مقسمة بعناوين
- مبدّل الوضع الداكن
- تغيير العملة
- تغيير يوم بداية الشهر
- تصدير/نسخ احتياطي
- إعادة ضبط فعّالة

---

## ✨ المهمة 2.4: التأثيرات الحركية (Animations)

### تأثيرات عامة
| التأثير | الاستخدام |
|---------|----------|
| `FadeTransition` | ظهور الشاشات |
| `SlideTransition` | انتقال بين الصفحات |
| `ScaleTransition` | ظهور الأزرار والبطاقات |
| `Hero` | انتقال بطاقة الرصيد |
| `AnimatedSwitcher` | تبديل المحتوى |
| `AnimatedContainer` | تغيير الألوان والأحجام |

### تأثيرات مخصصة
| التأثير | الاستخدام |
|---------|----------|
| Shake Animation | اهتزاز حقل PIN عند الخطأ |
| Confetti/Celebration | الوصول لهدف ادخار |
| Ripple Effect | ضغط على أزرار لوحة الأرقام |
| Count Up Animation | عرض المبالغ |
| Progress Fill | ملء نقاط PIN |

---

## 📱 المهمة 2.5: تحسينات تجربة الاستخدام (UX)

### 2.5.1 — حالات الفراغ (Empty States)
كل شاشة بدون بيانات تعرض:
- أيقونة كبيرة معبّرة
- نص توضيحي
- زر إجراء (مثل: "أضف أول معاملة")

### 2.5.2 — حالات التحميل (Loading States)
- Shimmer Effect أثناء تحميل البيانات
- Skeleton Screens بدل Spinner عادي

### 2.5.3 — التغذية الراجعة (Feedback)
- SnackBar مخصص بألوان الحالة (نجاح/خطأ/تحذير)
- تأثير Haptic Feedback عند الإجراءات المهمة
- رسائل تأكيد قبل الحذف

### 2.5.4 — التنقل (Navigation)
- Page transitions سلسة
- Swipe back في iOS
- BottomSheet بدل Dialog للإضافة السريعة

---

## ✅ معايير الاكتمال

- [ ] نظام ألوان مخصص مُطبق (فاتح + داكن)
- [ ] خط Tajawal مفعّل في كل النصوص
- [ ] كل شاشة مُعاد تصميمها
- [ ] تأثيرات حركية مُطبقة
- [ ] Empty States مصممة لكل شاشة
- [ ] Loading States بـ Shimmer
- [ ] التبديل بين الوضع الفاتح والداكن يعمل
- [ ] RTL مدعوم بالكامل بدون مشاكل
