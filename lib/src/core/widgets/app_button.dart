import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

/// زر مالي تفاعلي مع تأثير حركي عند الضغط واهتزاز لمسي (Haptic Feedback)
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonVariant variant;
  final double? width;
  final double height;
  final double borderRadius;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.width,
    this.height = 54,
    this.borderRadius = 16,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color backgroundColor;
    Color textColor;
    Border? border;
    Gradient? gradient;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
        gradient = isEnabled ? AppColors.primaryGradient : null;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurfaceAlt
            : AppColors.surfaceAlt;
        textColor = Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkTextPrimary
            : AppColors.textPrimary;
        break;
      case AppButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = AppColors.primary;
        border = Border.all(color: AppColors.primary, width: 1.5);
        break;
      case AppButtonVariant.danger:
        backgroundColor = AppColors.expense;
        textColor = Colors.white;
        gradient = isEnabled ? AppColors.expenseGradient : null;
        break;
    }

    if (!isEnabled) {
      backgroundColor = backgroundColor.withAlpha(128);
      textColor = textColor.withAlpha(153);
      gradient = null;
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: backgroundColor,
              gradient: gradient,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: border,
              boxShadow: isEnabled && widget.variant == AppButtonVariant.primary
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(51),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: textColor, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
