import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة إدارة وتغيير سمات التطبيق (الوضع الفاتح / الداكن / التلقائي)
class ThemeService {
  static const String _themePrefKey = 'app_theme_mode';

  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// تحميل السمة المحفوظة عند إقلاع التطبيق
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themePrefKey);

    switch (savedMode) {
      case 'light':
        themeModeNotifier.value = ThemeMode.light;
        break;
      case 'dark':
        themeModeNotifier.value = ThemeMode.dark;
        break;
      case 'system':
      default:
        themeModeNotifier.value = ThemeMode.system;
        break;
    }
  }

  /// تغيير وحفظ السمة المختارة فورياً
  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;

    final prefs = await SharedPreferences.getInstance();
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    await prefs.setString(_themePrefKey, modeString);
  }
}
