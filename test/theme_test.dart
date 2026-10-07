import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bashnddof/src/core/theme/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ThemeService.init();
    });

    test('defaults to ThemeMode.system', () {
      expect(ThemeService.themeModeNotifier.value, equals(ThemeMode.system));
    });

    test('switches to ThemeMode.dark and persists', () async {
      await ThemeService.setThemeMode(ThemeMode.dark);
      expect(ThemeService.themeModeNotifier.value, equals(ThemeMode.dark));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), equals('dark'));
    });

    test('switches to ThemeMode.light and persists', () async {
      await ThemeService.setThemeMode(ThemeMode.light);
      expect(ThemeService.themeModeNotifier.value, equals(ThemeMode.light));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), equals('light'));
    });

    test('loads saved dark mode on init', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
      await ThemeService.init();
      expect(ThemeService.themeModeNotifier.value, equals(ThemeMode.dark));
    });
  });
}
