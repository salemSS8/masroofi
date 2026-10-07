# دليل ومواصفات التكامل الهندسي بين تطبيقي (مصروفي) و (وصاة)
## Masroufi & Wasaat Ecosystem Integration Specification

---

## 1. نظرة عامة على المنظومة (Ecosystem Overview)

تهدف هذه المنظومة إلى توفير حل مالي عائلي متكامل يجمع بين **الحوكمة والتواصل العائلي السحابي** في تطبيق **«وصاة»**، وبين **الخصوصية والأمان والميزانية المشفرة** في تطبيق **«مصروفي»**.

```
[هواتف الأبناء / الأسرة]              [هاتف رب الأسرة (المحور المركزي)]
   (تطبيق وصاة)                          (تطبيق وصاة)
        │                                     │
        ▼                                     ▼
 [سحابة وصاة السريعة] ───────────────► [اعتماد رب الأسرة للطلب]
 (Firebase / Supabase)                        │
                                              ▼ (اتصال محلي صامت IPC)
                                        [تطبيق مصروفي]
                                     (خصم الميزانية + إشعار محلي)
```

### أطراف المنظومة:
1. **تطبيق «وصاة» (Wasaat):**
   * تطبيق عائلي سحابي يُثبت على هواتف أفراد الأسرة وهاتف رب الأسرة.
   * يتيح للأفراد رفع طلبات المصروفات والاحتياجات ومتابعة ميزانياتهم المخصصة.
   * يتيح لرب الأسرة مراجعة الطلبات، قبولها أو تعديلها أو رفضها.
2. **تطبيق «مصروفي» (Masroufi):**
   * المحفظة الشخصية المشفرة لرب الأسرة (Offline-First).
   * يحتوي على ميزانية الأظرف المالية الكلية للمنزل.
   * يستقبل المصروف المعتمد من «وصاة» ويخصمه تلقائياً وبصمت من الظرف المالي المحدد.

---

## 2. معمارية الربط والتواصل المحلي (Local IPC Architecture)

يتم التواصل بين التطبيقين على هاتف رب الأسرة محلياً بالكامل عبر **Android ContentProvider** مؤمن بأعلى معايير نظام أندرويد (`Signature Permission`)، دون الحاجة لفتح تطبيق مصروفي في الواجهة ودون إرسال بيانات مصروفي المالية إلى أي خادم خارجي.

### بيانات الـ ContentProvider في تطبيق «مصروفي»:
* **Authority:** `com.example.bashnddof.provider`
* **صلاحية الحماية:** `com.example.bashnddof.permission.INTEGRATION`
* **مستوى الصلاحية (Protection Level):** `signature` (حصري للتطبيقات الموقعة بنفس شهادة المطور).

---

## 3. نقاط الاتصال والخدمات المتاحة (Endpoints & URIs)

| الرابط (URI) | العملية | الوظيفة |
|---|---|---|
| `content://com.example.bashnddof.provider/envelopes` | `query()` | جلب جميع الأظرف المالية مع المبالغ المخصصة والمصروفة والمتبقية |
| `content://com.example.bashnddof.provider/transactions` | `insert()` | تسجيل معاملة مصروف جديدة وخصمها من الظرف المحدد فوراً |
| `content://com.example.bashnddof.provider/status` | `query()` | فحص حالة الاتصال وتوفر قاعدة بيانات مصروفي |

---

## 4. عقود وهياكل البيانات (Data Contracts)

### أ) استعلام الأظرف (`GET /envelopes`):
عند استعلام تطبيق «وصاة» عن الأظرف، يعيد الـ `Cursor` الأعمدة التالية لكل ظرف:

| اسم الحقل | النوع البرمجي | الوصف |
|---|---|---|
| `id` / `_id` | `INTEGER` | المعرف الفريد للظرف في مصروفي |
| `name` | `TEXT` | اسم الظرف (مثال: مقاضي المنزل، تعليم الأبناء) |
| `allocated_amount` | `REAL` | الميزانية المحددة للظرف |
| `spent_amount` | `REAL` | إجمالي المبالغ المصروفة من الظرف حتى الآن |
| `remaining_amount` | `REAL` | المبلغ المتبقي المتاح في الظرف |
| `icon` | `TEXT` | اسم أو رمز الأيقونة المرتبطة بالظرف |
| `color` | `INTEGER` | القيمة اللونية للظرف (Hex Color Int) |

### ب) إضافة مصروف معتمد (`INSERT /transactions`):
عند اعتماد رب الأسرة لمصروف في تطبيق «وصاة»، يتم تمرير القيم التالية في كائن `ContentValues`:

| المفتاح (Key) | النوع | إلزامي؟ | الوصف |
|---|---|---|---|
| `title` | `String` | **نعم** | عنوان المصروف واسم الطالب (مثال: "شراء كتب - أحمد") |
| `amount` | `Double` | **نعم** | المبلغ المعتمد للصرف |
| `envelope_id` | `Int` | **نعم** | معرّف الظرف المالي المراد الخصم منه في مصروفي |
| `category_id` | `Int` | لا (اختياري) | معرّف التصنيف إن وجد |
| `notes` | `String` | لا (اختياري) | ملاحظات إضافية (تلقائياً: "معتمد عبر تطبيق وصاة") |

---

## 5. المتطلبات الأمنية الإلزامية للمبرمج (Security Guidelines)

> [!IMPORTANT]
> لكي يتمكن تطبيق «وصاة» من الاتصال بتطبيق «مصروفي»، يجب تطبيق القواعد الأمنية التالية بدقة:

### 1. توقيع التطبيقين بنفس المفتاح (Keystore Signature):
* تم حماية مزود المحتوى في «مصروفي» بالصلاحية:
  ```xml
  <permission
      android:name="com.example.bashnddof.permission.INTEGRATION"
      android:protectionLevel="signature" />
  ```
* **القاعدة الذهبية:** لن يسمح نظام أندرويد لأي تطبيق بالاتصال بمصروفي إلا إذا كان موقعاً بـ **نفس ملف التوقيع (`keystore.jks`)** المستخدم في بناء «مصروفي».
* **أثناء التطوير (Debug Mode):** استخدم نفس الـ `debug.keystore` في المشروعين لكي يعمل الربط بسلاسة أثناء الفحص.
* **للإطلاق (Release Mode):** يجب استخدام نفس الـ `upload-keystore.jks` لتوقيع نسختي Release للتطبيقين.

### 2. إعدادات Manifest في تطبيق «وصاة»:
يجب إضافة السطور التالية داخل ملف `android/app/src/main/AndroidManifest.xml` الخاص بتطبيق **«وصاة»**:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- 1. طلب الصلاحية المشتركة للتواصل مع مصروفي -->
    <uses-permission android:name="com.example.bashnddof.permission.INTEGRATION" />

    <!-- 2. السماح لتطبيق وصاة برؤية تطبيق مصروفي على أندرويد 11+ (Package Visibility) -->
    <queries>
        <package android:name="com.example.bashnddof" />
        <provider android:authorities="com.example.bashnddof.provider" />
    </queries>

    <application ...>
        ...
    </application>
</manifest>
```

### 3. رمز الأمان المشترك (Shared Security Token):
* يوفر تطبيق «مصروفي» في شاشة **الإعدادات > الربط مع تطبيق وصاة** رمز أمان خاص (`Token`) مشفراً عشوائياً.
* يمكن لمطور «وصاة» تخزين هذا الرمز في إعدادات التطبيق لزيادة التحقق والتأكد من موثوقية كل معاملة.

---

## 6. كود دارت الجاهز لتطبيق «وصاة» (Dart Integration Code)

يمكن لمبرمج تطبيق «وصاة» استخدام الكود التالي مباشرة (باستخدام Platform Channel أو MethodChannel أو عبر Native Android):

### أ) كود Kotlin المساعد في تطبيق «وصاة» (`MainActivity.kt`):
```kotlin
package com.wasaat.family

import android.content.ContentValues
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.wasaat.family/masroufi_bridge"
    private val AUTHORITY = "com.example.bashnddof.provider"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getEnvelopes" -> {
                    try {
                        val uri = Uri.parse("content://$AUTHORITY/envelopes")
                        val cursor = contentResolver.query(uri, null, null, null, null)
                        val list = mutableListOf<Map<String, Any>>()
                        cursor?.use {
                            while (it.moveToNext()) {
                                val item = mapOf(
                                    "id" to it.getInt(it.getColumnIndexOrThrow("id")),
                                    "name" to it.getString(it.getColumnIndexOrThrow("name")),
                                    "allocated_amount" to it.getDouble(it.getColumnIndexOrThrow("allocated_amount")),
                                    "spent_amount" to it.getDouble(it.getColumnIndexOrThrow("spent_amount")),
                                    "remaining_amount" to it.getDouble(it.getColumnIndexOrThrow("remaining_amount"))
                                )
                                list.add(item)
                            }
                        }
                        result.success(list)
                    } catch (e: Exception) {
                        result.error("QUERY_ERROR", e.message, null)
                    }
                }
                "deductExpense" -> {
                    try {
                        val title = call.argument<String>("title") ?: "مصروف عائلي"
                        val amount = call.argument<Double>("amount") ?: 0.0
                        val envelopeId = call.argument<Int>("envelopeId") ?: 1
                        val notes = call.argument<String>("notes") ?: "معتمد عبر تطبيق وصاة"

                        val uri = Uri.parse("content://$AUTHORITY/transactions")
                        val values = ContentValues().apply {
                            put("title", title)
                            put("amount", amount)
                            put("envelope_id", envelopeId)
                            put("notes", notes)
                        }
                        val insertedUri = contentResolver.insert(uri, values)
                        result.success(insertedUri != null)
                    } catch (e: Exception) {
                        result.error("INSERT_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
```

### ب) كود خدمة دارت في تطبيق «وصاة» (`masroufi_bridge_service.dart`):
```dart
import 'package:flutter/services.dart';

class MasroufiBridgeService {
  static const MethodChannel _channel = MethodChannel('com.wasaat.family/masroufi_bridge');

  /// جلب قائمة الأظرف من تطبيق مصروفي
  static Future<List<Map<String, dynamic>>> getEnvelopes() async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getEnvelopes');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      print('خطأ في جلب أظرف مصروفي: $e');
      return [];
    }
  }

  /// خصم وتأكيد المصروف في مصروفي صامتاً
  static Future<bool> deductExpense({
    required String title,
    required double amount,
    required int envelopeId,
    String? notes,
  }) async {
    try {
      final bool? success = await _channel.invokeMethod('deductExpense', {
        'title': title,
        'amount': amount,
        'envelopeId': envelopeId,
        'notes': notes ?? 'معتمد عبر تطبيق وصاة',
      });
      return success ?? false;
    } catch (e) {
      print('خطأ في خصم المصروف في مصروفي: $e');
      return false;
    }
  }
}
```

---

## 7. سيناريو تجربة الاستخدام الكامل (Workflow Example)

1. يقوم **الابن (أحمد)** بفتح تطبيق «وصاة» ورفع طلب:
   * **البند:** شراء كتب ومستلزمات دراسية
   * **المبلغ المطلوب:** 5,000 ريال
2. يستقبل **رب الأسرة** إشعاراً في تطبيق «وصاة».
3. يفتح رب الأسرة شاشة تفاصيل الطلب في «وصاة»:
   * يقوم تطبيق «وصاة» باستدعاء `MasroufiBridgeService.getEnvelopes()`.
   * تظهر قائمة منسدلة أنيقة بجميع أظرف رب الأسرة من مصروفي (مثل: *مقاضي المنزل: متبقي 20,000 ريال*، *تعليم الأبناء: متبقي 15,000 ريال*).
4. يختار رب الأسرة ظرف **"تعليم الأبناء"** وينقر على **[اعتماد وصرف]**.
5. فوراً وبصمت في الخلفية:
   * يتم استدعاء `MasroufiBridgeService.deductExpense()`.
   * يقوم تطبيق «مصروفي» بخصم 5,000 ريال وتسجيل المعاملة.
   * يصدر تطبيق «مصروفي» إشعاراً محلياً رسمياً في ستارة الهاتف:
     > *"مصروفي | تم تسجيل مصروف (شراء كتب ومستلزمات دراسية) بمبلغ 5,000 ريال من ظرف تعليم الأبناء (اعتماد وصاة)"*
6. يتم تحديث حالة الطلب في «وصاة» إلى "معتمد"، ليصل إشعار فرح للابن على هاتفه!

---

## 8. الحالات الاستثنائية والتعامل معها (Edge Cases)

| الحالة | المعالجة البرمجية |
|---|---|
| **تطبيق مصروفي غير مثبت على هاتف الأب** | يقوم كود `getEnvelopes` بإرجاع قائمة فارغة بأمان، ويتيح تطبيق وصاة للأب الاعتماد دون خصم محلي مع تنبيه بتثبيت مصروفي. |
| **تطبيق مصروفي مقفل أو مغلق تماماً** | نظام `Android ContentProvider` يعمل حتى وإن كان التطبيق مغلقاً تماماً في الخلفية، ويقوم بفتح قاعدة البيانات محلياً وإتمام الخصم بنجاح. |
| **المبلغ المعتمد يتجاوز رصيد الظرف** | يقبل تطبيق مصروفي تسجيل المعاملة، ويتحول مؤشر الظرف إلى وضع التنبيه (`OverBudget`) لتنبيه رب الأسرة بزيادة الاستهلاك. |
| **محاولة تطبيق غير مصرح به الاتصال بمصروفي** | يرفض نظام التشغيل أندرويد الاتصال فوراً ويلقي استثناء `SecurityException` لأن التطبيق لا يحمل توقيع المطور المشترك (`Signature Permission`). |

---

*تاريخ التحديث: أكتوبر 2026*  
*فريق تطوير منظومة: مصروفي & وصاة*
