import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// لوحة أرقام تفاعلية مخصصة للمصادقة بالرمز السري وإدخال المبالغ
class NumericKeypad extends StatelessWidget {
  final void Function(String digit) onDigitPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onBiometricPressed;
  final bool showBiometric;

  const NumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onDeletePressed,
    this.onBiometricPressed,
    this.showBiometric = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(context, ['1', '2', '3']),
        const SizedBox(height: 16),
        _buildRow(context, ['4', '5', '6']),
        const SizedBox(height: 16),
        _buildRow(context, ['7', '8', '9']),
        const SizedBox(height: 16),
        _buildBottomRow(context),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) => _buildKey(context, digit)).toList(),
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // الخانة السفلية اليمنى: البصمة أو فارغ
        SizedBox(
          width: 72,
          height: 72,
          child: showBiometric && onBiometricPressed != null
              ? IconButton(
                  icon: const Icon(Icons.fingerprint_rounded, size: 36),
                  color: AppColors.primary,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onBiometricPressed!();
                  },
                )
              : null,
        ),

        // الصفر '0'
        _buildKey(context, '0'),

        // الخانة السفلية اليسرى: زر الحذف/المسح
        SizedBox(
          width: 72,
          height: 72,
          child: IconButton(
            icon: const Icon(Icons.backspace_outlined, size: 28),
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
            onPressed: () {
              HapticFeedback.lightImpact();
              onDeletePressed();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKey(BuildContext context, String digit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onDigitPressed(digit);
        },
        borderRadius: BorderRadius.circular(36),
        child: Ink(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: surfaceColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
