import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة إدارة لغة التطبيق (العربية والإنجليزية) والاتجاه (RTL / LTR)
class LanguageService {
  static const String _langPrefKey = 'app_language_code';

  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier<Locale>(const Locale('ar'));

  /// الحصول على اللغة الحالية
  static Locale get currentLocale => localeNotifier.value;

  /// هل التطبيق باللغة العربية حالياً؟
  static bool get isArabic => localeNotifier.value.languageCode == 'ar';

  /// تحميل اللغة المحفوظة عند الإقلاع
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_langPrefKey);

    if (savedCode == 'en') {
      localeNotifier.value = const Locale('en');
    } else {
      localeNotifier.value = const Locale('ar');
    }
  }

  /// تغيير وحفظ لغة التطبيق فورياً
  static Future<void> setLocale(Locale locale) async {
    localeNotifier.value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langPrefKey, locale.languageCode);
  }

  /// التبديل السريع بين العربية والإنجليزية
  static Future<void> toggleLanguage() async {
    final next = isArabic ? const Locale('en') : const Locale('ar');
    await setLocale(next);
  }
}
