import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/features/core/presentation/screens/intro_screen.dart';
import 'src/features/auth/presentation/pin_setup_screen.dart';
import 'src/features/auth/presentation/login_screen.dart';
import 'src/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'src/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'src/features/budget/presentation/screens/initial_budget_setup_screen.dart';
import 'src/core/services/notification_service.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/theme/theme_service.dart';
import 'src/core/localization/language_service.dart';
import 'src/core/localization/app_localizations.dart';
import 'src/core/currency/currency_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().initialize();
  await ThemeService.init();
  await LanguageService.init();
  await CurrencyService.init();

  final prefs = await SharedPreferences.getInstance();
  final isFirstTime = prefs.getBool('isFirstTime') ?? true;

  runApp(MyApp(isFirstTime: isFirstTime));
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;
  const MyApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeModeNotifier,
      builder: (context, currentThemeMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LanguageService.localeNotifier,
          builder: (context, currentLocale, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'BASHNDDOF',
              locale: currentLocale,
              supportedLocales: const [
                Locale('ar'),
                Locale('en'),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: currentThemeMode,
              initialRoute: isFirstTime ? '/intro' : '/login',
              routes: {
                '/intro': (context) => const IntroScreen(),
                '/pin_setup': (context) => const PinSetupScreen(),
                '/login': (context) => const LoginScreen(),
                '/budget_setup': (context) => const InitialBudgetSetupScreen(),
                '/dashboard': (context) => const DashboardScreen(),
                '/add_transaction': (context) => const AddTransactionScreen(),
              },
            );
          },
        );
      },
    );
  }
}
