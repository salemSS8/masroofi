import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bashnddof/src/core/theme/app_colors.dart';
import 'package:bashnddof/src/core/widgets/app_button.dart';
import 'package:bashnddof/src/core/localization/app_localizations.dart';

/// شاشة التعريف والترحيب التفاعلية العصرية (Modern Interactive Onboarding)
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onFinish(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed('/pin_setup');
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _onFinish(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = context.loc;
    final isArabic = context.isArabic;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // الشريط العلوي (العلامة وزر التخطي/البدء)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // شارة الشعار والاسم
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(30),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo_transparent.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isArabic ? 'مصروفي' : 'Masroufi',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  // زر التخطي / البدء السريع
                  TextButton(
                    onPressed: () => _onFinish(context),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                    ),
                    child: Text(
                      _currentPage == 0
                          ? loc.translate('start')
                          : loc.translate('skip'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // صفحات الترحيب التفاعلية (Carousel)
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPageOne(context, isDark, loc, isArabic),
                  _buildPageTwo(context, isDark, loc, isArabic),
                  _buildPageThree(context, isDark, loc, isArabic),
                ],
              ),
            ),

            // مؤشر الصفحات والأزرار السفلية
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // مؤشر الصفحات الديناميكي
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isActive
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(90),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // زر الإجراء الرئيسي
                  AppButton(
                    text: _currentPage == 2
                        ? loc.translate('getStarted')
                        : loc.translate('next'),
                    icon: context.forwardArrow,
                    onPressed: _nextPage,
                  ),
                  const SizedBox(height: 12),

                  // التوقيع اللطيف
                  Text(
                    loc.translate('madeWithLove'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- الصفحة الأولى: الترحيب والانطلاقة ---
  Widget _buildPageOne(BuildContext context, bool isDark, AppLocalizations loc, bool isArabic) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // الشعار المركزي الفاخر مع توهج هادئ
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // دائرة التوهج المحيطية
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withAlpha(isDark ? 40 : 25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // حاوية الأيقونة
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(isDark ? 55 : 35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
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
                      width: 82,
                      height: 82,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // شارة "100% محلي وبدون إنترنت"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withAlpha(45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined, size: 15, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  isArabic ? 'محفظة مالية آمنة ومحلية 100%' : '100% Offline & Secure Wallet',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // العنوان الرئيسي
          Text(
            loc.translate('introWelcome'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),

          // الوصف التوضيحي
          Text(
            loc.translate('introSubtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),

          // بطاقة ميزة الأوفلاين الأساسية
          _buildFeatureCard(
            context,
            icon: Icons.wifi_off_rounded,
            iconColor: AppColors.primary,
            title: loc.translate('offlineFeature'),
            subtitle: loc.translate('offlineFeatureSub'),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            context,
            icon: Icons.lock_outline_rounded,
            iconColor: const Color(0xFF10B981),
            title: isArabic ? 'سرية بياناتك هي أولويتنا' : 'Total Privacy Guaranteed',
            subtitle: isArabic
                ? 'لا نطلب تسجيل بريد، لا نستخدم خوادم سحابية، ولا نتتبع نفقاتك'
                : 'No registration, no cloud servers, zero ads or tracking',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // --- الصفحة الثانية: نظام الأظرف والميزانية ---
  Widget _buildPageTwo(BuildContext context, bool isDark, AppLocalizations loc, bool isArabic) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // بطاقة تمثيلية ذكية لميزانية الأظرف
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [Colors.white, const Color(0xFFF1F5F9)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : Colors.black.withAlpha(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 50 : 15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // رأس البطاقة
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mail_lock_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'ظرف التسوق والمقاضي' : 'Groceries & Supplies',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          Text(
                            isArabic ? 'المتبقي: 45,000 ريال (65%)' : 'Remaining: 45,000 YER (65%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // شريط التقدم التوضيحي
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 0.65,
                    minHeight: 10,
                    backgroundColor: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(15),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 14),

                // شارة تنبيه ذكية
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'تنبيه استباقي عند الاقتراب من حد الميزانية'
                              : 'Proactive alerts before exceeding budget limit',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // العنوان
          Text(
            loc.translate('envelopesFeature'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),

          // الوصف
          Text(
            loc.translate('envelopesFeatureSub'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          _buildFeatureCard(
            context,
            icon: Icons.pie_chart_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: isArabic ? 'تقسيم مرن وسلس للنفقات' : 'Flexible Expense Allocation',
            subtitle: isArabic
                ? 'أنشئ أظرفاً لفواتيرك، عائلتك، ومصروفاتك اليومية بسهولة'
                : 'Create envelopes for bills, family, and daily spending easily',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            context,
            icon: Icons.savings_rounded,
            iconColor: const Color(0xFF10B981),
            title: isArabic ? 'أهداف ادخار واضحة' : 'Dedicated Savings Goals',
            subtitle: isArabic
                ? 'ادخر لأهدافك الكبرى وراقب نسبة الإنجاز حتى اكتمالها'
                : 'Save for your key goals and watch your progress reach 100%',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // --- الصفحة الثالثة: الأمان والتشفير ---
  Widget _buildPageThree(BuildContext context, bool isDark, AppLocalizations loc, bool isArabic) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // قفل الأمان وتشفير البيانات الفاخر
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withAlpha(40),
                  const Color(0xFF10B981).withAlpha(40),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.darkSurface : Colors.white,
                ),
                child: const Icon(
                  Icons.enhanced_encryption_rounded,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // شارة الأمان
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withAlpha(45)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 14, color: Color(0xFF10B981)),
                SizedBox(width: 6),
                Text(
                  'AES-256 MILITARY ENCRYPTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // العنوان
          Text(
            loc.translate('securityFeature'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),

          // الوصف
          Text(
            loc.translate('securityFeatureSub'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          _buildFeatureCard(
            context,
            icon: Icons.fingerprint_rounded,
            iconColor: AppColors.primary,
            title: isArabic ? 'دعم البصمة والتعرف على الوجه' : 'Biometric Face & Fingerprint',
            subtitle: isArabic
                ? 'تسجيل دخول فوري وآمن بلمسة واحدة دون الحاجة لكتابة الرمز كل مرة'
                : 'Instant secure login using device biometrics or passkey',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            context,
            icon: Icons.backup_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: isArabic ? 'نسخ احتياطي مشفر بالكامل' : 'Encrypted Offline Backup',
            subtitle: isArabic
                ? 'صدّر واستعد بياناتك متى أردت بكلمة مرور خاصة تشفر ملفاتك'
                : 'Export and restore your database anytime with custom password protection',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
