import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'currency_model.dart';
export 'currency_model.dart';

/// خدمة إدارة العملات المتعددة وتنسيق المبالغ المالية
class CurrencyService {
  static const String _currencyPrefKey = 'app_currency_code';

  /// العملة الافتراضية للتطبيق (الريال اليمني) للحفاظ على التوافق الكامل مع البيانات القائمة
  static const CurrencyModel defaultCurrency = CurrencyModel(
    code: 'YER',
    nameAr: 'ريال يمني',
    nameEn: 'Yemeni Rial',
    symbolAr: 'ر.ي',
    symbolEn: 'YER',
    flag: '🇾🇪',
  );

  /// قائمة جميع العملات المدعومة (جميع العملات العربية الـ 21 بالإضافة إلى الدولار واليورو)
  static const List<CurrencyModel> allCurrencies = [
    CurrencyModel(
      code: 'YER',
      nameAr: 'ريال يمني',
      nameEn: 'Yemeni Rial',
      symbolAr: 'ر.ي',
      symbolEn: 'YER',
      flag: '🇾🇪',
    ),
    CurrencyModel(
      code: 'SAR',
      nameAr: 'ريال سعودي',
      nameEn: 'Saudi Riyal',
      symbolAr: 'ر.س',
      symbolEn: 'SAR',
      flag: '🇸🇦',
    ),
    CurrencyModel(
      code: 'AED',
      nameAr: 'درهم إماراتي',
      nameEn: 'UAE Dirham',
      symbolAr: 'د.إ',
      symbolEn: 'AED',
      flag: '🇦🇪',
    ),
    CurrencyModel(
      code: 'KWD',
      nameAr: 'دينار كويتي',
      nameEn: 'Kuwaiti Dinar',
      symbolAr: 'د.ك',
      symbolEn: 'KWD',
      flag: '🇰🇼',
    ),
    CurrencyModel(
      code: 'QAR',
      nameAr: 'ريال قطري',
      nameEn: 'Qatari Riyal',
      symbolAr: 'ر.ق',
      symbolEn: 'QAR',
      flag: '🇶🇦',
    ),
    CurrencyModel(
      code: 'OMR',
      nameAr: 'ريال عماني',
      nameEn: 'Omani Rial',
      symbolAr: 'ر.ع',
      symbolEn: 'OMR',
      flag: '🇴🇲',
    ),
    CurrencyModel(
      code: 'BHD',
      nameAr: 'دينار بحريني',
      nameEn: 'Bahraini Dinar',
      symbolAr: 'د.ب',
      symbolEn: 'BHD',
      flag: '🇧🇭',
    ),
    CurrencyModel(
      code: 'EGP',
      nameAr: 'جنيه مصري',
      nameEn: 'Egyptian Pound',
      symbolAr: 'ج.م',
      symbolEn: 'EGP',
      flag: '🇪🇬',
    ),
    CurrencyModel(
      code: 'JOD',
      nameAr: 'دينار أردني',
      nameEn: 'Jordanian Dinar',
      symbolAr: 'د.أ',
      symbolEn: 'JOD',
      flag: '🇯🇴',
    ),
    CurrencyModel(
      code: 'IQD',
      nameAr: 'دينار عراقي',
      nameEn: 'Iraqi Dinar',
      symbolAr: 'د.ع',
      symbolEn: 'IQD',
      flag: '🇮🇶',
    ),
    CurrencyModel(
      code: 'LBP',
      nameAr: 'ليرة لبنانية',
      nameEn: 'Lebanese Pound',
      symbolAr: 'ل.ل',
      symbolEn: 'LBP',
      flag: '🇱🇧',
    ),
    CurrencyModel(
      code: 'SYP',
      nameAr: 'ليرة سورية',
      nameEn: 'Syrian Pound',
      symbolAr: 'ل.س',
      symbolEn: 'SYP',
      flag: '🇸🇾',
    ),
    CurrencyModel(
      code: 'SDG',
      nameAr: 'جنيه سوداني',
      nameEn: 'Sudanese Pound',
      symbolAr: 'ج.س',
      symbolEn: 'SDG',
      flag: '🇸🇩',
    ),
    CurrencyModel(
      code: 'LYD',
      nameAr: 'دينار ليبي',
      nameEn: 'Libyan Dinar',
      symbolAr: 'د.ل',
      symbolEn: 'LYD',
      flag: '🇱🇾',
    ),
    CurrencyModel(
      code: 'TND',
      nameAr: 'دينار تونسي',
      nameEn: 'Tunisian Dinar',
      symbolAr: 'د.ت',
      symbolEn: 'TND',
      flag: '🇹🇳',
    ),
    CurrencyModel(
      code: 'DZD',
      nameAr: 'دينار جزائري',
      nameEn: 'Algerian Dinar',
      symbolAr: 'د.ج',
      symbolEn: 'DZD',
      flag: '🇩🇿',
    ),
    CurrencyModel(
      code: 'MAD',
      nameAr: 'درهم مغربي',
      nameEn: 'Moroccan Dirham',
      symbolAr: 'د.م',
      symbolEn: 'MAD',
      flag: '🇲🇦',
    ),
    CurrencyModel(
      code: 'MRU',
      nameAr: 'أوقية موريتانية',
      nameEn: 'Mauritanian Ouguiya',
      symbolAr: 'أ.م',
      symbolEn: 'MRU',
      flag: '🇲🇷',
    ),
    CurrencyModel(
      code: 'SOS',
      nameAr: 'شلن صومالي',
      nameEn: 'Somali Shilling',
      symbolAr: 'ش.ص',
      symbolEn: 'SOS',
      flag: '🇸🇴',
    ),
    CurrencyModel(
      code: 'DJF',
      nameAr: 'فرنك جيبوتي',
      nameEn: 'Djiboutian Franc',
      symbolAr: 'ف.ج',
      symbolEn: 'DJF',
      flag: '🇩🇯',
    ),
    CurrencyModel(
      code: 'KMF',
      nameAr: 'فرنك قمري',
      nameEn: 'Comorian Franc',
      symbolAr: 'ف.ق',
      symbolEn: 'KMF',
      flag: '🇰🇲',
    ),
    CurrencyModel(
      code: 'USD',
      nameAr: 'دولار أمريكي',
      nameEn: 'US Dollar',
      symbolAr: '\$',
      symbolEn: '\$',
      flag: '🇺🇸',
    ),
    CurrencyModel(
      code: 'EUR',
      nameAr: 'يورو',
      nameEn: 'Euro',
      symbolAr: '€',
      symbolEn: '€',
      flag: '🇪🇺',
    ),
  ];

  static final ValueNotifier<CurrencyModel> currencyNotifier =
      ValueNotifier<CurrencyModel>(defaultCurrency);

  /// الحصول على العملة المختارة الحالية
  static CurrencyModel get currentCurrency => currencyNotifier.value;

  /// تحميل العملة المحفوظة عند إقلاع التطبيق
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_currencyPrefKey);

    if (savedCode != null) {
      final found = findByCode(savedCode);
      if (found != null) {
        currencyNotifier.value = found;
      }
    }
  }

  /// تعيين وحفظ العملة المختارة فورياً
  static Future<void> setCurrency(CurrencyModel currency) async {
    currencyNotifier.value = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyPrefKey, currency.code);
  }

  /// البحث عن عملة برمز الأيزو
  static CurrencyModel? findByCode(String code) {
    try {
      return allCurrencies.firstWhere(
        (c) => c.code.toUpperCase() == code.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// تنسيق المبالغ المالية بدقة وفق العملة المختارة واللغة
  static String format(
    double amount, {
    bool isArabic = true,
    int decimalDigits = 2,
    bool showSign = false,
    bool? isIncome,
  }) {
    final currency = currentCurrency;
    final symbol = currency.getSymbol(isArabic);
    final formatter = NumberFormat(
      decimalDigits == 0 ? '#,##0' : '#,##0.${'0' * decimalDigits}',
      isArabic ? 'ar' : 'en',
    );

    final sign = showSign
        ? (isIncome == true ? '+' : (amount < 0 || isIncome == false ? '-' : ''))
        : '';
    final absAmount = showSign ? amount.abs() : amount;
    final formattedNumber = formatter.format(absAmount);

    if (isArabic) {
      // باللغة العربية: الإشارة ثم الرقم ثم الرمز (مثال: +10,000.00 ر.س)
      return '$sign$formattedNumber $symbol';
    } else {
      // باللغة الإنجليزية: إذا كان الرمز $ أو € يوضع في البداية، خلاف ذلك في النهاية
      if (symbol == '\$' || symbol == '€') {
        return '$sign$symbol$formattedNumber';
      } else {
        return '$sign$formattedNumber $symbol';
      }
    }
  }

  /// الحصول على رمز العملة الحالية مباشرة
  static String getSymbol([bool isArabic = true]) {
    return currentCurrency.getSymbol(isArabic);
  }
}
