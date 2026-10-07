import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bashnddof/src/core/database/app_database.dart';
import 'package:bashnddof/src/core/services/backup_service.dart';
import 'package:bashnddof/src/core/services/notification_service.dart';
import 'package:bashnddof/src/core/services/secure_storage_service.dart';
import 'package:bashnddof/src/core/services/wasaat_integration_service.dart';
import 'package:bashnddof/src/core/theme/app_colors.dart';
import 'package:bashnddof/src/core/theme/theme_service.dart';
import 'package:bashnddof/src/core/widgets/app_button.dart';
import 'package:bashnddof/src/core/widgets/app_text_field.dart';
import 'package:bashnddof/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:bashnddof/src/features/recurring/presentation/screens/recurring_transactions_screen.dart';
import 'package:bashnddof/src/features/savings/presentation/screens/savings_goals_screen.dart';
import 'package:bashnddof/src/core/currency/currency_service.dart';
import 'package:bashnddof/src/core/localization/app_localizations.dart';
import 'package:bashnddof/src/core/localization/language_service.dart';

/// شاشة الإعدادات والأمان وإدارة البيانات لتطبيق BASHNDDOF
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SecureStorageService _storage = SecureStorageService();
  final BackupService _backupService = BackupService();
  final NotificationService _notificationService = NotificationService();

  bool _biometricsEnabled = true;
  bool _notificationsEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final bio = await _storage.isBiometricsEnabled();
    final notif = await _notificationService.isNotificationsEnabled();
    final time = await _notificationService.getReminderTime();
    if (mounted) {
      setState(() {
        _biometricsEnabled = bio;
        _notificationsEnabled = notif;
        _reminderTime = time;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    await _storage.setBiometricsEnabled(value);
    setState(() {
      _biometricsEnabled = value;
    });
    if (!mounted) return;
    final isArabic = context.isArabic;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? (isArabic ? '✅ تم تفعيل المصادقة البيومترية' : '✅ Biometrics enabled')
              : (isArabic ? 'تم تعطيل المصادقة البيومترية' : 'Biometrics disabled'),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    final isArabic = context.isArabic;
    if (value) {
      final granted = await _notificationService.requestPermissions();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? '⚠️ تنبيه: يرجى منح الإذن للإشعارات في إعدادات الهاتف'
                  : '⚠️ Please grant notification permission in device settings',
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }

    await _notificationService.setNotificationsEnabled(value);
    if (value) {
      await _notificationService.scheduleDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
    }

    setState(() {
      _notificationsEnabled = value;
    });

    HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? (isArabic ? '✅ تم تفعيل الإشعارات والتذكيرات المحلية' : '✅ Local reminders enabled')
              : (isArabic ? 'تم إيقاف الإشعارات المحلية' : 'Local reminders disabled'),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selectReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null) {
      await _notificationService.setReminderTime(picked);
      setState(() {
        _reminderTime = picked;
      });
      HapticFeedback.lightImpact();
      if (!mounted) return;
      final isArabic = context.isArabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? '✅ تم ضبط موعد التذكير اليومي: ${picked.format(context)}'
                : '✅ Daily reminder set to: ${picked.format(context)}',
          ),
          backgroundColor: AppColors.income,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // --- تغيير الرمز السري ---

  Future<void> _showChangePinDialog() async {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? errorMessage;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final isArabic = context.isArabic;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        isArabic ? 'تغيير الرمز السري' : 'Change Security PIN',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: AppColors.expense, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  AppTextField(
                    label: isArabic ? 'الرمز السري الحالي' : 'Current PIN',
                    controller: currentPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: isArabic ? 'الرمز السري الجديد (4 أرقام)' : 'New PIN (4 digits)',
                    controller: newPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: isArabic ? 'تأكيد الرمز السري الجديد' : 'Confirm New PIN',
                    controller: confirmPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    text: isArabic ? 'حفظ الرمز السري الجديد' : 'Save New PIN',
                    onPressed: () async {
                      final current = currentPinController.text.trim();
                      final newPin = newPinController.text.trim();
                      final confirm = confirmPinController.text.trim();

                      if (current.length != 4 || newPin.length != 4 || confirm.length != 4) {
                        setSheetState(() {
                          errorMessage = isArabic
                              ? 'يجب أن يتكون كل رمز من 4 أرقام.'
                              : 'Each PIN must be 4 digits.';
                        });
                        return;
                      }

                      final hashedCurrent = sha256.convert(utf8.encode(current)).toString();
                      final savedPin = await _storage.getPin();

                      if (savedPin != hashedCurrent) {
                        setSheetState(() {
                          errorMessage = isArabic
                              ? 'الرمز السري الحالي غير صحيح.'
                              : 'Current PIN is incorrect.';
                        });
                        return;
                      }

                      if (newPin != confirm) {
                        setSheetState(() {
                          errorMessage = isArabic
                              ? 'الرمز الجديد وتأكيده غير متطابقين.'
                              : 'New PIN and confirmation do not match.';
                        });
                        return;
                      }

                      final hashedNew = sha256.convert(utf8.encode(newPin)).toString();
                      await _storage.savePin(hashedNew);

                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      HapticFeedback.mediumImpact();

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isArabic
                              ? '✅ تم تغيير الرمز السري بنجاح'
                              : '✅ PIN changed successfully'),
                          backgroundColor: AppColors.income,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- تصدير النسخة الاحتياطية المشفرة ---

  Future<void> _exportBackup() async {
    final passphraseController = TextEditingController();
    String? error;
    final isArabic = context.isArabic;
    final loc = context.loc;

    final pass = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.shield_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(isArabic ? 'تشفير النسخة الاحتياطية' : 'Encrypt Backup'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic
                      ? 'أدخل كلمة سر قوية لتشفير ملف النسخة الاحتياطية بتقنية AES-256. ستحتاج هذه الكلمة عند الاستعادة.'
                      : 'Enter a strong password to encrypt the backup with AES-256. You will need it to restore.',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: isArabic ? 'كلمة سر التشفير' : 'Encryption Password',
                  controller: passphraseController,
                  obscureText: true,
                  hintText: isArabic ? 'كلمة سر من 6 خانات على الأقل' : 'At least 6 characters',
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: AppColors.expense, fontSize: 12)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: Text(loc.translate('cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = passphraseController.text.trim();
                  if (text.length < 6) {
                    setDialogState(() {
                      error = isArabic
                          ? 'يجب ألا تقل كلمة السر عن 6 أحرف.'
                          : 'Password must be at least 6 characters.';
                    });
                    return;
                  }
                  Navigator.of(ctx).pop(text);
                },
                child: Text(isArabic ? 'تصدير الآن' : 'Export Now'),
              ),
            ],
          );
        },
      ),
    );

    if (pass == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final encryptedBackup = await _backupService.exportEncryptedBackup(pass);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.income),
              const SizedBox(width: 8),
              Text(isArabic ? 'تم تجهيز النسخة الاحتياطية' : 'Backup Ready'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isArabic
                    ? 'تم تشفير كامل بياناتك المالية بنجاح. يمكنك نسخ الشفرة وحفظها في مكان آمن لاستعادتها مستقبلاً:'
                    : 'All your financial data has been encrypted successfully. Copy and store this payload safely to restore later:',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  encryptedBackup.length > 120
                      ? '${encryptedBackup.substring(0, 120)}...'
                      : encryptedBackup,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                text: isArabic ? 'نسخ الشفرة المشفرة إلى الحافظة' : 'Copy Encrypted Payload',
                icon: Icons.copy_rounded,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: encryptedBackup));
                  HapticFeedback.lightImpact();
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic
                            ? '📋 تم نسخ النسخة الاحتياطية المشفرة إلى الحافظة!'
                            : '📋 Encrypted backup payload copied to clipboard!',
                      ),
                      backgroundColor: AppColors.income,
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.translate('close')),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'فشل التصدير: $e' : 'Export failed: $e'),
          backgroundColor: AppColors.expense,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- استعادة النسخة الاحتياطية المشفرة ---

  Future<void> _restoreBackup() async {
    final payloadController = TextEditingController();
    final passphraseController = TextEditingController();
    String? errorMessage;
    final isArabic = context.isArabic;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.restore_page_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        isArabic ? 'استعادة نسخة احتياطية مشفرة' : 'Restore Encrypted Backup',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic
                        ? 'الصق النص المشفر وأدخل كلمة السر التي تم التصدير بها. تنبيه: ستستبدل البيانات الحالية بالبيانات المستعادة.'
                        : 'Paste the encrypted payload and enter password. Note: Current data will be replaced.',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: AppColors.expense, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  AppTextField(
                    label: isArabic ? 'نص النسخة المشفر' : 'Encrypted Payload',
                    controller: payloadController,
                    maxLines: 3,
                    hintText: isArabic ? 'الصق النص المشفر هنا...' : 'Paste encrypted text here...',
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: isArabic ? 'كلمة سر فك التشفير' : 'Decryption Password',
                    controller: passphraseController,
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    text: isArabic ? 'بدء الاستعادة الآمنة' : 'Start Secure Restore',
                    onPressed: () async {
                      final payload = payloadController.text.trim();
                      final pass = passphraseController.text.trim();

                      if (payload.isEmpty || pass.isEmpty) {
                        setSheetState(() {
                          errorMessage = isArabic
                              ? 'يرجى ملء جميع الحقول المطلوبة.'
                              : 'Please fill all required fields.';
                        });
                        return;
                      }

                      setSheetState(() => errorMessage = null);
                      final result = await _backupService.restoreEncryptedBackup(
                        encryptedPayload: payload,
                        passphrase: pass,
                      );

                      if (!ctx.mounted) return;

                      if (result.isSuccess) {
                        Navigator.of(ctx).pop();
                        HapticFeedback.mediumImpact();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isArabic
                                  ? '✅ تمت الاستعادة بنجاح: ${result.transactionsCount} معاملة، ${result.categoriesCount} تصنيف.'
                                  : '✅ Restored successfully: ${result.transactionsCount} transactions, ${result.categoriesCount} categories.',
                            ),
                            backgroundColor: AppColors.income,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      } else {
                        setSheetState(() {
                          if (isArabic) {
                            errorMessage = result.message;
                          } else {
                            if (result.message.contains('كلمة السر غير صحيحة')) {
                              errorMessage = 'Incorrect password or corrupted backup payload.';
                            } else if (result.message.contains('الملف ليس نسخة احتياطية صالحة')) {
                              errorMessage = 'The payload is not a valid BASHNDDOF backup.';
                            } else if (result.message.contains('حدث خطأ أثناء قراءة البيانات')) {
                              errorMessage = result.message.replaceAll('حدث خطأ أثناء قراءة البيانات المستعادة:', 'Error restoring data:');
                            } else {
                              errorMessage = result.message;
                            }
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- تصفير التطبيق بالكامل ---

  Future<void> _handleFullReset(BuildContext context) async {
    final isArabic = context.isArabic;
    final loc = context.loc;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? '⚠️ هل أنت متأكد من إعادة الضبط؟' : '⚠️ Are you sure you want to reset?'),
        content: Text(
          isArabic
              ? 'سيؤدي هذا الإجراء إلى مسح الرمز السري، حذف جميع المعاملات، الأظرف، وأهداف الادخار نهائيًا. لا يمكن التراجع عن هذا الإجراء.'
              : 'This will erase the PIN, all transactions, envelopes, and savings goals permanently. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.translate('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isArabic ? 'نعم، احذف كل شيء' : 'Yes, Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await AppDatabase.instance.resetDatabase();
      await _storage.resetAll();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      HapticFeedback.heavyImpact();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? '✅ تمت إعادة ضبط التطبيق بنجاح' : '✅ App reset successfully'),
          backgroundColor: AppColors.income,
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/intro', (route) => false);
    }
  }

  void _showAboutDialog(BuildContext context) {
    final isArabic = context.isArabic;
    final loc = context.loc;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_transparent.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(isArabic ? 'عن تطبيق مصروفي' : 'About Masroufi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo_transparent.png',
                width: 72,
                height: 72,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isArabic
                  ? 'تطبيق مصروفي (الإصدار 1.0.0)\n\nمحفظتك المالية الشخصية الآمنة، مصممة لتعمل بدون إنترنت بنسبة 100% حفاظاً على سرية وخصوصية بياناتك المالية وفق معايير التشفير العسكري AES-256.\n\nصُنِع بحب وإتقان على يد المبرمج العم سالم ❤️'
                  : 'Masroufi App (Version 1.0.0)\n\nYour secure personal finance wallet, designed to work 100% offline to maintain privacy and security with military-grade AES-256 encryption.\n\nCrafted with passion by Developer Uncle Salem ❤️',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.translate('close')),
          ),
        ],
      ),
    );
  }

  Future<void> _showWasaatIntegrationInfo(BuildContext context) async {
    final isArabic = context.isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = context.loc;
    final service = WasaatIntegrationService();
    final token = await service.getSecurityToken();
    final count = (await service.getWasaatTransactions()).length;

    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hub_rounded, color: Color(0xFF10B981), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isArabic ? 'الربط التلقائي مع تطبيق وصاة' : 'Integration with Wasaat App',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                isArabic
                    ? 'هذا التطبيق مُهيأ عبر مزود محتوى آمن (ContentProvider) للتواصل المباشر مع تطبيق (وصاة) لإدارة ميزانية الأسرة. عند اعتماد أي مصروف في وصاة، سيتم خصمه فوراً وبصمت من الظرف المحدد في مصروفي.'
                    : 'This app is integrated via a secure ContentProvider with (Wasaat) Family Expense Management. Approved expenses in Wasaat are deducted silently and instantly from your envelopes.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isArabic ? 'رمز الأمان المشترك (Token):' : 'Shared Security Token:',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: token));
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isArabic ? 'تم نسخ رمز الأمان' : 'Security token copied'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                isArabic ? 'نسخ' : 'Copy',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      token,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.verified_outlined, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(
                    isArabic
                        ? 'المعاملات المعتمدة من وصاة: $count'
                        : 'Approved transactions from Wasaat: $count',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(loc.translate('close')),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.isArabic;
    final loc = context.loc;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settingsTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // قسم المظهر والسمة (Theme)
                _buildSectionHeader(loc.translate('appearanceSection')),
                _buildCardContainer(
                  isDark: isDark,
                  children: [
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: ThemeService.themeModeNotifier,
                      builder: (context, currentMode, _) {
                        return Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.palette_outlined, size: 20, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    isArabic ? 'نمط واجهة التطبيق' : 'Theme Mode',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildThemeOption(
                                    context: context,
                                    title: loc.translate('lightMode'),
                                    subtitle: isArabic ? 'فاتح' : 'Light',
                                    icon: Icons.wb_sunny_rounded,
                                    mode: ThemeMode.light,
                                    currentMode: currentMode,
                                    isDark: isDark,
                                    activeColor: const Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildThemeOption(
                                    context: context,
                                    title: loc.translate('darkMode'),
                                    subtitle: isArabic ? 'داكن' : 'Dark',
                                    icon: Icons.nightlight_round,
                                    mode: ThemeMode.dark,
                                    currentMode: currentMode,
                                    isDark: isDark,
                                    activeColor: const Color(0xFF818CF8),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildThemeOption(
                                    context: context,
                                    title: loc.translate('systemMode'),
                                    subtitle: loc.translate('systemSubtitle'),
                                    icon: Icons.brightness_auto_rounded,
                                    mode: ThemeMode.system,
                                    currentMode: currentMode,
                                    isDark: isDark,
                                    activeColor: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // قسم اللغة والعملة (Language & Currency)
                _buildSectionHeader(loc.translate('languageAndRegion')),
                _buildCardContainer(
                  isDark: isDark,
                  children: [
                    // خيار اختيار لغة التطبيق
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.language_rounded, size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                loc.translate('appLanguage'),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ValueListenableBuilder<Locale>(
                            valueListenable: LanguageService.localeNotifier,
                            builder: (context, currentLocale, _) {
                              final isAr = currentLocale.languageCode == 'ar';
                              return Row(
                                children: [
                                  _buildLanguageOption(
                                    title: 'العربية',
                                    subtitle: isArabic ? 'العربية' : 'Arabic',
                                    flag: '🇾🇪 / 🇸🇦',
                                    isSelected: isAr,
                                    isDark: isDark,
                                    onTap: () {
                                      LanguageService.setLocale(const Locale('ar'));
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  _buildLanguageOption(
                                    title: 'English',
                                    subtitle: isArabic ? 'الإنجليزية' : 'English',
                                    flag: '🇺🇸 / 🇬🇧',
                                    isSelected: !isAr,
                                    isDark: isDark,
                                    onTap: () {
                                      LanguageService.setLocale(const Locale('en'));
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // خيار اختيار عملة التطبيق
                    ValueListenableBuilder<CurrencyModel>(
                      valueListenable: CurrencyService.currencyNotifier,
                      builder: (context, currentCurrency, _) {
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              currentCurrency.flag,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          title: Text(
                            loc.translate('currency'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${currentCurrency.getName(isArabic)} • ${currentCurrency.code} (${currentCurrency.getSymbol(isArabic)})',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          trailing: Icon(context.forwardChevron, size: 16),
                          onTap: () => _showCurrencyPickerDialog(context),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // قسم الميزات المالية
                _buildSectionHeader(loc.translate('financialFeatures')),
                _buildCardContainer(
                  isDark: isDark,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.repeat_rounded, color: Color(0xFFF59E0B)),
                      title: Text(loc.translate('recurringTitle'), style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(isArabic ? 'جدولة المدفوعات والاشتراكات الشهرية' : 'Schedule payments & monthly subscriptions'),
                      trailing: Icon(context.forwardChevron, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RecurringTransactionsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.savings_rounded, color: Color(0xFF8B5CF6)),
                      title: Text(loc.translate('savingsGoalsTitle'), style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(isArabic ? 'متابعة خطط التوفير والمبالغ المتبقية' : 'Track savings plans & remaining amounts'),
                      trailing: Icon(context.forwardChevron, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SavingsGoalsScreen(showAppBar: true),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // قسم الأمان والمصادقة
                _buildSectionHeader(loc.translate('securitySection')),
                _buildCardContainer(
                  isDark: isDark,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                      title: Text(loc.translate('changePin'), style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(loc.translate('changePinSub')),
                      trailing: Icon(context.forwardChevron, size: 16),
                      onTap: _showChangePinDialog,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                      title: Text(loc.translate('biometrics'), style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(loc.translate('biometricsSub')),
                      value: _biometricsEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: _toggleBiometrics,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.verified_user_rounded, color: AppColors.income),
                      title: Text(isArabic ? 'حالة التخزين والخصوصية' : 'Storage & Privacy Status', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(isArabic ? 'محلي بالكامل (Offline) • مشفر ولا يُرفع لأي خوادم' : '100% Offline • Encrypted with AES-256'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // قسم التنبيهات والإشعارات المحلية
                _buildSectionHeader(loc.translate('notificationsSection')),
                _buildCardContainer(
                  isDark: isDark,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
                      title: Text(isArabic ? 'سجل الإشعارات والتنبيهات المحفوظة' : 'Notifications History', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(isArabic ? 'عرض جميع التنبيهات المحفوظة وإدارتها ومسحها' : 'View, manage and clear saved notifications'),
                      trailing: Icon(context.forwardChevron, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.schedule_rounded, color: Color(0xFFF59E0B)),
                      title: Text(loc.translate('dailyNotifications'), style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(loc.translate('dailyNotificationsSub')),
                      value: _notificationsEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: _toggleNotifications,
                    ),
                    if (_notificationsEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.access_time_rounded, color: Color(0xFFF59E0B)),
                        title: Text(loc.translate('reminderTime'), style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${isArabic ? "سيصلك التنبيه الساعة: " : "Daily at: "}${_reminderTime.format(context)}'),
                        trailing: const Icon(Icons.edit_outlined, size: 18),
                        onTap: _selectReminderTime,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // قسم النسخ الاحتياطي المشفر
                _buildSectionHeader(loc.translate('backupSection')),
                _buildCardContainer(
                  isDark: isDark,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
                      title: Text(loc.translate('exportBackup'), style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(loc.translate('exportBackupSub')),
                      trailing: Icon(context.forwardChevron, size: 16),
                      onTap: _exportBackup,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.cloud_download_outlined, color: Color(0xFF0284C7)),
                      title: Text(loc.translate('restoreBackup'), style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(loc.translate('restoreBackupSub')),
                      trailing: Icon(context.forwardChevron, size: 16),
                      onTap: _restoreBackup,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // قسم التكامل والربط مع وصاة
                _buildSectionHeader(isArabic ? 'الربط مع تطبيق وصاة' : 'Wasaat Integration'),
                _buildCardContainer(
                  isDark: isDark,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.hub_rounded, color: Color(0xFF10B981)),
                      title: Text(
                        isArabic ? 'تكامل إدارة مصروفات الأسرة' : 'Family Expense Integration',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        isArabic
                            ? 'جاهز لاستقبال وخصم المصروفات المعتمدة تلقائياً وبصمت'
                            : 'Ready to receive & deduct approved expenses automatically',
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isArabic ? 'نشط ●' : 'Active ●',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                      onTap: () => _showWasaatIntegrationInfo(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // قسم المعلومات والدعم
                _buildSectionHeader(loc.translate('aboutApp')),
                _buildCardContainer(
                  isDark: isDark,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded, color: AppColors.info),
                      title: Text(loc.translate('aboutApp'), style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(loc.translate('aboutAppSub')),
                      trailing: Icon(context.forwardChevron, size: 16),
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // منطقة الخطر (Danger Zone)
                _buildSectionHeader(loc.translate('dataManagement'), isDanger: true),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.expense.withAlpha(77)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: AppColors.expense),
                    title: Text(
                      loc.translate('resetAllData'),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.expense),
                    ),
                    subtitle: Text(loc.translate('resetAllDataSub')),
                    trailing: Icon(context.forwardChevron, size: 16, color: AppColors.expense),
                    onTap: () => _handleFullReset(context),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildCardContainer({required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSectionHeader(String title, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDanger ? AppColors.expense : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required String flag,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeColor = AppColors.primary;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withAlpha(isDark ? 45 : 30)
                : (isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark ? AppColors.darkBorder : AppColors.border),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? activeColor
                      : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              if (isSelected)
                Icon(Icons.check_circle_rounded, size: 16, color: activeColor)
              else
                const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencyPickerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CurrencyPickerModal(),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required bool isDark,
    required Color activeColor,
  }) {
    final isSelected = currentMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          ThemeService.setThemeMode(mode);
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withAlpha(isDark ? 45 : 30)
                : (isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark ? AppColors.darkBorder : AppColors.border),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                size: 26,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? activeColor
                      : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: activeColor,
                )
              else
                const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// نافذة سفلية منبثقة للبحث واختيار العملة بين كافة العملات العربية الـ 21 بالإضافة إلى الدولار واليورو
class _CurrencyPickerModal extends StatefulWidget {
  const _CurrencyPickerModal();

  @override
  State<_CurrencyPickerModal> createState() => _CurrencyPickerModalState();
}

class _CurrencyPickerModalState extends State<_CurrencyPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  List<CurrencyModel> _filteredCurrencies = CurrencyService.allCurrencies;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = CurrencyService.allCurrencies;
      } else {
        _filteredCurrencies = CurrencyService.allCurrencies.where((c) {
          return c.code.toLowerCase().contains(query) ||
              c.nameAr.toLowerCase().contains(query) ||
              c.nameEn.toLowerCase().contains(query) ||
              c.symbolAr.toLowerCase().contains(query) ||
              c.symbolEn.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.isArabic;
    final loc = context.loc;
    final currentCurrency = CurrencyService.currentCurrency;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // مقبض السحب
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(90),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.currency_exchange_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      loc.translate('selectCurrency'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: AppTextField(
              controller: _searchController,
              hintText: loc.translate('searchCurrency'),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredCurrencies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = _filteredCurrencies[index];
                final isSelected = item.code == currentCurrency.code;

                return InkWell(
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    await CurrencyService.setCurrency(item);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isArabic
                                ? '✅ تم تغيير العملة إلى: ${item.flag} ${item.nameAr} (${item.symbolAr})'
                                : '✅ Currency changed to: ${item.flag} ${item.nameEn} (${item.symbolEn})',
                          ),
                          backgroundColor: AppColors.income,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withAlpha(isDark ? 40 : 25)
                          : (isDark ? AppColors.darkSurface : AppColors.surface),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.darkBorder : AppColors.border),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(item.flag, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.getName(isArabic),
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isArabic ? item.nameEn : item.nameAr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.code,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.getSymbol(isArabic),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
