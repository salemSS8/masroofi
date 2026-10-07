import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// ويدجت رسم فني تفاعلي للظرف المالي (Envelope Illustration)
/// يتميز بتصميم فني يدوي الصنع بالكامل (CustomPainter) مع حركة تنفس انسيابية ناعمة
class ArtisticEnvelopeIllustration extends StatefulWidget {
  final double size;
  const ArtisticEnvelopeIllustration({super.key, this.size = 140});

  @override
  State<ArtisticEnvelopeIllustration> createState() => _ArtisticEnvelopeIllustrationState();
}

class _ArtisticEnvelopeIllustrationState extends State<ArtisticEnvelopeIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final floatOffset = math.sin(_controller.value * math.pi) * 6;
        final glowAlpha = (0.25 + 0.15 * math.sin(_controller.value * math.pi));

        return Transform.translate(
          offset: Offset(0, -floatOffset),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _EnvelopePainter(
                isDark: isDark,
                glowAlpha: glowAlpha,
                sparklePhase: _controller.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EnvelopePainter extends CustomPainter {
  final bool isDark;
  final double glowAlpha;
  final double sparklePhase;

  _EnvelopePainter({
    required this.isDark,
    required this.glowAlpha,
    required this.sparklePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2 + 6);

    // 1. هالة ضوئية خلفية ناعمة (Ambient Glow)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withAlpha((glowAlpha * 255).toInt()),
          AppColors.primaryLight.withAlpha((glowAlpha * 100).toInt()),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.45));
    canvas.drawCircle(center, w * 0.45, glowPaint);

    // 2. أوراق النقد الخارجة من الظرف (Banknotes)
    final billWidth = w * 0.55;
    final billHeight = h * 0.32;
    final billRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - h * 0.18),
      width: billWidth,
      height: billHeight,
    );

    // ورقة نقدية خلفية مائلة قليلاً
    canvas.save();
    canvas.translate(center.dx, center.dy - h * 0.18);
    canvas.rotate(-0.08);
    final backBillPaint = Paint()
      ..color = const Color(0xFF10B981).withAlpha(180)
      ..style = PaintingStyle.fill;
    final backBillRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: billWidth * 0.9, height: billHeight * 0.85),
      const Radius.circular(6),
    );
    canvas.drawRRect(backBillRRect, backBillPaint);
    canvas.restore();

    // ورقة نقدية أمامية مستقيمة
    final billPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF34D399), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(billRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(billRect, const Radius.circular(8)),
      billPaint,
    );

    // تفاصيل نقدية داخل الورقة
    final billBorderPaint = Paint()
      ..color = Colors.white.withAlpha(90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(billRect.deflate(4), const Radius.circular(6)),
      billBorderPaint,
    );

    // 3. جسم الظرف الأساسي (Envelope Base)
    final envWidth = w * 0.76;
    final envHeight = h * 0.48;
    final envRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + h * 0.06),
      width: envWidth,
      height: envHeight,
    );

    // ظل الظرف
    final envShadowPaint = Paint()
      ..color = Colors.black.withAlpha(isDark ? 80 : 35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(envRect.shift(const Offset(0, 6)), const Radius.circular(16)),
      envShadowPaint,
    );

    // خامة الظرف الفاخر
    final envPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
            : [Colors.white, const Color(0xFFF1F5F9)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(envRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(envRect, const Radius.circular(16)),
      envPaint,
    );

    // إطار خفيف
    final envBorder = Paint()
      ..color = isDark ? Colors.white.withAlpha(25) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(envRect, const Radius.circular(16)),
      envBorder,
    );

    // 4. طيات الظرف السفلية والجانبية (Envelope Folds)
    final foldPaint = Paint()
      ..color = (isDark ? Colors.black : const Color(0xFFCBD5E1)).withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final foldPath = Path();
    // من الزاوية اليسرى السفلية للمركز
    foldPath.moveTo(envRect.left, envRect.bottom);
    foldPath.lineTo(center.dx, center.dy + h * 0.08);
    // من الزاوية اليمنى السفلية للمركز
    foldPath.moveTo(envRect.right, envRect.bottom);
    foldPath.lineTo(center.dx, center.dy + h * 0.08);
    canvas.drawPath(foldPath, foldPaint);

    // 5. غطاء الظرف المفتوح (Open Flap)
    final flapPath = Path();
    flapPath.moveTo(envRect.left, envRect.top);
    flapPath.lineTo(center.dx, envRect.top - h * 0.14);
    flapPath.lineTo(envRect.right, envRect.top);
    flapPath.close();

    final flapPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF334155), const Color(0xFF1E293B)]
            : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(envRect);
    canvas.drawPath(flapPath, flapPaint);
    canvas.drawPath(flapPath, envBorder);

    // 6. ختم الشمع الذهبي الملكي (Golden Wax Seal)
    final sealCenter = Offset(center.dx, envRect.top + h * 0.02);
    final sealRadius = w * 0.09;

    final sealShadow = Paint()
      ..color = const Color(0xFFD97706).withAlpha(100)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(sealCenter, sealRadius + 2, sealShadow);

    final sealPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFCD34D), Color(0xFFD97706), Color(0xFF92400E)],
        stops: [0.2, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: sealCenter, radius: sealRadius));
    canvas.drawCircle(sealCenter, sealRadius, sealPaint);

    // نقش الختم الداخلي
    final sealInnerRing = Paint()
      ..color = Colors.white.withAlpha(130)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(sealCenter, sealRadius * 0.65, sealInnerRing);

    // 7. جزيئات اللمعان والنجوم المحيطة (Sparkles)
    _drawSparkle(canvas, Offset(w * 0.18, h * 0.28), w * 0.035, sparklePhase);
    _drawSparkle(canvas, Offset(w * 0.82, h * 0.35), w * 0.045, (sparklePhase + 0.4) % 1.0);
    _drawSparkle(canvas, Offset(w * 0.75, h * 0.78), w * 0.028, (sparklePhase + 0.7) % 1.0);
  }

  void _drawSparkle(Canvas canvas, Offset pos, double radius, double phase) {
    final scale = 0.5 + 0.5 * math.sin(phase * math.pi * 2);
    final currentR = radius * scale;
    if (currentR <= 0.5) return;

    final paint = Paint()
      ..color = const Color(0xFFFBBF24).withAlpha((180 * scale).toInt())
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(pos.dx, pos.dy - currentR * 1.5);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx + currentR * 1.5, pos.dy);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy + currentR * 1.5);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx - currentR * 1.5, pos.dy);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy - currentR * 1.5);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EnvelopePainter oldDelegate) {
    return oldDelegate.glowAlpha != glowAlpha ||
        oldDelegate.sparklePhase != sparklePhase ||
        oldDelegate.isDark != isDark;
  }
}

/// ويدجت رسم فني لحصالة وأهداف الادخار (Savings Vault Illustration)
class ArtisticSavingsVaultIllustration extends StatefulWidget {
  final double size;
  const ArtisticSavingsVaultIllustration({super.key, this.size = 140});

  @override
  State<ArtisticSavingsVaultIllustration> createState() => _ArtisticSavingsVaultIllustrationState();
}

class _ArtisticSavingsVaultIllustrationState extends State<ArtisticSavingsVaultIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final floatOffset = math.sin(_controller.value * math.pi) * 5;

        return Transform.translate(
          offset: Offset(0, -floatOffset),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _VaultPainter(
                isDark: isDark,
                animValue: _controller.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VaultPainter extends CustomPainter {
  final bool isDark;
  final double animValue;

  _VaultPainter({required this.isDark, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2 + 10);

    // 1. هالة بنفسجية ملكية خلفية
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8B5CF6).withAlpha((70 + 40 * math.sin(animValue * math.pi)).toInt()),
          const Color(0xFFA78BFA).withAlpha(20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.45));
    canvas.drawCircle(center, w * 0.45, glowPaint);

    // 2. قاعدة الحصالة / الخزنة الفنية (Piggy/Vault Body)
    final bodyRect = Rect.fromCenter(
      center: center,
      width: w * 0.65,
      height: h * 0.52,
    );

    // ظل الجسم
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(isDark ? 90 : 30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(bodyRect.shift(const Offset(0, 8)), shadowPaint);

    // جسم الحصالة المتدرج
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFA78BFA), Color(0xFF7C3AED), Color(0xFF5B21B6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bodyRect);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(32)), bodyPaint);

    // لمعان أبيض علوي منحني
    final highlightPaint = Paint()
      ..color = Colors.white.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final highlightPath = Path();
    highlightPath.addArc(bodyRect.deflate(6), math.pi, math.pi / 2);
    canvas.drawPath(highlightPath, highlightPaint);

    // 3. فتحة العملة (Coin Slot)
    final slotRect = Rect.fromCenter(
      center: Offset(center.dx, bodyRect.top + 6),
      width: w * 0.22,
      height: 6,
    );
    final slotPaint = Paint()..color = const Color(0xFF3B0764);
    canvas.drawRRect(RRect.fromRectAndRadius(slotRect, const Radius.circular(3)), slotPaint);

    // 4. العملة الذهبية العائمة فوق الفتحة (Floating Golden Coin)
    final coinY = bodyRect.top - h * 0.16 + (math.sin(animValue * math.pi * 2) * 5);
    final coinCenter = Offset(center.dx, coinY);
    final coinRadius = w * 0.12;

    // توهج العملة
    final coinGlow = Paint()
      ..color = const Color(0xFFF59E0B).withAlpha(120)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(coinCenter, coinRadius + 2, coinGlow);

    // العملة
    final coinPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFEF08A), Color(0xFFF59E0B), Color(0xFFB45309)],
        stops: [0.2, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: coinCenter, radius: coinRadius));
    canvas.drawCircle(coinCenter, coinRadius, coinPaint);

    // نقش إطار العملة الداخلي ورمز النجمة
    final coinRing = Paint()
      ..color = Colors.white.withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(coinCenter, coinRadius * 0.7, coinRing);

    // 5. أقدام الحصالة اللطيفة
    final footPaint = Paint()..color = const Color(0xFF5B21B6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx - w * 0.2, bodyRect.bottom + 4), width: 18, height: 10),
        const Radius.circular(4),
      ),
      footPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx + w * 0.2, bodyRect.bottom + 4), width: 18, height: 10),
        const Radius.circular(4),
      ),
      footPaint,
    );

    // 6. نجوم ولمعان متألق
    _drawStar(canvas, Offset(w * 0.16, h * 0.22), 8, animValue);
    _drawStar(canvas, Offset(w * 0.84, h * 0.26), 10, (animValue + 0.5) % 1.0);
    _drawStar(canvas, Offset(w * 0.22, h * 0.80), 6, (animValue + 0.3) % 1.0);
  }

  void _drawStar(Canvas canvas, Offset pos, double size, double phase) {
    final scale = 0.5 + 0.5 * math.sin(phase * math.pi * 2);
    final s = size * scale;
    if (s <= 1) return;

    final paint = Paint()
      ..color = const Color(0xFFFCD34D).withAlpha((200 * scale).toInt())
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(pos.dx, pos.dy - s);
    path.lineTo(pos.dx + s * 0.3, pos.dy - s * 0.3);
    path.lineTo(pos.dx + s, pos.dy);
    path.lineTo(pos.dx + s * 0.3, pos.dy + s * 0.3);
    path.lineTo(pos.dx, pos.dy + s);
    path.lineTo(pos.dx - s * 0.3, pos.dy + s * 0.3);
    path.lineTo(pos.dx - s, pos.dy);
    path.lineTo(pos.dx - s * 0.3, pos.dy - s * 0.3);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _VaultPainter oldDelegate) {
    return oldDelegate.animValue != animValue || oldDelegate.isDark != isDark;
  }
}

/// ويدجت رسم فني للتقارير والتحليلات البيانية (Analytics Illustration)
class ArtisticAnalyticsIllustration extends StatefulWidget {
  final double size;
  const ArtisticAnalyticsIllustration({super.key, this.size = 140});

  @override
  State<ArtisticAnalyticsIllustration> createState() => _ArtisticAnalyticsIllustrationState();
}

class _ArtisticAnalyticsIllustrationState extends State<ArtisticAnalyticsIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _AnalyticsPainter(
              isDark: isDark,
              animValue: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class _AnalyticsPainter extends CustomPainter {
  final bool isDark;
  final double animValue;

  _AnalyticsPainter({required this.isDark, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. هالة إضاءة زرقاء زمردية ناعمة
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0EA5E9).withAlpha((50 + 30 * math.sin(animValue * math.pi)).toInt()),
          AppColors.primary.withAlpha(20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.45));
    canvas.drawCircle(center, w * 0.45, glow);

    // 2. لوح التقرير الرخامي الشفاف (Floating Dashboard Board)
    final boardRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + 4),
      width: w * 0.78,
      height: h * 0.62,
    );

    final boardPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF1E293B).withAlpha(230), const Color(0xFF0F172A).withAlpha(230)]
            : [Colors.white.withAlpha(240), const Color(0xFFF8FAFC).withAlpha(240)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(boardRect);
    canvas.drawRRect(RRect.fromRectAndRadius(boardRect, const Radius.circular(18)), boardPaint);

    final boardBorder = Paint()
      ..color = isDark ? Colors.white.withAlpha(25) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(boardRect, const Radius.circular(18)), boardBorder);

    // 3. أعمدة بيانية فنية صاعدة (Stylized Bars)
    final barWidth = w * 0.08;
    final baseBottom = boardRect.bottom - h * 0.10;

    final barHeights = [
      h * 0.16 + (math.sin(animValue * math.pi) * 4),
      h * 0.28 - (math.cos(animValue * math.pi) * 5),
      h * 0.22 + (math.sin(animValue * math.pi + 1) * 3),
      h * 0.36 + (math.sin(animValue * math.pi * 2) * 4),
    ];

    final barColors = [
      const [Color(0xFF38BDF8), Color(0xFF0284C7)],
      const [Color(0xFF34D399), Color(0xFF059669)],
      const [Color(0xFFFBBF24), Color(0xFFD97706)],
      const [Color(0xFFA78BFA), Color(0xFF7C3AED)],
    ];

    for (int i = 0; i < 4; i++) {
      final barX = boardRect.left + w * 0.12 + (i * (barWidth + w * 0.065));
      final barH = barHeights[i];
      final bRect = Rect.fromLTWH(barX, baseBottom - barH, barWidth, barH);

      final barPaint = Paint()
        ..shader = LinearGradient(
          colors: barColors[i],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bRect);

      canvas.drawRRect(RRect.fromRectAndRadius(bRect, const Radius.circular(6)), barPaint);
    }

    // 4. خط اتجاه انسيابي منحني مع نقاط متوهجة (Bezier Trendline)
    final path = Path();
    final p0 = Offset(boardRect.left + w * 0.08, baseBottom - h * 0.12);
    final p1 = Offset(boardRect.left + w * 0.26, baseBottom - h * 0.26);
    final p2 = Offset(boardRect.left + w * 0.44, baseBottom - h * 0.18);
    final p3 = Offset(boardRect.left + w * 0.64, baseBottom - h * 0.38 - (math.sin(animValue * math.pi) * 5));

    path.moveTo(p0.dx, p0.dy);
    path.cubicTo(p1.dx - 15, p1.dy, p1.dx, p1.dy, p1.dx, p1.dy);
    path.cubicTo(p2.dx - 15, p2.dy, p2.dx, p2.dy, p2.dx, p2.dy);
    path.cubicTo(p3.dx - 15, p3.dy, p3.dx, p3.dy, p3.dx, p3.dy);

    final linePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // النقطة الأخيرة المتوهجة
    final nodeGlow = Paint()
      ..color = const Color(0xFF34D399).withAlpha(150)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(p3, 6, nodeGlow);

    final nodePaint = Paint()..color = Colors.white;
    canvas.drawCircle(p3, 4, nodePaint);
  }

  @override
  bool shouldRepaint(covariant _AnalyticsPainter oldDelegate) {
    return oldDelegate.animValue != animValue || oldDelegate.isDark != isDark;
  }
}

/// ويدجت رسم فني للمحفظة الفارغة (Empty Wallet Illustration)
class ArtisticWalletIllustration extends StatefulWidget {
  final double size;
  const ArtisticWalletIllustration({super.key, this.size = 140});

  @override
  State<ArtisticWalletIllustration> createState() => _ArtisticWalletIllustrationState();
}

class _ArtisticWalletIllustrationState extends State<ArtisticWalletIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final floatOffset = math.sin(_controller.value * math.pi) * 4;

        return Transform.translate(
          offset: Offset(0, -floatOffset),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _WalletPainter(
                isDark: isDark,
                animValue: _controller.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WalletPainter extends CustomPainter {
  final bool isDark;
  final double animValue;

  _WalletPainter({required this.isDark, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2 + 4);

    // 1. هالة خضراء زمردية
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withAlpha((60 + 30 * math.sin(animValue * math.pi)).toInt()),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.45));
    canvas.drawCircle(center, w * 0.45, glow);

    // 2. بطاقة ائتمانية بارزة من المحفظة
    final cardRect = Rect.fromCenter(
      center: Offset(center.dx - 4, center.dy - h * 0.16),
      width: w * 0.52,
      height: h * 0.32,
    );

    final cardPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(cardRect);
    canvas.drawRRect(RRect.fromRectAndRadius(cardRect, const Radius.circular(10)), cardPaint);

    // شريحة ذهبية على البطاقة
    final chipRect = Rect.fromLTWH(cardRect.left + 10, cardRect.top + 10, 14, 10);
    final chipPaint = Paint()..color = const Color(0xFFFCD34D);
    canvas.drawRRect(RRect.fromRectAndRadius(chipRect, const Radius.circular(3)), chipPaint);

    // 3. جسم المحفظة الجلدية الأساسي
    final walletRect = Rect.fromCenter(
      center: center,
      width: w * 0.72,
      height: h * 0.54,
    );

    final walletShadow = Paint()
      ..color = Colors.black.withAlpha(isDark ? 90 : 35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(walletRect.shift(const Offset(0, 6)), const Radius.circular(18)),
      walletShadow,
    );

    final walletPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF334155), const Color(0xFF1E293B)]
            : [const Color(0xFF0F766E), const Color(0xFF115E59)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(walletRect);
    canvas.drawRRect(RRect.fromRectAndRadius(walletRect, const Radius.circular(18)), walletPaint);

    // خياطة جلدية أنيقة (Stitching)
    final stitchPaint = Paint()
      ..color = Colors.white.withAlpha(70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(RRect.fromRectAndRadius(walletRect.deflate(6), const Radius.circular(14)), stitchPaint);

    // 4. مشبك الإغلاق المذهب (Golden Clasp)
    final claspRect = Rect.fromCenter(
      center: Offset(walletRect.right - 8, center.dy),
      width: w * 0.16,
      height: h * 0.22,
    );
    final claspPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF475569), const Color(0xFF1E293B)]
            : [const Color(0xFF134E4A), const Color(0xFF042F2E)],
      ).createShader(claspRect);
    canvas.drawRRect(RRect.fromRectAndRadius(claspRect, const Radius.circular(8)), claspPaint);

    // زر المشبك الذهبي
    final buttonCenter = Offset(claspRect.left + 10, center.dy);
    final buttonPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFDE68A), Color(0xFFD97706)],
      ).createShader(Rect.fromCircle(center: buttonCenter, radius: 7));
    canvas.drawCircle(buttonCenter, 6, buttonPaint);

    // 5. لمعات متطايرة
    _drawSparkle(canvas, Offset(w * 0.18, h * 0.26), 6, animValue);
    _drawSparkle(canvas, Offset(w * 0.82, h * 0.72), 7, (animValue + 0.6) % 1.0);
  }

  void _drawSparkle(Canvas canvas, Offset pos, double r, double phase) {
    final scale = 0.5 + 0.5 * math.sin(phase * math.pi * 2);
    final s = r * scale;
    if (s <= 0.5) return;

    final paint = Paint()
      ..color = const Color(0xFFFBBF24).withAlpha((200 * scale).toInt())
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, s, paint);
  }

  @override
  bool shouldRepaint(covariant _WalletPainter oldDelegate) {
    return oldDelegate.animValue != animValue || oldDelegate.isDark != isDark;
  }
}
