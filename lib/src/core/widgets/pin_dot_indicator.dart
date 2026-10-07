import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// مؤشر نقاط الرمز السري التفاعلي مع تأثيرات التحريك
class PinDotIndicator extends StatelessWidget {
  final int length;
  final int currentLength;
  final bool hasError;

  const PinDotIndicator({
    super.key,
    this.length = 4,
    required this.currentLength,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isFilled = index < currentLength;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: isFilled ? 18 : 14,
          height: isFilled ? 18 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasError
                ? AppColors.expense
                : (isFilled
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.darkSurfaceAlt
                        : AppColors.surfaceAlt)),
            border: Border.all(
              color: hasError
                  ? AppColors.expense
                  : (isFilled
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkBorder
                          : AppColors.border)),
              width: 1.5,
            ),
            boxShadow: isFilled && !hasError
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
