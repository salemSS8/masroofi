import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/in_app_notification_model.dart';
import '../../../../core/repositories/in_app_notification_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/artistic_illustrations.dart';
import '../../../../core/localization/app_localizations.dart';

/// شاشة سجل ومركز الإشعارات والتنبيهات المالية (Notifications Screen)
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = InAppNotificationRepository();
  List<InAppNotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final items = await _repo.getAll();
    if (mounted) {
      setState(() {
        _notifications = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    await _repo.markAllAsRead();
    HapticFeedback.lightImpact();
    _loadNotifications();
    if (!mounted) return;
    final isArabic = mounted ? context.isArabic : true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isArabic
            ? '✅ تم تحديد كافة الإشعارات كمقروءة'
            : '✅ All notifications marked as read'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _clearAll() async {
    final isArabic = context.isArabic;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'مسح سجل الإشعارات' : 'Clear Notifications'),
        content: Text(isArabic
            ? 'هل أنت متأكد من رغبتك في حذف جميع الإشعارات المحفوظة؟'
            : 'Are you sure you want to delete all saved notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isArabic ? 'مسح الكل' : 'Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repo.deleteAll();
      HapticFeedback.mediumImpact();
      _loadNotifications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic
              ? 'تم مسح سجل الإشعارات بالكامل'
              : 'Notification history cleared'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _onNotificationTap(InAppNotificationModel item) async {
    if (!item.isRead && item.id != null) {
      await _repo.markAsRead(item.id!);
      _loadNotifications();
    }
  }

  Future<void> _deleteSingle(InAppNotificationModel item) async {
    if (item.id != null) {
      await _repo.delete(item.id!);
      HapticFeedback.lightImpact();
      _loadNotifications();
    }
  }

  (IconData, Color) _getTypeVisuals(String type) {
    switch (type) {
      case 'budget':
        return (Icons.warning_amber_rounded, AppColors.expense);
      case 'reminder':
        return (Icons.nights_stay_rounded, const Color(0xFF8B5CF6));
      case 'recurring':
        return (Icons.repeat_rounded, const Color(0xFFF59E0B));
      case 'system':
      default:
        return (Icons.notifications_active_rounded, AppColors.primary);
    }
  }

  String _localizeNotificationTitle(String title, bool isArabic) {
    if (isArabic) {
      if (title.contains('Daily Expense Reminder')) return 'تذكير المصروفات اليومي | مصروفي';
      if (title.contains('Envelope Budget Exceeded')) return 'تجاوزت ميزانية الظرف';
      if (title.contains('Budget Alert') || title.contains('Budget Warning')) return 'تنبيه اقتراب ميزانية';
      if (title.contains('Recurring Transaction Due')) return 'موعد استحقاق معاملة دورية';
      if (title.contains('Test Notification')) return 'إشعار تجريبي | مصروفي';
      if (title.contains('Goal Achieved') || title.contains('Congratulations')) return 'تهانينا، حققت هدف الادخار';
      return title
          .replaceAll('🔔', '')
          .replaceAll('🌙', '')
          .replaceAll('⚠️', '')
          .replaceAll('⚡', '')
          .replaceAll('⏰', '')
          .replaceAll('🎉', '')
          .replaceAll('BASHNDDOF', 'مصروفي')
          .trim();
    } else {
      if (title.contains('تذكير المصروفات اليومي')) return 'Daily Expense Reminder | Masroufi';
      if (title.contains('تجاوزت ميزانية الظرف')) return 'Envelope Budget Exceeded';
      if (title.contains('تنبيه اقتراب ميزانية')) return 'Budget Alert';
      if (title.contains('موعد استحقاق معاملة دورية')) return 'Recurring Transaction Due';
      if (title.contains('إشعار تجريبي')) return 'Test Notification | Masroufi';
      if (title.contains('هدف الادخار') || title.contains('تهانينا')) return 'Congratulations! Goal Achieved';
      return title
          .replaceAll('🔔', '')
          .replaceAll('🌙', '')
          .replaceAll('⚠️', '')
          .replaceAll('⚡', '')
          .replaceAll('⏰', '')
          .replaceAll('🎉', '')
          .replaceAll('BASHNDDOF', 'Masroufi')
          .trim();
    }
  }

  String _localizeNotificationBody(String body, bool isArabic) {
    if (isArabic) {
      if (body.contains("Don't forget to log today's expenses")) {
        return 'لا تنسَ تسجيل مصروفات وإيرادات اليوم للحفاظ على دقة ميزانيتك.';
      }
      if (body.contains('You have consumed the entire budget for envelope')) {
        return body.replaceAll('You have consumed the entire budget for envelope', 'لقد استهلكت كامل الميزانية المحددة لظرف');
      }
      if (body.contains('Time to record/pay')) {
        return body
            .replaceAll('Time to record/pay', 'حان موعد دفع/تسجيل')
            .replaceAll(' of ', ' بمبلغ ');
      }
      if (body.contains('Local notification system is working')) {
        return 'نظام الإشعارات المحلي يعمل بنجاح وبدون إنترنت على هاتفك!';
      }
      return body;
    } else {
      if (body.contains('لا تنسَ تسجيل مصروفات وإيرادات اليوم')) {
        return "Don't forget to log today's expenses and income to keep your budget accurate.";
      }
      if (body.contains('لقد استهلكت كامل الميزانية المحددة لظرف')) {
        return body.replaceAll('لقد استهلكت كامل الميزانية المحددة لظرف', 'You have consumed the entire budget for envelope');
      }
      if (body.contains('حان موعد دفع/تسجيل')) {
        return body
            .replaceAll('حان موعد دفع/تسجيل', 'Time to record/pay')
            .replaceAll(' بمبلغ ', ' of ');
      }
      if (body.contains('نظام الإشعارات المحلي يعمل')) {
        return 'Local notification system is working successfully offline!';
      }
      return body;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.isArabic;
    final hasUnread = _notifications.any((n) => !n.isRead);

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'سجل التنبيهات' : 'Notification Center'),
        actions: [
          if (hasUnread)
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: isArabic ? 'تحديد الكل كمقروء' : 'Mark all as read',
              onPressed: _markAllAsRead,
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: isArabic ? 'مسح السجل' : 'Clear log',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const ArtisticAnalyticsIllustration(size: 135),
                            const SizedBox(height: 20),
                            Text(
                              isArabic ? 'لا توجد إشعارات مسجلة' : 'No notifications yet',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isArabic
                                  ? 'ستظهر هنا تنبيهات تجاوز الميزانية، وتذكيرات المصروفات، وأي تنبيهات مالية مهمة.'
                                  : 'Budget alerts, expense reminders, and important financial updates will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _notifications[index];
                        final visuals = _getTypeVisuals(item.type);
                        final dateStr = DateFormat('MM/dd - hh:mm a', isArabic ? 'ar' : 'en')
                            .format(item.createdAt);

                        return Dismissible(
                          key: Key('notif-${item.id}'),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _deleteSingle(item),
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            decoration: BoxDecoration(
                              color: AppColors.expense,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.white),
                          ),
                          child: InkWell(
                            onTap: () => _onNotificationTap(item),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? (item.isRead
                                        ? AppColors.darkSurface
                                        : AppColors.darkSurfaceAlt)
                                    : (item.isRead
                                        ? AppColors.surface
                                        : AppColors.surfaceAlt),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: item.isRead
                                      ? (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.border)
                                      : AppColors.primary.withAlpha(100),
                                  width: item.isRead ? 1.0 : 1.5,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: visuals.$2.withAlpha(25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(visuals.$1, color: visuals.$2, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _localizeNotificationTitle(item.title, isArabic),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: item.isRead
                                                      ? FontWeight.w600
                                                      : FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            if (!item.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          _localizeNotificationBody(item.body, isArabic),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.textSecondary,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.darkTextHint
                                                : AppColors.textHint,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
