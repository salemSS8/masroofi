/// نموذج بيانات العملة يدعم اللغتين العربية والإنجليزية ورموز العملات والأعلام
class CurrencyModel {
  final String code; // رمز الأيزو (YER, SAR, USD, EUR...)
  final String nameAr; // الاسم باللغة العربية
  final String nameEn; // الاسم باللغة الإنجليزية
  final String symbolAr; // الرمز باللغة العربية (ر.ي، ر.س، $...)
  final String symbolEn; // الرمز أو الاختصار بالإنجليزية (YER, SAR, $...)
  final String flag; // الإيموجي للعلم (🇾🇪, 🇸🇦, 🇺🇸...)

  const CurrencyModel({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.symbolAr,
    required this.symbolEn,
    required this.flag,
  });

  /// جلب اسم العملة حسب لغة التطبيق
  String getName(bool isArabic) => isArabic ? nameAr : nameEn;

  /// جلب رمز العملة حسب لغة التطبيق
  String getSymbol(bool isArabic) => isArabic ? symbolAr : symbolEn;

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'symbolAr': symbolAr,
      'symbolEn': symbolEn,
      'flag': flag,
    };
  }

  factory CurrencyModel.fromMap(Map<String, dynamic> map) {
    return CurrencyModel(
      code: map['code'] as String,
      nameAr: map['nameAr'] as String,
      nameEn: map['nameEn'] as String,
      symbolAr: map['symbolAr'] as String,
      symbolEn: map['symbolEn'] as String,
      flag: map['flag'] as String? ?? '💰',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyModel &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$code ($flag $nameAr)';
}
