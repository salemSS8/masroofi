# 🔒 خطة تعزيز الأمان والتشفير

> **المرحلة 4** — تأمين البيانات المالية الحساسة  
> **الأولوية:** 🟡 متوسطة-عالية — تُنفذ بالتوازي مع المرحلة 3

---

## 🎯 الأهداف

التأكد من أن كل البيانات المالية محمية، والرمز السري مُخزّن بأمان، والتطبيق محصّن ضد الاستخدام غير المصرح به.

---

## 📋 المهام

### المهمة 4.1: تحسين نظام PIN

#### 4.1.1 — إصلاح التدفق الحالي
**المشاكل:**
- `screens/pin_setup_screen.dart` لا يحفظ PIN فعلياً (C6)
- `pin_setup_screen.dart` يحفظ لكن بدون confirm من الشاشة الثانية
- لا يوجد عداد محاولات خاطئة

**الحل:**
```dart
// تدفق PIN الموحد:
// 1. إدخال PIN (4 أو 6 أرقام)
// 2. تأكيد PIN (إدخال مرة ثانية)
// 3. التحقق من التطابق
// 4. تشفير SHA-256
// 5. حفظ في SecureStorage
// 6. الانتقال للخطوة التالية (إعداد الميزانية)
```

#### 4.1.2 — عداد المحاولات الخاطئة
```dart
class LoginAttemptManager {
  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 5);
  
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  
  bool get isLocked => _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);
  int get remainingAttempts => maxAttempts - _failedAttempts;
  
  void recordFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts >= maxAttempts) {
      _lockoutUntil = DateTime.now().add(lockoutDuration);
    }
  }
  
  void reset() {
    _failedAttempts = 0;
    _lockoutUntil = null;
  }
}
```

#### 4.1.3 — تغيير PIN من الإعدادات
```dart
// التدفق:
// 1. إدخال PIN الحالي → التحقق
// 2. إدخال PIN الجديد
// 3. تأكيد PIN الجديد
// 4. حفظ الجديد في SecureStorage
```

---

### المهمة 4.2: تعزيز SecureStorageService

#### 4.2.1 — إضافة وظائف جديدة
```dart
class SecureStorageService {
  // موجود:
  Future<void> savePin(String hashedPin);
  Future<String?> getPin();
  Future<void> deletePin();
  Future<void> resetAll();
  
  // جديد:
  Future<void> saveLastLogin(DateTime time);
  Future<DateTime?> getLastLogin();
  Future<void> saveFailedAttempts(int count);
  Future<int> getFailedAttempts();
  Future<void> saveLockoutUntil(DateTime? time);
  Future<DateTime?> getLockoutUntil();
  Future<void> saveCurrency(String currency);
  Future<String> getCurrency();
  Future<void> saveBudgetDay(int day);
  Future<int> getBudgetDay();
}
```

---

### المهمة 4.3: تشفير قاعدة البيانات (اختياري/متقدم)

#### الوضع الحالي
- `EncryptionService` موجود لكن غير مستخدم
- يستخدم `encrypt` package مع AES
- المفتاح مشتق من PIN (padded to 32 chars)

#### الخطة
**الخيار 1 (موصى به):** استخدام `sqflite_sqlcipher` لتشفير قاعدة البيانات بالكامل
```yaml
# pubspec.yaml
dependencies:
  sqflite_sqlcipher: ^3.1.0  # بدل sqflite
```
```dart
_db = await openDatabase(
  path,
  password: derivedKey,  // مشتق من PIN
  version: 1,
  onCreate: _createDB,
);
```

**الخيار 2 (أبسط):** تشفير الحقول الحساسة فقط (note, category)
```dart
Future<int> insertTransaction(TransactionModel t) async {
  final map = t.toMap();
  map['note'] = _encryptor.encrypt(map['note'] ?? '');
  return await db.insert('transactions', map);
}
```

---

### المهمة 4.4: المصادقة البيومترية (local_auth)

#### الوضع الحالي
- `local_auth: ^2.2.0` موجود في pubspec
- غير مستخدم في أي مكان

#### التنفيذ
```dart
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  
  Future<bool> isAvailable() async {
    return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
  }
  
  Future<bool> authenticate() async {
    return await _auth.authenticate(
      localizedReason: 'استخدم البصمة لفتح التطبيق',
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: false,
      ),
    );
  }
}
```

#### تكامل مع شاشة تسجيل الدخول
```dart
// في LoginScreen:
// 1. فحص إذا البصمة مفعّلة في الإعدادات
// 2. إذا نعم: عرض زر البصمة + لوحة PIN
// 3. إذا لا: لوحة PIN فقط
// 4. في الإعدادات: خيار تفعيل/تعطيل البصمة
```

---

### المهمة 4.5: أمان التطبيق العام

#### 4.5.1 — قفل التطبيق عند الخروج
```dart
// في main.dart أو AppLifecycleObserver:
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // عند الخروج من التطبيق → وضع علامة "يحتاج إعادة تسجيل دخول"
      SecureStorageService().saveNeedsReauth(true);
    }
    if (state == AppLifecycleState.resumed) {
      // عند العودة → فحص إذا يحتاج إعادة تسجيل
      // إذا نعم → توجيه لشاشة login
    }
  }
}
```

#### 4.5.2 — منع التقاط الشاشة (Android)
```kotlin
// في MainActivity.kt:
window.setFlags(
  WindowManager.LayoutParams.FLAG_SECURE,
  WindowManager.LayoutParams.FLAG_SECURE
)
```

#### 4.5.3 — تنظيف البيانات من الذاكرة
```dart
// عند الخروج من شاشات حساسة:
@override
void dispose() {
  _pinController.clear();
  _pinController.dispose();
  super.dispose();
}
```

---

### المهمة 4.6: النسخ الاحتياطي والاستعادة

#### تصدير (Export)
```dart
Future<String> exportData() async {
  final db = await DatabaseHelper.instance.database;
  final transactions = await db.query('transactions');
  final categories = await db.query('categories');
  final envelopes = await db.query('envelopes');
  final savings = await db.query('savings_goals');
  
  final data = {
    'version': 1,
    'exported_at': DateTime.now().toIso8601String(),
    'transactions': transactions,
    'categories': categories,
    'envelopes': envelopes,
    'savings_goals': savings,
  };
  
  // تشفير الملف المُصدَّر بـ PIN
  final encrypted = _encryptor.encrypt(jsonEncode(data));
  
  // حفظ كملف في مجلد التنزيلات
  final file = File('${downloadsPath}/bashnddof_backup_${date}.enc');
  await file.writeAsString(encrypted);
  return file.path;
}
```

#### استيراد (Import)
```dart
Future<void> importData(String filePath, String pin) async {
  final file = File(filePath);
  final encrypted = await file.readAsString();
  
  // فك التشفير بـ PIN
  final decrypted = _encryptor.decrypt(encrypted);
  final data = jsonDecode(decrypted);
  
  // استعادة البيانات
  await db.delete('transactions');
  for (var t in data['transactions']) {
    await db.insert('transactions', t);
  }
  // ... نفس الشيء لباقي الجداول
}
```

---

## ✅ معايير الاكتمال

- [ ] PIN يُحفظ مشفراً بـ SHA-256
- [ ] عداد محاولات خاطئة (5 محاولات → قفل 5 دقائق)
- [ ] تغيير PIN من الإعدادات
- [ ] البصمة/Face ID (اختياري من الإعدادات)
- [ ] قفل التطبيق عند الخروج وإعادة التسجيل عند العودة
- [ ] النسخ الاحتياطي المشفر
- [ ] استعادة من نسخة احتياطية
- [ ] لا يتم تخزين PIN كنص صريح في أي مكان
