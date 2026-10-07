import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:bashnddof/src/core/services/secure_storage_service.dart';
import 'package:bashnddof/src/core/theme/app_colors.dart';
import 'package:bashnddof/src/core/widgets/numeric_keypad.dart';
import 'package:bashnddof/src/core/widgets/pin_dot_indicator.dart';
import 'package:bashnddof/src/core/localization/app_localizations.dart';

/// شاشة تسجيل الدخول والمصادقة الأمنية المصرفية الفاخرة (Fintech Secure Lock Screen)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
  with SingleTickerProviderStateMixin {
  static const int _pinLength = 4;
  String _enteredPin = '';
  bool _hasError = false;
  bool _canCheckBiometrics = false;
  bool _isLockedOut = false;
  int _lockoutRemainingSeconds = 0;
  Timer? _lockoutTimer;

  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorageService _storage = SecureStorageService();

  @override
  void initState() {
    super.initState();

    // حركة نبض هادئة وراقية خلف أيقونة التطبيق
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _checkLockoutStatus();
    _checkBiometricsSupport();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLockoutStatus() async {
    final locked = await _storage.isLockedOut();
    if (locked) {
      final remaining = await _storage.getLockoutRemainingSeconds();
      if (remaining > 0) {
        _startLockoutCountdown(remaining);
      }
    }
  }

  void _startLockoutCountdown(int seconds) {
    _lockoutTimer?.cancel();
    setState(() {
      _isLockedOut = true;
      _lockoutRemainingSeconds = seconds;
      _enteredPin = '';
      _hasError = false;
    });

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_lockoutRemainingSeconds > 1) {
          _lockoutRemainingSeconds--;
        } else {
          _lockoutRemainingSeconds = 0;
          _isLockedOut = false;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _checkBiometricsSupport() async {
    try {
      final biometricsEnabled = await _storage.isBiometricsEnabled();
      if (!biometricsEnabled) return;

      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final available = await _localAuth.getAvailableBiometrics();

      final supported = (canCheck || isSupported) && (available.isNotEmpty || isSupported);

      if (mounted) {
        setState(() {
          _canCheckBiometrics = supported;
        });

        if (_canCheckBiometrics && !_isLockedOut) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 350), () {
              if (mounted && !_isLockedOut) {
                _authenticateWithBiometrics();
              }
            });
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isLockedOut) return;
    try {
      final isArabic = mounted ? context.isArabic : true;
      final authenticated = await _localAuth.authenticate(
        localizedReason: isArabic
            ? 'تأكيد الهوية لفتح المحفظة'
            : 'Confirm identity to unlock wallet',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (authenticated && mounted) {
        await _storage.resetFailedAttempts();
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (_) {}
  }

  void _onDigitPressed(String digit) {
    if (_isLockedOut || _enteredPin.length >= _pinLength) return;

    setState(() {
      _hasError = false;
      _enteredPin += digit;
    });

    if (_enteredPin.length == _pinLength) {
      _verifyPin();
    }
  }

  void _onDeletePressed() {
    if (_isLockedOut || _enteredPin.isEmpty) return;
    setState(() {
      _hasError = false;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _verifyPin() async {
    final storedPin = await _storage.getPin();
    final hashed = sha256.convert(utf8.encode(_enteredPin)).toString();

    if (storedPin == null || storedPin == hashed) {
      HapticFeedback.mediumImpact();
      await _storage.resetFailedAttempts();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      HapticFeedback.heavyImpact();
      await _storage.incrementFailedAttempts();
      final failedAttempts = await _storage.getFailedAttempts();

      if (!mounted) return;

      if (failedAttempts >= 5) {
        await _storage.setLockoutDuration(const Duration(seconds: 30));
        if (!mounted) return;
        _startLockoutCountdown(30);
        final isArabic = context.isArabic;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic
                ? 'تم قفل التطبيق مؤقتاً لتكرار المحاولات الخاطئة'
                : 'App locked temporarily due to repeated failed attempts'),
            backgroundColor: AppColors.expense,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        setState(() {
          _hasError = true;
        });

        final remainingTries = 5 - failedAttempts;
        final isArabic = context.isArabic;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic
                ? 'الرمز السري غير صحيح. تبقى لك $remainingTries محاولات.'
                : 'Incorrect PIN. $remainingTries attempts remaining.'),
            backgroundColor: AppColors.expense,
            duration: const Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        setState(() {
          _enteredPin = '';
          _hasError = false;
        });
      }
    }
  }

  Future<void> _resetApp() async {
    final isArabic = context.isArabic;
    final loc = context.loc;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'تأكيد إعادة التعيين' : 'Confirm Reset'),
        content: Text(
          isArabic
              ? 'سيؤدي هذا إلى مسح الرمز السري وجميع بيانات المحفظة نهائيًا ولا يمكن التراجع عن ذلك.'
              : 'This will erase your PIN and all wallet data permanently and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.translate('cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isArabic ? 'حذف كل شيء' : 'Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.resetAll();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/intro', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.isArabic;
    final loc = context.loc;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // شريط علوي أنيق برمز الأمان وزر إعادة التعيين
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.restart_alt_rounded,
                                size: 22,
                                color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                              ),
                              tooltip: isArabic ? 'إعادة تعيين المحفظة' : 'Reset Wallet',
                              onPressed: _resetApp,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primary.withAlpha(45),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isArabic ? 'مصروفي • أمان محلي' : 'MASROUFI • SECURE',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // الحاوية المركزية للشعار الفاخر مع توهج هادئ
                      AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _glowAnimation.value,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? AppColors.darkSurface : Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(
                                      (40 + 35 * _glowController.value).toInt(),
                                    ),
                                    blurRadius: 20 + 8 * _glowController.value,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : Colors.black.withAlpha(12),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/logo_transparent.png',
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // عنوان الترحيب
                      Text(
                        loc.translate('welcomeBack'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        _isLockedOut
                            ? (isArabic
                                ? 'التطبيق مقفل مؤقتًا لأسباب أمنية'
                                : 'App temporarily locked for security')
                            : (_canCheckBiometrics
                                ? (isArabic
                                    ? 'أدخل الرمز السري أو استخدم البصمة لفتح المحفظة'
                                    : 'Enter PIN or tap biometric key to unlock')
                                : (isArabic
                                    ? 'أدخل الرمز السري للمتابعة'
                                    : 'Enter PIN to continue')),
                        style: TextStyle(
                          fontSize: 13,
                          color: _isLockedOut
                              ? AppColors.expense
                              : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          fontWeight: _isLockedOut ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // بطاقة القفل الأمني عند نفاد المحاولات
                      if (_isLockedOut)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.expense.withAlpha(20),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.expense.withAlpha(70)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.timer_outlined, color: AppColors.expense, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                isArabic
                                    ? 'يرجى الانتظار: $_lockoutRemainingSeconds ثانية قبل المحاولة'
                                    : 'Please wait: $_lockoutRemainingSeconds s before retrying',
                                style: const TextStyle(
                                  color: AppColors.expense,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // مؤشر النقاط التفاعلي
                      PinDotIndicator(
                        length: _pinLength,
                        currentLength: _enteredPin.length,
                        hasError: _hasError,
                      ),
                      const SizedBox(height: 24),

                      // لوحة المفاتيح الرقمية المتكاملة
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _isLockedOut ? 0.35 : 1.0,
                        child: IgnorePointer(
                          ignoring: _isLockedOut,
                          child: NumericKeypad(
                            onDigitPressed: _onDigitPressed,
                            onDeletePressed: _onDeletePressed,
                            showBiometric: _canCheckBiometrics,
                            onBiometricPressed: _authenticateWithBiometrics,
                          ),
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
