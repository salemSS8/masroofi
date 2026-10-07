import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bashnddof/src/core/services/secure_storage_service.dart';
import 'package:bashnddof/src/core/theme/app_colors.dart';
import 'package:bashnddof/src/core/widgets/numeric_keypad.dart';
import 'package:bashnddof/src/core/widgets/pin_dot_indicator.dart';
import 'package:bashnddof/src/core/localization/app_localizations.dart';

/// شاشة إعداد الرمز السري لأول مرة بتجربة مستخدم مصرفية فاخرة وتفاعلية
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  static const int _pinLength = 4;
  String _enteredPin = '';
  String _firstPin = '';
  bool _isConfirming = false;
  bool _hasError = false;

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= _pinLength) return;

    setState(() {
      _hasError = false;
      _enteredPin += digit;
    });

    if (_enteredPin.length == _pinLength) {
      _handlePinComplete();
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _hasError = false;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _handlePinComplete() async {
    if (!_isConfirming) {
      // حفظ الرمز الأول والانتقال لتأكيده
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _firstPin = _enteredPin;
        _enteredPin = '';
        _isConfirming = true;
      });
    } else {
      // التحقق من تطابق الرمزين
      if (_enteredPin == _firstPin) {
        HapticFeedback.mediumImpact();
        // تشفير الرمز وحفظه في التخزين الآمن
        final hashed = sha256.convert(utf8.encode(_enteredPin)).toString();
        final storage = SecureStorageService();
        await storage.savePin(hashed);

        if (!mounted) return;
        final isArabic = context.isArabic;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic
                ? 'تم إنشاء رمز الأمان بنجاح'
                : 'PIN created successfully'),
            backgroundColor: AppColors.income,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/budget_setup');
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _hasError = true;
        });
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        setState(() {
          _enteredPin = '';
          _firstPin = '';
          _isConfirming = false;
          _hasError = false;
        });
      }
    }
  }

  void _restartSetup() {
    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin = '';
      _firstPin = '';
      _isConfirming = false;
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = context.loc;
    final isArabic = context.isArabic;

    final Color statusColor = _hasError
        ? AppColors.expense
        : (_isConfirming ? const Color(0xFF10B981) : AppColors.primary);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          loc.translate('pinSetup'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        leading: _isConfirming
            ? IconButton(
                icon: Icon(context.backArrow),
                tooltip: isArabic ? 'العودة للخطوة الأولى' : 'Back to Step 1',
                onPressed: _restartSetup,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // شريط التقدم بين الخطوتين
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: LinearProgressIndicator(
                value: _isConfirming ? 1.0 : 0.5,
                minHeight: 3,
                backgroundColor: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const SizedBox(height: 16),

                            // شارة الخطوات المزدوجة
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStepPill(
                                  step: '1',
                                  label: isArabic ? 'إنشاء الرمز' : 'Create PIN',
                                  isActive: !_isConfirming,
                                  isDone: _isConfirming,
                                  isDark: isDark,
                                ),
                                Container(
                                  width: 24,
                                  height: 2,
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  color: _isConfirming
                                      ? const Color(0xFF10B981)
                                      : (isDark ? AppColors.darkBorder : AppColors.border),
                                ),
                                _buildStepPill(
                                  step: '2',
                                  label: isArabic ? 'تأكيد الرمز' : 'Confirm PIN',
                                  isActive: _isConfirming,
                                  isDone: false,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // أيقونة الأمان المركزية مع توهج
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor.withAlpha(20),
                                border: Border.all(
                                  color: statusColor.withAlpha(60),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withAlpha(35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  _hasError
                                      ? Icons.lock_open_rounded
                                      : (_isConfirming
                                          ? Icons.lock_reset_rounded
                                          : Icons.lock_outline_rounded),
                                  size: 38,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // العنوان التوجيهي
                            Text(
                              _hasError
                                  ? loc.translate('pinMismatch')
                                  : (_isConfirming
                                      ? loc.translate('confirmPin')
                                      : loc.translate('choosePin')),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: _hasError
                                    ? AppColors.expense
                                    : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // الوصف المساعد
                            Text(
                              _hasError
                                  ? (isArabic
                                      ? 'الرمزان غير متطابقين، يرجى إعادة المحاولة'
                                      : 'PINs do not match, please try again')
                                  : (_isConfirming
                                      ? (isArabic
                                          ? 'أعد إدخال نفس الرمز السري للتأكيد'
                                          : 'Re-enter the same PIN to confirm')
                                      : (isArabic
                                          ? 'اختر 4 أرقام يسهل تذكرها لتأمين محفظتك'
                                          : 'Choose 4 easy-to-remember digits')),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: _hasError
                                    ? AppColors.expense
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // مؤشر النقاط التفاعلي
                            PinDotIndicator(
                              length: _pinLength,
                              currentLength: _enteredPin.length,
                              hasError: _hasError,
                            ),
                            const SizedBox(height: 20),

                            // لوحة الأرقام الرقمية
                            NumericKeypad(
                              onDigitPressed: _onDigitPressed,
                              onDeletePressed: _onDeletePressed,
                            ),

                            const Spacer(),
                            const SizedBox(height: 16),

                            // شارة التشفير المحلي السفلية
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  size: 14,
                                  color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isArabic
                                      ? 'تشفير محلي عسكري AES-256'
                                      : 'Local AES-256 Military Encryption',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepPill({
    required String step,
    required String label,
    required bool isActive,
    required bool isDone,
    required bool isDark,
  }) {
    final color = isDone
        ? const Color(0xFF10B981)
        : (isActive ? AppColors.primary : (isDark ? AppColors.darkTextHint : AppColors.textHint));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isActive || isDone)
            ? color.withAlpha(20)
            : (isDark ? AppColors.darkSurface : AppColors.surface),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isActive || isDone)
              ? color.withAlpha(60)
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : Text(
                      step,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: (isActive || isDone) ? FontWeight.w700 : FontWeight.normal,
              color: (isActive || isDone)
                  ? (isDark ? Colors.white : AppColors.textPrimary)
                  : (isDark ? AppColors.darkTextHint : AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}
