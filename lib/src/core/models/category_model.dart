/// نموذج تصنيف المعاملة (دخل أو مصروف)
class CategoryModel {
  final int? id;
  final String name;
  final String icon;
  final int color;
  final bool isIncome;

  const CategoryModel({
    this.id,
    required this.name,
    this.icon = 'category',
    this.color = 0xFF10B981,
    this.isIncome = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'is_income': isIncome ? 1 : 0,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'بدون اسم',
      icon: map['icon'] as String? ?? 'category',
      color: (map['color'] as num?)?.toInt() ?? 0xFF10B981,
      isIncome: (map['is_income'] as int? ?? 0) == 1,
    );
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    String? icon,
    int? color,
    bool? isIncome,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isIncome: isIncome ?? this.isIncome,
    );
  }

  String localizedName({required bool isArabic}) =>
      localizeName(name, isArabic: isArabic);

  static const Map<String, String> _arToEn = {
    'الراتب': 'Salary',
    'عمل حر': 'Freelance',
    'استثمارات': 'Investments',
    'أخرى (دخل)': 'Other (Income)',
    'طعام ومشروبات': 'Food & Drinks',
    'سكن وإيجار': 'Housing & Rent',
    'فواتير وخدمات': 'Bills & Utilities',
    'مواصلات ووقود': 'Transportation',
    'تسوق ومشتريات': 'Shopping',
    'صحة وأدوية': 'Health & Medical',
    'ترفيه وسياحة': 'Entertainment',
    'تعليم وتطوير': 'Education',
    'أخرى (مصروف)': 'Other (Expense)',
    'أخرى': 'Other',
    'دخل': 'Income',
    'مصروف': 'Expense',
    'بدون اسم': 'Uncategorized',
  };

  static const Map<String, String> _enToAr = {
    'Salary': 'الراتب',
    'Freelance': 'عمل حر',
    'Investments': 'استثمارات',
    'Other (Income)': 'أخرى (دخل)',
    'Food & Drinks': 'طعام ومشروبات',
    'Housing & Rent': 'سكن وإيجار',
    'Bills & Utilities': 'فواتير وخدمات',
    'Transportation': 'مواصلات ووقود',
    'Shopping': 'تسوق ومشتريات',
    'Health & Medical': 'صحة وأدوية',
    'Entertainment': 'ترفيه وسياحة',
    'Education': 'تعليم وتطوير',
    'Other (Expense)': 'أخرى (مصروف)',
    'Other': 'أخرى',
    'Income': 'دخل',
    'Expense': 'مصروف',
    'Uncategorized': 'بدون اسم',
  };

  static String localizeName(String originalName, {required bool isArabic}) {
    if (isArabic) {
      return _enToAr[originalName] ?? originalName;
    } else {
      return _arToEn[originalName] ?? originalName;
    }
  }

  @override
  String toString() => 'CategoryModel(id: $id, name: $name, isIncome: $isIncome)';
}
