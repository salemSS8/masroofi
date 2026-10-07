# 🧪 خطة الاختبارات والتلميع النهائي

> **المرحلة 5** — ضمان الجودة والتلميع قبل الإطلاق  
> **الأولوية:** 🟡 متوسطة — تُنفذ بعد اكتمال الميزات

---

## 🎯 الأهداف

1. كتابة اختبارات شاملة لكل طبقة
2. إصلاح أي أخطاء مكتشفة
3. تحسين الأداء
4. تلميع التفاصيل الدقيقة

---

## 📋 المهام

### المهمة 5.1: اختبارات الوحدات (Unit Tests)

#### 5.1.1 — اختبار النماذج (Models)
```dart
// test/models/transaction_model_test.dart
group('TransactionModel', () {
  test('toMap returns correct map', () { ... });
  test('fromMap creates correct model', () { ... });
  test('roundtrip toMap -> fromMap preserves data', () { ... });
});
// نفس الشيء لـ CategoryModel, EnvelopeModel, SavingsGoalModel, RecurringModel
```

#### 5.1.2 — اختبار المستودعات (Repositories)
```dart
// test/repositories/transaction_repository_test.dart
group('TransactionRepository', () {
  test('insert and retrieve transaction', () { ... });
  test('getByDateRange returns filtered results', () { ... });
  test('getTotalExpenses calculates correctly', () { ... });
  test('delete removes transaction', () { ... });
  test('getExpensesByCategory returns correct grouping', () { ... });
});
```

#### 5.1.3 — اختبار خدمة التخزين الآمن
```dart
// test/services/secure_storage_service_test.dart
group('SecureStorageService', () {
  test('savePin stores hashed pin', () { ... });
  test('getPin retrieves stored pin', () { ... });
  test('resetAll clears all data', () { ... });
  test('failed attempts tracking', () { ... });
});
```

#### 5.1.4 — اختبار خدمة التشفير
```dart
// test/security/encryption_service_test.dart
group('EncryptionService', () {
  test('encrypt produces non-empty string', () { ... });
  test('decrypt reverses encrypt', () { ... });
  test('different pins produce different ciphertexts', () { ... });
});
```

---

### المهمة 5.2: اختبارات BLoC

```dart
// test/bloc/transactions_bloc_test.dart
blocTest<TransactionsBloc, TransactionsState>(
  'emits [Loading, Loaded] when LoadTransactions is added',
  build: () => TransactionsBloc(mockRepository),
  act: (bloc) => bloc.add(LoadTransactions()),
  expect: () => [TransactionsLoading(), TransactionsLoaded(transactions)],
);

blocTest<TransactionsBloc, TransactionsState>(
  'emits [Loading, Loaded] when AddTransaction is added',
  build: () => TransactionsBloc(mockRepository),
  act: (bloc) => bloc.add(AddTransaction(newTransaction)),
  expect: () => [isA<TransactionsLoading>(), isA<TransactionsLoaded>()],
);
```

---

### المهمة 5.3: اختبارات الواجهة (Widget Tests)

```dart
// test/widgets/login_screen_test.dart
testWidgets('LoginScreen shows PIN keypad', (tester) async {
  await tester.pumpWidget(MaterialApp(home: LoginScreen()));
  expect(find.text('تسجيل الدخول'), findsOneWidget);
  // اختبار إدخال PIN
  // اختبار رسالة الخطأ
});

// test/widgets/dashboard_screen_test.dart
testWidgets('DashboardScreen shows balance card', (tester) async {
  await tester.pumpWidget(/* ... */);
  expect(find.text('الرصيد المتاح للإنفاق'), findsOneWidget);
});

// test/widgets/add_transaction_screen_test.dart
testWidgets('AddTransactionScreen validates amount', (tester) async {
  // اختبار validation
  // اختبار الحفظ
});
```

---

### المهمة 5.4: اختبار التكامل (Integration Tests)

```dart
// integration_test/app_test.dart
testWidgets('Full app flow: setup -> login -> add transaction', (tester) async {
  app.main();
  await tester.pumpAndSettle();
  
  // 1. شاشة الترحيب
  expect(find.text('ابدأ'), findsOneWidget);
  await tester.tap(find.text('ابدأ'));
  await tester.pumpAndSettle();
  
  // 2. إعداد PIN
  // ... إدخال PIN وتأكيده
  
  // 3. إعداد الميزانية
  // ... إدخال يوم الشهر والرصيد
  
  // 4. تسجيل الدخول
  // ... إدخال PIN
  
  // 5. لوحة التحكم
  expect(find.text('الرصيد المتاح'), findsOneWidget);
  
  // 6. إضافة معاملة
  await tester.tap(find.byIcon(Icons.add));
  // ... ملء الحقول والحفظ
});
```

---

### المهمة 5.5: تحسين الأداء

#### 5.5.1 — قاعدة البيانات
- إضافة فهارس (Indexes) للأعمدة المستخدمة في الاستعلامات:
  ```sql
  CREATE INDEX idx_transactions_datetime ON transactions(datetime);
  CREATE INDEX idx_transactions_type ON transactions(type);
  CREATE INDEX idx_transactions_category ON transactions(category_id);
  CREATE INDEX idx_transactions_envelope ON transactions(envelope_id);
  ```
- استخدام `batch` للعمليات المتعددة

#### 5.5.2 — الواجهة
- استخدام `const` constructors حيثما أمكن
- `ListView.builder` بدل `ListView` للقوائم الطويلة
- تجنب إعادة بناء الـ widgets غير المتغيرة
- استخدام `RepaintBoundary` للعناصر المعقدة

#### 5.5.3 — الذاكرة
- `dispose` لكل controller و subscription
- تجنب تحميل كل المعاملات في الذاكرة (pagination)

---

### المهمة 5.6: التلميع النهائي (Polish)

#### 5.6.1 — التفاصيل البصرية
- [ ] التأكد من محاذاة كل العناصر في RTL
- [ ] التأكد من عمل الـ overflow بشكل صحيح (نصوص طويلة)
- [ ] التأكد من تناسق الـ padding و margin
- [ ] التأكد من عمل الألوان في الوضع الفاتح والداكن
- [ ] التأكد من عمل الخط Tajawal في كل مكان
- [ ] التأكد من وضوح الأرقام (عربية/إنجليزية حسب الإعداد)

#### 5.6.2 — تجربة الاستخدام
- [ ] كل زر يعطي feedback (SnackBar أو visual)
- [ ] كل عملية حذف لها تأكيد
- [ ] لا يوجد dead-end في التنقل
- [ ] Back button يعمل بشكل صحيح في كل شاشة
- [ ] Keyboard لا يحجب المحتوى

#### 5.6.3 — التعامل مع الأخطاء
- [ ] رسائل خطأ واضحة بالعربي
- [ ] Try-catch حول كل عملية قاعدة بيانات
- [ ] Fallback UI عند فشل التحميل
- [ ] لا crashes عند بيانات فارغة أو null

#### 5.6.4 — الوصولية (Accessibility)
- [ ] Semantic labels على كل عنصر تفاعلي
- [ ] أحجام خطوط كافية (≥ 14sp)
- [ ] تباين ألوان كافٍ (WCAG AA)
- [ ] دعم TalkBack/VoiceOver

---

### المهمة 5.7: إعداد الإطلاق

#### 5.7.1 — App Icon
- تصميم أيقونة مخصصة (محفظة/عملة)
- `flutter_launcher_icons` لتوليد كل الأحجام

#### 5.7.2 — Splash Screen
- `flutter_native_splash` لشاشة تحميل مخصصة
- لون الخلفية: primary gradient

#### 5.7.3 — تنظيف pubspec.yaml
- حذف الحزم غير المستخدمة
- ترتيب وتوثيق كل حزمة

---

## ✅ معايير الاكتمال

- [ ] ≥ 80% تغطية اختبارات للنماذج والمستودعات
- [ ] اختبار BLoC لكل feature
- [ ] اختبار واجهة لكل شاشة رئيسية
- [ ] اختبار تكامل لتدفق التطبيق الكامل
- [ ] لا warnings في `flutter analyze`
- [ ] لا crashes في أي سيناريو
- [ ] أداء سلس (60fps) في كل الشاشات
- [ ] App icon + splash screen مخصصة
