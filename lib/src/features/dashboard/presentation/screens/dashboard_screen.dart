import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:bashnddof/src/core/models/transaction_model.dart';
import 'package:bashnddof/src/core/models/category_model.dart';
import 'package:bashnddof/src/core/repositories/transaction_repository.dart';
import 'package:bashnddof/src/core/theme/app_colors.dart';
import 'package:bashnddof/src/core/widgets/financial_card.dart';
import 'package:bashnddof/src/features/envelopes/presentation/screens/envelopes_screen.dart';
import 'package:bashnddof/src/features/recurring/presentation/screens/recurring_transactions_screen.dart';
import 'package:bashnddof/src/features/reports/presentation/screens/reports_screen.dart';
import 'package:bashnddof/src/features/savings/presentation/screens/savings_goals_screen.dart';
import 'package:bashnddof/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:bashnddof/src/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:bashnddof/src/core/currency/currency_service.dart';
import 'package:bashnddof/src/core/localization/app_localizations.dart';

import 'package:bashnddof/src/core/repositories/in_app_notification_repository.dart';
import 'package:bashnddof/src/core/services/notification_service.dart';
import 'package:bashnddof/src/core/widgets/artistic_bottom_nav_bar.dart';
import 'package:bashnddof/src/core/widgets/artistic_illustrations.dart';
import 'package:bashnddof/src/features/notifications/presentation/screens/notifications_screen.dart';

/// الشاشة الرئيسية ولوحة التحكم المركزية لتطبيق BASHNDDOF
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  int _refreshTrigger = 0;
  int _unreadNotificationCount = 0;
  late final PageController _pageController;
  final _notificationRepo = InAppNotificationRepository();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _loadUnreadNotifications();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadNotifications() async {
    await NotificationService().checkDueRecurringTransactions();
    final count = await _notificationRepo.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadNotificationCount = count;
      });
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (_selectedIndex != index) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedIndex = index;
      });
      _loadUnreadNotifications();
    }
  }

  String _getAppBarTitle(BuildContext context) {
    final loc = context.loc;
    switch (_selectedIndex) {
      case 0:
        return loc.appName;
      case 1:
        return loc.translate('budgetEnvelopes');
      case 2:
        return loc.translate('financialReports');
      case 3:
        return loc.translate('savingsGoalsTitle');
      default:
        return loc.appName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedIndex == 0) ...[
              Image.asset(
                'assets/images/logo_transparent.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
            ],
            Text(_getAppBarTitle(context)),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, size: 26),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.expense,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadNotificationCount > 9 ? '+9' : '$_unreadNotificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: isArabic ? 'الإشعارات والتنبيهات' : 'Notifications',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
              _loadUnreadNotifications();
            },
          ),
          IconButton(
            icon: const Icon(Icons.repeat_rounded),
            tooltip: isArabic ? 'المعاملات المتكررة' : 'Recurring Transactions',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const RecurringTransactionsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: isArabic ? 'الإعدادات' : 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: [
          DashboardHomeTab(
            key: ValueKey('tab-0-$_refreshTrigger'),
            onNavigateToSavings: () => _onItemTapped(3),
          ),
          EnvelopesScreen(
            key: ValueKey('tab-1-$_refreshTrigger'),
            showAppBar: false,
          ),
          ReportsScreen(
            key: ValueKey('tab-2-$_refreshTrigger'),
            showAppBar: false,
          ),
          SavingsGoalsScreen(
            key: ValueKey('tab-3-$_refreshTrigger'),
            showAppBar: false,
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final added = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
                );
                if (added == true && mounted) {
                  setState(() {
                    _refreshTrigger++;
                  });
                }
              },
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      bottomNavigationBar: SafeArea(
        top: false,
        child: ArtisticBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemTapped,
        ),
      ),
    );
  }
}

/// لسان التبويب الرئيسي لعرض الرصيد، الإجراءات السريعة، وأحدث المعاملات
class DashboardHomeTab extends StatefulWidget {
  final VoidCallback? onNavigateToSavings;
  const DashboardHomeTab({super.key, this.onNavigateToSavings});

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab> {
  final _transactionRepo = TransactionRepository();

  double _balance = 0.0;
  double _income = 0.0;
  double _expenses = 0.0;
  List<TransactionModel> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final balance = await _transactionRepo.getCurrentBalance();
    final income = await _transactionRepo.getTotalIncome(
      from: firstDayOfMonth,
      to: lastDayOfMonth,
    );
    final expenses = await _transactionRepo.getTotalExpenses(
      from: firstDayOfMonth,
      to: lastDayOfMonth,
    );
    final recent = await _transactionRepo.getRecent(limit: 8);

    if (mounted) {
      setState(() {
        _balance = balance;
        _income = income;
        _expenses = expenses;
        _recentTransactions = recent;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTransaction(TransactionModel tx) async {
    final isArabic = context.isArabic;
    final loc = context.loc;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.translate('delete')),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من حذف معاملة "${tx.title}"؟'
              : 'Are you sure you want to delete "${tx.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.translate('cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && tx.id != null) {
      await _transactionRepo.delete(tx.id!);
      HapticFeedback.mediumImpact();
      _loadDashboardData();
    }
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'receipt_long':
        return Icons.receipt_long_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'movie':
        return Icons.movie_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'payments':
        return Icons.payments_rounded;
      case 'laptop_mac':
        return Icons.laptop_mac_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'savings':
        return Icons.savings_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.isArabic;
    final loc = context.loc;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // بطاقة الرصيد الفاخرة
          FinancialCard(
            balance: _balance,
            income: _income,
            expenses: _expenses,
          ),
          const SizedBox(height: 24),

          // صف الإجراءات السريعة
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  icon: Icons.add_circle_outline_rounded,
                  label: loc.translate('addTransaction'),
                  color: AppColors.primary,
                  onTap: () async {
                    final res = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
                    );
                    if (res == true) _loadDashboardData();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  icon: Icons.savings_rounded,
                  label: loc.translate('savingsGoals'),
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    if (widget.onNavigateToSavings != null) {
                      widget.onNavigateToSavings!();
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SavingsGoalsScreen(showAppBar: true),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  icon: Icons.repeat_rounded,
                  label: loc.translate('recurringTransactions'),
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const RecurringTransactionsScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // رأس قسم أحدث المعاملات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.translate('recentTransactions'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (_recentTransactions.isNotEmpty)
                Text(
                  '${_recentTransactions.length} ${isArabic ? "معاملات" : "txns"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // قائمة المعاملات أو الحالة الفارغة
          if (_recentTransactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  const ArtisticWalletIllustration(size: 130),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'لا توجد معاملات مسجلة حتى الآن' : 'No transactions recorded yet',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isArabic
                        ? 'ابدأ بتسجيل أول دخل أو مصروف لتتبع رصيدك وميزانيتك'
                        : 'Start logging your income or expenses to track your balance and budget',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(isArabic ? 'إضافة أول معاملة' : 'Add First Transaction'),
                    onPressed: () async {
                      final res = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
                      );
                      if (res == true) _loadDashboardData();
                    },
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentTransactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final tx = _recentTransactions[index];
                final dateFormatted = DateFormat('MM/dd - hh:mm a', 'ar').format(tx.date);
                final categoryColor = tx.categoryColor != null
                    ? Color(tx.categoryColor!)
                    : (tx.isIncome ? AppColors.income : AppColors.expense);

                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: categoryColor.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconData(tx.categoryIcon),
                        color: categoryColor,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      tx.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Row(
                      children: [
                        if (tx.isRecurring) ...[
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.repeat_rounded, size: 11, color: Color(0xFFD97706)),
                                const SizedBox(width: 3),
                                Text(
                                  isArabic ? 'دورية' : 'Recurring',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            '${CategoryModel.localizeName(tx.categoryName ?? (tx.isIncome ? (isArabic ? 'دخل' : 'Income') : (isArabic ? 'مصروف' : 'Expense')), isArabic: isArabic)} • $dateFormatted',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyService.format(
                            tx.amount,
                            isArabic: isArabic,
                            showSign: true,
                            isIncome: tx.isIncome,
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: tx.isIncome ? AppColors.income : AppColors.expense,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 18),
                          padding: EdgeInsets.zero,
                          tooltip: isArabic ? 'خيارات' : 'Options',
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          onSelected: (val) async {
                            if (val == 'edit') {
                              final updated = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (context) => AddTransactionScreen(editTransaction: tx),
                                ),
                              );
                              if (updated == true) _loadDashboardData();
                            } else if (val == 'delete') {
                              _deleteTransaction(tx);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text(loc.translate('edit')),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expense),
                                  const SizedBox(width: 8),
                                  Text(loc.translate('delete'), style: const TextStyle(color: AppColors.expense)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (context) => AddTransactionScreen(editTransaction: tx),
                        ),
                      );
                      if (updated == true) _loadDashboardData();
                    },
                    onLongPress: () => _deleteTransaction(tx),
                  ),
                );
              },
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
