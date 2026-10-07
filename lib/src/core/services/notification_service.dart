import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/in_app_notification_model.dart';
import '../repositories/in_app_notification_repository.dart';
import '../repositories/recurring_transaction_repository.dart';
import '../currency/currency_service.dart';
import '../localization/language_service.dart';

/// خدمة الإشعارات والتنبيهات المحلية غير المتصلة بالإنترنت (Local Offline Notification Service)
/// تعمل بنسبة 100% بدون أي خوادم أو إنترنت، مع الحفاظ التام على خصوصية المستخدم
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final InAppNotificationRepository _notificationRepo =
      InAppNotificationRepository();

  bool _isInitialized = false;

  static const String _channelId = 'masroufi_reminders_channel';
  static const String _channelName = 'تنبيهات وتذكيرات مصروفي';
  static const String _channelDesc =
      'قناة الإشعارات والتذكيرات المالية وتنبيهات الميزانية لتطبيق مصروفي';

  static const String _prefKeyEnabled = 'pref_notifications_enabled';
  static const String _prefKeyHour = 'pref_notification_hour';
  static const String _prefKeyMinute = 'pref_notification_minute';

  /// تهيئة إعدادات الإشعارات وقنوات النظام
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (_) {}

    try {
      const androidSettings =
          AndroidInitializationSettings('@drawable/ic_notification');

      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final initSettings = const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // تفاعل عند النقر على الإشعار
        },
      );

      // إنشاء قناة الأندرويد لضمان ظهور الإشعار بأولوية عالية وصوت واهتزاز
      final androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService initialize fallback: $e');
    }
  }

  /// طلب صلاحية الإشعارات من النظام (مطلوب لأندرويد 13+)
  Future<bool> requestPermissions() async {
    try {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (_) {}

    return true;
  }

  /// إرسال إشعار فوري في ستارة الهاتف وحفظه في سجل الإشعارات
  Future<void> showInstantNotification({
    int id = 0,
    required String title,
    required String body,
    String type = 'system',
  }) async {
    try {
      // حفظ في سجل الإشعارات الداخلي
      await _notificationRepo.insert(
        InAppNotificationModel(
          title: title,
          body: body,
          type: type,
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {}

    try {
      await initialize();

      final isEnabled = await isNotificationsEnabled();
      if (!isEnabled) return;

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@drawable/ic_notification',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('showInstantNotification fallback: $e');
    }
  }

  /// جدولة التذكير اليومي في ساعة محددة
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    try {
      await initialize();

      final isEnabled = await isNotificationsEnabled();
      if (!isEnabled) return;

      // إلغاء أي تذكير يومي سابق برقم 100
      await cancel(100);

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@drawable/ic_notification',
      );

      const details = NotificationDetails(android: androidDetails);

      final isAr = LanguageService.isArabic;
      await _notificationsPlugin.zonedSchedule(
        id: 100,
        title: isAr
            ? 'تذكير المصروفات اليومي | مصروفي'
            : 'Daily Expense Reminder | Masroufi',
        body: isAr
            ? 'لا تنسَ تسجيل مصروفات وإيرادات اليوم للحفاظ على دقة ميزانيتك.'
            : "Don't forget to log today's expenses and income to keep your budget accurate.",
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('scheduleDailyReminder fallback: $e');
    }
  }

  /// إرسال تنبيه تجاوز أو اقتراب ميزانية ظرف
  Future<void> notifyBudgetStatus({
    required String envelopeName,
    required double percent,
  }) async {
    final isAr = LanguageService.isArabic;
    if (percent >= 1.0) {
      await showInstantNotification(
        id: envelopeName.hashCode,
        title: isAr ? 'تجاوزت ميزانية الظرف' : 'Envelope Budget Exceeded',
        body: isAr
            ? 'لقد استهلكت كامل الميزانية المحددة لظرف "$envelopeName".'
            : 'You have consumed the entire budget for envelope "$envelopeName".',
        type: 'budget',
      );
    } else if (percent >= 0.85) {
      await showInstantNotification(
        id: envelopeName.hashCode,
        title: isAr ? 'تنبيه اقتراب ميزانية' : 'Budget Alert',
        body: isAr
            ? 'استهلكت ${(percent * 100).toStringAsFixed(0)}% من ميزانية ظرف "$envelopeName".'
            : 'You have used ${(percent * 100).toStringAsFixed(0)}% of the budget for "$envelopeName".',
        type: 'budget',
      );
    }
  }

  /// فحص المعاملات والالتزامات الدورية المستحقة وإرسال إشعار فوري بها
  Future<void> checkDueRecurringTransactions() async {
    try {
      final isEnabled = await isNotificationsEnabled();
      if (!isEnabled) return;

      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final lastChecked = prefs.getString('pref_last_recurring_notif_date');
      if (lastChecked == todayStr) return;

      final recurringRepo = RecurringTransactionRepository();
      final dueItems = await recurringRepo.getDueTransactions();
      if (dueItems.isEmpty) return;

      final isAr = LanguageService.isArabic;
      for (final item in dueItems) {
        final notifId = (item.id ?? 1) + 5000;
        await showInstantNotification(
          id: notifId,
          title: isAr ? 'موعد استحقاق معاملة دورية' : 'Recurring Transaction Due',
          body: isAr
              ? 'حان موعد دفع/تسجيل "${item.title}" بمبلغ ${CurrencyService.format(item.amount, isArabic: true)}.'
              : 'Time to record/pay "${item.title}" of ${CurrencyService.format(item.amount, isArabic: false)}.',
          type: 'recurring',
        );
      }

      await prefs.setString('pref_last_recurring_notif_date', todayStr);
    } catch (_) {}
  }

  /// إلغاء إشعار محدد
  Future<void> cancel(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (_) {}
  }

  /// إلغاء كافة الإشعارات المجدولة
  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (_) {}
  }

  // --- إدارة تفضيلات الإشعارات (SharedPreferences) ---

  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEnabled, value);
    if (!value) {
      await cancelAll();
    }
  }

  Future<TimeOfDay> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getInt(_prefKeyHour) ?? 21; // 9:00 PM افتراضياً
    final m = prefs.getInt(_prefKeyMinute) ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyHour, time.hour);
    await prefs.setInt(_prefKeyMinute, time.minute);
    await scheduleDailyReminder(hour: time.hour, minute: time.minute);
  }
}
