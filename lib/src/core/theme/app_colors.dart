import 'package:flutter/material.dart';

/// لوحة الألوان المركزية لتطبيق BASHNDDOF
/// مستوحاة من درجات الأخضر الزمردي المالي الراقي مع ألوان محايدة فائقة النقاء
class AppColors {
  AppColors._();

  // 🌿 الألوان الأساسية (Primary & Emerald Brand)
  static const Color primary = Color(0xFF1B8A6B); // أخضر زمردي عميق
  static const Color primaryLight = Color(0xFF4ECDC4); // فيروزي منعش
  static const Color primaryDark = Color(0xFF0D5C46); // زمردي داكن
  static const Color primarySubtle = Color(0xFFE8F6F2); // مسحة خضراء ناعمة جداً

  // ☀️ الوضع الفاتح (Light Theme)
  static const Color background = Color(0xFFF7F9FC); // رمادي مالي فاتح جداً
  static const Color surface = Color(0xFFFFFFFF); // أبيض ناصع للبطاقات
  static const Color surfaceAlt = Color(0xFFF0F4F8); // سطح بديل للعناصر
  static const Color border = Color(0xFFE2E8F0); // حدود ناعمة
  static const Color divider = Color(0xFFEDF2F7);

  // 🌙 الوضع الداكن (Dark Theme)
  static const Color darkBackground = Color(0xFF0B131E); // كحلي مالي فاحم
  static const Color darkSurface = Color(0xFF14202E); // بطاقات داكنة فاخرة
  static const Color darkSurfaceAlt = Color(0xFF1E2E42); // سطح بديل
  static const Color darkBorder = Color(0xFF283A50);
  static const Color darkDivider = Color(0xFF1F2F43);

  // 📝 ألوان النصوص (Typography Colors)
  static const Color textPrimary = Color(0xFF0F172A); // أسود كحلي عميق عالي التباين
  static const Color textSecondary = Color(0xFF64748B); // رمادي مائل للزرقة
  static const Color textHint = Color(0xFF94A3B8); // نص مساعد رمادي
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // أبيض قمرى
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextHint = Color(0xFF64748B);

  // 📊 ألوان الحالة المالية (Financial Status Colors)
  static const Color income = Color(0xFF10B981); // أخضر دخل
  static const Color incomeSubtle = Color(0xFFD1FAE5);
  static const Color expense = Color(0xFFEF4444); // أحمر مصروف
  static const Color expenseSubtle = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B); // برتقالي تحذيري
  static const Color warningSubtle = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6); // أزرق معلومات
  static const Color infoSubtle = Color(0xFFDBEAFE);

  // ✉️ ألوان الأظرف المالية (Envelope Custom Palettes)
  static const List<Color> envelopeColors = [
    Color(0xFF6366F1), // نيلي Indigo
    Color(0xFF10B981), // زمردي Emerald
    Color(0xFFF59E0B), // عنبري Amber
    Color(0xFFEC4899), // وردي Pink
    Color(0xFF3B82F6), // أزرق Blue
    Color(0xFF8B5CF6), // بنفسجي Purple
    Color(0xFF14B8A6), // فيروزي Teal
    Color(0xFFF97316), // برتقالي Orange
    Color(0xFF06B6D4), // سماوي Cyan
  ];

  // 🌈 التدرجات اللونية الفاخرة (Gradients)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF1B8A6B), Color(0xFF28A07F)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF0F5C46), Color(0xFF1B8A6B), Color(0xFF25A180)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A2C3D), Color(0xFF0F1A26)],
  );

  static const LinearGradient incomeGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF059669), Color(0xFF10B981)],
  );

  static const LinearGradient expenseGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
  );
}
