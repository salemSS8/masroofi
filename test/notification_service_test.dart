import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bashnddof/src/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Tests', () {
    late NotificationService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = NotificationService();
    });

    test('NotificationService maintains singleton instance', () {
      final s1 = NotificationService();
      final s2 = NotificationService();
      expect(identical(s1, s2), isTrue);
    });

    test('isNotificationsEnabled defaults to true', () async {
      final enabled = await service.isNotificationsEnabled();
      expect(enabled, isTrue);
    });

    test('setNotificationsEnabled persists correctly', () async {
      await service.setNotificationsEnabled(false);
      expect(await service.isNotificationsEnabled(), isFalse);

      await service.setNotificationsEnabled(true);
      expect(await service.isNotificationsEnabled(), isTrue);
    });

    test('getReminderTime defaults to 21:00 (9:00 PM)', () async {
      final time = await service.getReminderTime();
      expect(time.hour, 21);
      expect(time.minute, 0);
    });

    test('setReminderTime persists custom time accurately', () async {
      const customTime = TimeOfDay(hour: 20, minute: 45);
      await service.setReminderTime(customTime);

      final saved = await service.getReminderTime();
      expect(saved.hour, 20);
      expect(saved.minute, 45);
    });
  });
}
