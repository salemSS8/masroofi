import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bashnddof/src/core/currency/currency_service.dart';
import 'package:bashnddof/src/core/localization/language_service.dart';
import 'package:bashnddof/src/core/localization/app_localizations.dart';
import 'package:bashnddof/src/core/models/category_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CurrencyService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await CurrencyService.init();
    });

    test('Defaults to Yemeni Rial (YER)', () {
      expect(CurrencyService.currentCurrency.code, equals('YER'));
      expect(CurrencyService.currentCurrency.symbolAr, equals('ر.ي'));
      expect(CurrencyService.currentCurrency.symbolEn, equals('YER'));
      expect(CurrencyService.currentCurrency.flag, equals('🇾🇪'));
    });

    test('Includes all 21 Arab League currencies plus USD and EUR (23 total)', () {
      final currencies = CurrencyService.allCurrencies;
      expect(currencies.length, equals(23));

      final codes = currencies.map((c) => c.code).toSet();
      // USD & EUR
      expect(codes.contains('USD'), isTrue);
      expect(codes.contains('EUR'), isTrue);

      // Arab League currencies
      const arabCodes = [
        'YER', 'SAR', 'AED', 'KWD', 'QAR', 'BHD', 'OMR',
        'EGP', 'JOD', 'IQD', 'LBP', 'SYP', 'SDG', 'LYD',
        'TND', 'DZD', 'MAD', 'MRU', 'SOS', 'DJF', 'KMF',
      ];
      for (final code in arabCodes) {
        expect(codes.contains(code), isTrue, reason: 'Missing Arab currency: $code');
      }
    });

    test('findByCode returns correct model or null for unknown', () {
      final sar = CurrencyService.findByCode('SAR');
      expect(sar, isNotNull);
      expect(sar!.code, equals('SAR'));
      expect(sar.nameAr, equals('ريال سعودي'));
      expect(sar.symbolAr, equals('ر.س'));

      final usd = CurrencyService.findByCode('USD');
      expect(usd, isNotNull);
      expect(usd!.code, equals('USD'));
      expect(usd.symbolAr, equals('\$'));
      expect(usd.symbolEn, equals('\$'));

      final eur = CurrencyService.findByCode('EUR');
      expect(eur, isNotNull);
      expect(eur!.code, equals('EUR'));
      expect(eur.symbolAr, equals('€'));
      expect(eur.symbolEn, equals('€'));

      // Unknown returns null
      final unknown = CurrencyService.findByCode('XYZ');
      expect(unknown, isNull);
    });

    test('setCurrency updates notifier and persists to SharedPreferences', () async {
      final aed = CurrencyService.findByCode('AED')!;
      await CurrencyService.setCurrency(aed);

      expect(CurrencyService.currentCurrency.code, equals('AED'));
      expect(CurrencyService.currencyNotifier.value.code, equals('AED'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_currency_code'), equals('AED'));

      // Re-init loads saved currency
      await CurrencyService.init();
      expect(CurrencyService.currentCurrency.code, equals('AED'));
    });

    test('format produces correct strings in Arabic and English', () async {
      // YER format
      await CurrencyService.setCurrency(CurrencyService.findByCode('YER')!);
      expect(CurrencyService.format(1250.50, isArabic: true), equals('1,250.50 ر.ي'));
      expect(CurrencyService.format(1250.50, isArabic: false), equals('1,250.50 YER'));

      // USD format ($ prefix in English, $ suffix in Arabic)
      await CurrencyService.setCurrency(CurrencyService.findByCode('USD')!);
      expect(CurrencyService.format(99.99, isArabic: false), equals('\$99.99'));
      expect(CurrencyService.format(99.99, isArabic: true), equals('99.99 \$'));

      // EUR format (€ prefix in English, € suffix in Arabic)
      await CurrencyService.setCurrency(CurrencyService.findByCode('EUR')!);
      expect(CurrencyService.format(50.0, isArabic: false), equals('€50.00'));
      expect(CurrencyService.format(50.0, isArabic: true), equals('50.00 €'));

      // With income / expense sign for EUR
      expect(
        CurrencyService.format(100.0, isArabic: false, showSign: true, isIncome: true),
        equals('+€100.00'),
      );
      expect(
        CurrencyService.format(100.0, isArabic: false, showSign: true, isIncome: false),
        equals('-€100.00'),
      );
    });
  });

  group('LanguageService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LanguageService.init();
    });

    test('Defaults to Arabic (ar)', () {
      expect(LanguageService.currentLocale.languageCode, equals('ar'));
      expect(LanguageService.isArabic, isTrue);
    });

    test('Switching to English persists and updates notifier', () async {
      await LanguageService.setLocale(const Locale('en'));
      expect(LanguageService.currentLocale.languageCode, equals('en'));
      expect(LanguageService.isArabic, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language_code'), equals('en'));

      // Re-init preserves English
      await LanguageService.init();
      expect(LanguageService.currentLocale.languageCode, equals('en'));
    });

    test('Switching back to Arabic persists and updates notifier', () async {
      await LanguageService.setLocale(const Locale('en'));
      await LanguageService.setLocale(const Locale('ar'));

      expect(LanguageService.currentLocale.languageCode, equals('ar'));
      expect(LanguageService.isArabic, isTrue);
    });
  });

  group('AppLocalizations & Directionality Tests', () {
    test('Arabic dictionary resolves essential keys', () {
      final loc = AppLocalizations(const Locale('ar'));
      expect(loc.translate('appTitle'), equals('تطبيق مصروفي'));
      expect(loc.translate('appName'), equals('مصروفي'));
      expect(loc.translate('addNewTransaction'), equals('إضافة معاملة جديدة'));
      expect(loc.translate('budgetEnvelopes'), equals('أظرف الميزانية'));
      expect(loc.translate('savingsGoalsTitle'), equals('أهداف الادخار'));
      expect(loc.translate('settingsTitle'), equals('الإعدادات والأمان'));
    });

    test('English dictionary resolves essential keys', () {
      final loc = AppLocalizations(const Locale('en'));
      expect(loc.translate('appTitle'), equals('Masroufi Wallet'));
      expect(loc.translate('appName'), equals('Masroufi'));
      expect(loc.translate('addNewTransaction'), equals('Add New Transaction'));
      expect(loc.translate('budgetEnvelopes'), equals('Budget Envelopes'));
      expect(loc.translate('savingsGoalsTitle'), equals('Savings Goals'));
      expect(loc.translate('settingsTitle'), equals('Settings & Security'));
      expect(loc.translate('selectCurrency'), equals('Select Currency'));
    });

    test('Directional icons invert properly between RTL and LTR', () {
      final locAr = AppLocalizations(const Locale('ar'));
      expect(locAr.isRtl, isTrue);
      // In RTL, forward chevron points to the left (iOS new back icon points left)
      expect(locAr.forwardChevron, equals(Icons.arrow_back_ios_new_rounded));
      // In RTL, back chevron points to the right
      expect(locAr.backChevron, equals(Icons.arrow_forward_ios_rounded));
      // In RTL, forward arrow points left
      expect(locAr.forwardArrow, equals(Icons.arrow_back_rounded));
      // In RTL, back arrow points right
      expect(locAr.backArrow, equals(Icons.arrow_forward_rounded));

      final locEn = AppLocalizations(const Locale('en'));
      expect(locEn.isRtl, isFalse);
      // In LTR, forward chevron points to the right
      expect(locEn.forwardChevron, equals(Icons.arrow_forward_ios_rounded));
      // In LTR, back chevron points to the left
      expect(locEn.backChevron, equals(Icons.arrow_back_ios_new_rounded));
      // In LTR, forward arrow points right
      expect(locEn.forwardArrow, equals(Icons.arrow_forward_rounded));
      // In LTR, back arrow points left
      expect(locEn.backArrow, equals(Icons.arrow_back_rounded));
    });

    test('CategoryModel.localizeName converts between Arabic and English flawlessly', () {
      expect(CategoryModel.localizeName('الراتب', isArabic: false), equals('Salary'));
      expect(CategoryModel.localizeName('Salary', isArabic: true), equals('الراتب'));
      expect(CategoryModel.localizeName('طعام ومشروبات', isArabic: false), equals('Food & Drinks'));
      expect(CategoryModel.localizeName('Food & Drinks', isArabic: true), equals('طعام ومشروبات'));
      expect(CategoryModel.localizeName('ترفيه وسياحة', isArabic: false), equals('Entertainment'));
      expect(CategoryModel.localizeName('أخرى (مصروف)', isArabic: false), equals('Other (Expense)'));
      expect(CategoryModel.localizeName('أخرى (دخل)', isArabic: false), equals('Other (Income)'));
      expect(CategoryModel.localizeName('Custom Category', isArabic: false), equals('Custom Category'));
    });
  });
}
