import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../localization/app_localizations.dart';

/// شريط التنقل السفلي الفني العائم (Artistic Floating Navigation Dock)
/// يتميز بـ:
/// - تصميم عائم بتأثير زجاجي راقٍ وبوردر انسيابي
/// - مؤشر تفاعلي منزلق يراعي اتجاه اللغتين (RTL للعربية و LTR للإنجليزية)
/// - تعريب كامل لتسميات الأزرار
class ArtisticBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const ArtisticBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final loc = context.loc;

    final navItems = [
      _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: loc.navHome,
      ),
      _NavItem(
        icon: Icons.mail_outline_rounded,
        activeIcon: Icons.mail_rounded,
        label: loc.navEnvelopes,
      ),
      _NavItem(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        label: loc.navReports,
      ),
      _NavItem(
        icon: Icons.savings_outlined,
        activeIcon: Icons.savings_rounded,
        label: loc.navSavings,
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withAlpha(240)
            : Colors.white.withAlpha(245),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(20) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 25),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / navItems.length;

          return Stack(
            children: [
              // 1. المؤشر المنزلق المتوهج (Animated Sliding Indicator)
              // يراعي اتجاه اللغتين RTL في العربية و LTR في الإنجليزية
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                right: isRtl ? selectedIndex * itemWidth : null,
                left: isRtl ? null : selectedIndex * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(100),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. عناصر القائمة التفاعلية
              Row(
                children: List.generate(navItems.length, (index) {
                  final item = navItems[index];
                  final isSelected = selectedIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!isSelected) {
                          HapticFeedback.selectionClick();
                          onItemSelected(index);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // أيقونة مع تأثير التكبير عند التحديد
                            AnimatedScale(
                              scale: isSelected ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                size: 22,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(height: 3),
                            // نص العنصر المعرب
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    isSelected ? FontWeight.w800 : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
